# Incentives Rationale

Why incentives? In order to have a sustainable p2p storage network such that it can be used to store arbitrary data and avoid specializing around a certain type of content, economic incentives or payments are required.
## Incentives in p2p networks

Bittorrent & friends, tend to specialize around **popular content** such as movies or music (citation). Empirical evidence suggests, that this is a consequence of how incentives are aligned in this types of network (citation). Without diving too deep, the bittorrent incentives model is composed of 3 major elements:

- A "tit-for-tat" (or some variation) accounting system
- A "seeding ratio", which signals the peer's reputation
- The content being shared, which becomes the commodity traded in the network

In other words, you trade "content" in a "tit-for-tat" fashion, which increases the "seeding ratio", which gives access to more "content". This model sounds attractive and fair at first, however it has shown to have major flaws.

- It leads to network specialization where only certain types of content are available
  - Peers want to maximize their "seeding-ratio", which leads to sharing content which is in high demand (popular), which often tends to be the latest movie, tv show or music album.
  - Rare or "uninteresting" content is almost impossible to come by unless explicitly provided by a party such as specialized communities or private trackers (which usually implies payments, ie external incentives).
- File availability becomes dependent on the content's popularity and age (in the network). It's availability declines over time.
  - Anecdotally, the current season of a tv show is often easier to come by than the previous season, this is because once the content has been downloaded (and consumed), there is little reason to continue sharing it for a longer period of time.

There is also operational costs associated with running a node. This costs grows (at the very least linearly) proportional to the amount of users being served. Running a highly available node that serves thousands of other nodes a day is probably unfeasible for the vast majority of casual users and building a business around this type of protocols has unclear economics and quite often, legal consequences due to (the already mentioned network specialization issues) sharing illegal or "pirated" content.

In short, a direct consequence of this incentives model is **network specialization** and **content/data availability**.

In contrast to this, there is a different type of p2p network where this problem is not observed. Blockchains, which are in some sense data sharing networks, are an example of such networks. The reason for this is that there is a minimum amount of data required for a blockchain node to operate and thus all nodes have the incentive to download that data - we can call it **essential** data. Since this data is **essential** to operate a node, it's guaranteed to always be available - **this is a premise of the network**; non essential data however, such as the chain's full history is harder to come by and usually subsidized by third party organizations.

It follows from the above examples that, there are __at least__ two types of p2p storage networks:

- One where the data is intrinsic to the protocol, in other words the protocol and the data are inseparable, which is the case of blockchains
- Another, where the data is extrinsic and the protocol does not rely on it in order to operate

## General purpose p2p storage networks

In general, when compared to centralized alternatives p2p networks have many desirable properties such as:

- Censorship resistance
- Robustness, in the face of large scale failures
- Excellent scaling potential
  - This is usually a matter of having more nodes joining the network

In short, p2p networks have advantages over centralized counterparts and yet, we haven't see wider adoption outside of a few niche use cases already outlined above. In our opinion, this is due to lack of sufficient guarantees in networks with extrinsic data.

One important property of data, is that once data is gone and no backups exist, the chances of recovery are very slim. Contrast this with computation, if the data is intact, recovering from failed computation usually implies simply re-running it with the same input. In other words, when it comes to data, integrity and availability is more important than any other aspect.

It's this project's aim to provide a solution to the outlined issues of **data availability** in networks with extrinsic data.

It's worth further breaking down **data availability** into two separate problems:

1. Retrievability - the ability to retrieve/download data from the network at any time
2. Persistence - the guarantee that data is persisted by the network over a predetermined time frame

## What should be incentivized then?

In our opinion, anything that is a finite resource. In p2p storage networks this is largely bandwidth and hard drive.

### Bandwidth incentives

Bandwidth is a finite resource and has an associated cost. Eventually this cost is going to compound and serving the network will become unreasonable and unsustainable. This leads to low node participation and data retrievability issues as peers will chooses to only serve select nodes or none at all. In many cases, this leads nodes to temporarily leave the network even when the file is still sitting on its hard drive.

There are several fundamental problems that bandwidth incentives solve.

- Increase the chance of data being "retrievable" from the network
- Properly compensate "seeders" for the resources consumed by "leechers"
  - This ensures higher levels of node participation
- Serves as a sybil attack prevention mechanism in an open network

With incentivized bandwidth, rational nodes driven by market dynamics should seek to maximize profits by sharing data that is in high demand, thus offsetting operational costs and scaling the network up or down. This would give the network properties similar to a CDN that caches content to prevent overwhelming the origin with requests.

### Storage incentives

Storage, also being a finite resource, has associated costs. Storing data on your own hard drive for no reason is irrational and it's safe to assume that an overwhelming majority of the network's participants wont do that. This leads the network to specialize around certain types of __popular__ content. In order to offset that trend, storing data needs to be incentivized.

The fundamental issues that storage incentives solve is **data availability** and more precisely the issue of data **persistence** over a predetermined time frame.

Enabling persistence opens up many common use cases such as data backups, becoming a storage provider for traditional web and web3 applications, and many others. In short, it replaces centralized cloud storage providers. Due to the wide range of use cases the issue of specialization also goes away.

It's worth noting that we make no claims that the network is not going to be used to store and distribute "pirated" content, we merely claim that by realigning incentives we'll enable other more common use cases.

Together, these incentives lead to a sustainable and censorship resistant p2p network. You negotiate a price for certain content to be stored long-term. Should the content become unavailable (due to censorship or a generic failure) after the contract is negotiated then the peer that stores the content is punished. When content is popular, then it will spread because more peers want to earn bandwidth fees, which allows the network to scale to high demand, acting as a censorship resistant CDN.

## Zero-cash entry

Zero-cash entry entails that you can enter the network without having any funds. When all interactions in the network have a price then it becomes a problem to start participating unless the node is funded. The way to work around this problem is to initially become a provider of services, for example, a node can start persisting chunks for some amount of time (minutes or hours), and thus earn some initial capital after which it can start to freely exchange data.

Another possibility would be that businesses that have storage requirements subsidize new users with a seed amount. For example a chat application can seed a small amount to a newly signed up client which will help it get started in the network. Once the client participates in the network, it will start earning bandwidth fees, which if correctly balanced, mean that a casual user can participate almost for free.


## Design philosophy

When choosing and designing our incentive protocols we favor practical and provable protocols that maximally reduce the risks for participants. We favor those solutions that are easy to separate and upgrade over those that are tightly coupled with the rest of the network design.
