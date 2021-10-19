# Dagger project overview

> This documents outlines at a high level, what Dagger is; the problem it's attempting to solve and it's value proposition; as well as how it compares to similar solutions.

## Introduction

Peer to peer storage and file sharing networks have been around for quite a long time. They exhibit clear advantages in comparison to centralized storage providers such as scalability and robustness in the face of large scale network disruptions and have desirable censorship resistant properties. However, we've yet to see widespread adoption outside of a few niche applications.

Our intuition is that the lack of incentives, strong data availability, and persistence guarantees make these networks unsuitable for applications with moderate to high availability requirements. In other words, **without reliability at the storage layer it is impossible to build other reliable applications** on top of it. A more in depth overview of these observations can be found in the [incentives rationale](https://github.com/status-im/dagger-research/blob/main/incentives-rationale.md) document.

## Goals and Motivations

Dagger is our attempt at creating a decentralized storage engine that intends to improve on the state of the art by supplying:

- An incentivized p2p storage network with strong availability and persistence guarantees
- A resource restricted friendly protocol that can endure higher levels of churn and large amounts of ephemeral devices

We intend to address the first issue by developing a robust data availability and retrievability scheme and the second by building a p2p network friendly to mobile and other ephemeral devices.

We follow the "less is more" principle and attempt to remove as much complexity from the core protocol as possible. Anything that doesn't directly contribute to the core functionality is pushed out of the protocol - this decision has two important goals. Reducing complexity at the protocol level, simplifies implementation and allows for quick iterative development cycles and, by simplifying the protocol we also simplify the incentives mechanisms - a particularly hard problem that we believe is yet to be properly addressed by other solutions.

## High level network overview

Dagger consists of a p2p network of **storage, ephemeral, validator** and **regular** nodes.

### Storage nodes

Storage nodes provide long term reliable storage. In order for a storage node to operate it needs to stake a collateral proportional to the amount of data it's willing to store. Once the collateral has been staked and the node begins to store data, it needs to periodically provide proofs of data possession. If a node fails to provide a proof in time, it is penalized with a portion of its stake; if the node fails to provide proofs several times in a row, it looses the entirety of the stake.

### Validator nodes

Validator nodes are in charge of collecting, validating and submitting proofs to an adjudicator contract which rewards and penalizes storage and other validator nodes. A validator node also needs to stake a collateral in order to be able to participate in the validation process.

Note that we don't use the term "adjudicator contract" in the literal sense of an Ethereum contract. We use it to indicate anything that executes on a consensus engine.

### Ephemeral nodes

Bandwidth incentives allow anyone to operate as an ephemeral node, profiting only from caching and serving popular content. We expect this to have the emergent property of an organic CDN, where nodes with spare bandwidth but limited or unreliable storage can collectively scale the network depending on current demands.

### Regular nodes

Regular or client nodes, engage with other nodes to store, find and retrieve data from the network. Regular nodes constitute the lion share of the Dagger network and consume services offered by other nodes in exchange for payments. A regular node can also be an ephemeral node by caching previously consumed data that other nodes can retrieve from it. This allows nodes to offset some of the cost of participating in the network and it's expected to allow the majority of nodes to participate on an almost free basis after an initial entree fee - this last point is covered in more detail in a later section.

## Incentives structure

The goals behind our incentives structure are:

1. Allow demand and supply to direct the network to optimally utilize its resources
2. Allow nodes to utilize their competitive advantages to maximize profits, thus increasing participation
3. Serve as a security and spam prevention mechanism

Interactions between nodes are 1:1. This decision is deliberate and allows us to simplify accounting and adjudicating of payments and avoids complex price discovery mechanisms. We explicitly want to avoid:

- Complex multihop payment chains - all interactions are strictly between directly connected nodes
- Arbitrary price setting - all prices are driven by demand and supply and are negotiated 1:1
- Loose payment guarantees and doublespends - all interactions between parties are settled securely and unambiguously

In other words, our incentive structure attempts to be simple, predictable and secure. Predictability and security allows nodes to properly plan and allocate resources.

### Incentives categories

There are several incentives categories:

- Staking
- Bandwidth
- Storage
- Penalties and rewards

#### Staking

Staking is used as a mechanism to prevent spam and abuse in the system - all nodes stake some amount of collateral.

Regular nodes stake funds indirectly by having an operational capital to be able to retrieve content from the network, i.e. bandwidth fees.

#### Bandwidth

Bandwidth fees play several important roles in the system:

- Prevent spam and DDoS attacks from requesting nodes
- Enable nodes to operate as exit or caching nodes
- Avoid hotpaths and enable (geographical) locality
  - Rational nodes looking to maximize profits, can quickly cache and serve popular content, thus scaling the network according to current needs

#### Storage

Storage incentives allow nodes to earn a profit in exchange for storing arbitrary data. This allows content to persist in the network regardless of its popularity and age.

#### Penalties and Rewards

Penalties and rewards allow verifying nodes to profit by monitoring and detecting malicious or malfunctioning storage and other validator nodes.

## Data availability and persistence

A core goal of the Dagger protocol is to enable data availability and persistence. In order to accomplish this, we rely on several complementary techniques:

- We use active verification to ensure data is available and retrievable
- We ensure that failures are detected and corrected early to prevent outages and keep previously agreed upon redundancy guarantees
- We use erasure coding to increase network wide data redundancy and prevent catastrophic data loss

When a node commits to a storage contract and a user uploads a file or other arbitrary data, the network will proactively verify that the storing node is online and the data is retrievable. Storage nodes broadcast proofs of data possession over random intervals. If the storage node sent invalid proofs or failed to provide them in time, the network will re-post the contract for any other storage node to pick up. When the contract is re-posted, an amount from the faulty node's stake is used for the new storing node bandwidth fees. It is expected that data is stored on at least several nodes to prevent data loss in the case of a catastrophic network failure. Erasure coding complements active verification by allowing to reconstruct the full set from a subset of the data.

### Proofs of data possession and retrievability

We use proofs of data possession and retrievability to ensure storage nodes committed to a contract remain online and available. The storage and retrievability proofs are formally described in this [document](https://hackmd.io/2uRBltuIT7yX0CyczJevYg?view).

The main objective of the proofs are:

- Ensure nodes are online and maintaining the entirety of the dataset from the storage contract
- Ensure that data is readily retrievable to prevent blackmailing and withholding attacks


## Interacting with the Dagger Network

Any regular node that participates in the network needs to have an operational amount set aside in order to cover for bandwidth fees. This creates a barrier to entry however, we think it's a worthy tradeoff in order to maintain the security and health of the network. It's worth noting that any decentralized platform will have similar requirements and limitations. Bellow, we'll list some potential ways to workaround this in Dagger.

### Subsidies or airdrops

Any application migrating or being built for a decentralized platform requires some operational capital to participate. Many projects workaround this by initially subsidizing potential users with small portions of their token. This are usually known as airdrops. Dagger can use a similar technique to allow first adopters to begin participating in the network.

### Tit-for-tat settlements

Many interactions in the network will be long lived, this allows two nodes to exchange in a tit-for-tat manner. It works like this, a long lived payment channel is opened and nodes freely exchange chunks regardless of which way the balance tilts. The channel can only be closed when both parties agree (this is always true, regardless of how long the channel has been open). The node that is currently in debt will need to add funds to the channel or keep providing the other peer with chunks until the debt is repaid. The channel is closed only when the debt is completely settled or the counter party forgoes it.  We expect that nodes resort to tit-for-tat often, thus alleviating the need to constantly "top up" the node's balance.

### Ephemeral or Caching nodes

Storing nodes need to be constantly online in order to earn fees on storage contracts and respond to probing requests. If a node is overwhelmed and unable to serve requests, it can miss a verification window or a verifier requesting random chunks, both of which lead to penalties. In this cases, rational storage nodes can lower the price per chunk to allow other nodes to share the load. In many cases they might forgo bandwidth fees for some period of time, which allows newly joining or underfunded nodes to become caching nodes and earn bandwidth fees.

### Adaptive nodes

Many mobile devices follow well established patterns of usage. Phones often switch from mobile data to WiFi and back; and are either on the go or plugged in the wall, charging. This devices can operate mostly as a consumer when on the go, but switch to a caching node when bandwidth and power aren't a limitation. This will offset all or most of the nodes consumed bandwidth during the day.

### Opportunistic providing

A node might not have a chunk itself, but it might be connected to another node that does, in that case it might choose to advertise the chunk to the requesting node but charge a small premium in order to cover it's expenses and make a small profit on top. This is called "opportunistic providing".

Note that this emulates forwarding but without incuring in complexity with payments tracking accross many hops. Payments at each hop are still settled 1:1.

### Altruistic nodes

Any node can choose to provide services for free. Nodes can store and share arbitrary data at will without charging any fees.

## Closing Notes

To summarize, Dagger attempts to "untie the knot" of incentivized storage and allow many existing and future application to be built in a distributed manner. We're building Dagger to be reliable and predictable p2p storage infrastructure that will allow for many business and casual use cases. We accomplish data persistence and availability by introducing robust PoDP proofs which we supplement with error correction techniques. We use robust PoR schemes to prevent blackmailing and data withholding attacks and guarantee data is always retrievable. We provide reasonable workarounds to the "zero entry" problem without compromising the network's security.

Hopefully, this overview has clarified what Dagger is and what its main value proposition.
