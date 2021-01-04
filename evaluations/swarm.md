An evaluation of the Swarm book
===============================

2020-12-22 Mark Spanbroek

https://swarm-gateways.net/bzz:/latest.bookofswarm.eth/

Goal of this evaluation is to find things to adopt or avoid while designing
Dagger. It is not meant to be a criticism of Swarm.

#### Pros:

+ Book contains a well-articulated vision and historical context (§1)
+ Uses libp2p as underlay network (§2.1.1)
+ Uses content-addressable fixed-size chunks (§2.2.1, §2.2.2)
+ Employs encryption by default, enabling plausible deniability for node owners
  (§2.2.4)
+ Opportunistic caching allows for automatic scaling for popular content
  (§2.3.1, §3.1.2)
+ Has an upload protocol that, once completed, allows the uploader to disappear
  (§2.3.2)
+ Network self-repairs content through pull syncing (§2.3.3).
+ Nodes can play different roles depending on their capabilities, e.g. light
  node, forwarding node, caching node (§2.3.4).
+ Has a pricing protocol (§3.1.2)
+ Uses micro payments (§3.2)
+ Allows for zero cash entry (§3.2.5), which benefits decentralization
+ Uses staking/collateral, spot-checks and litigation to insure long term
  storage. (§3.3.4, §5.3)
+ The Merkle tree for chunking a file enables random access, and resumption of
  uploads (§4.1.1)
+ Manifests allow for collections of files and their paths (§4.1.2)
+ Combines erasure coding with a Merkle tree in a smart way (§5.1.3)
+ Redundancy is used to improve latency (§5.1.3)

#### Cons:

- Use of two peer-to-peer networks (underlay and overlay) seems overly complex
  (§2.1)
- Tries to solve many problems that can be addressed by other protocols, such as
  routing privacy, micro payments and messaging.
- Storage nodes and peers are chosen based on their mathematical proximity,
  instead of taking performance and risk into account (§2.1.3)
- Uses a forwarding Kademlia DHT (§2.1.3) for routing, which requires stable,
  long lived network connections
- Depends heavily on forwarding of messages, each message passes through list of
  peers that could be on opposite sides of the world. (§2.1.3)
- Tries to solve routing privacy (§2.1.3), which could arguably be better
  addressed by a separate protocol such as onion routing.
- Because of the use of an overlay DHT network, Swarm has to solve the
  bootstrapping problem, even though libp2p already solves this (§2.1.4).
- A Swarm node needs to maintain three different DHTs; one for the underlay
  network (libp2p), another for routing (forwarding Kademlia), and a third for
  storage (DISC).
- Solves the problem of changing content in a content-addressable system in two
  different ways: through single-owner chunks (§2.2.3), and through ENS (§4.1.3)
- Garbage collection based on chunk value makes it hard to reason about the
  amount of money that is required to keep content on the network (§2.2.5)
- Besides all the various incentives, Swarm also has a reputation system in the
  form of a deny list (§2.2.7).
- Incentive system is complex, and therefore harder to verify. (§3)
- Has its own implementation of micro payments, instead of using existing
  payment channels (§3.2.1)
- Rewarding nodes for upload receipts leads to a store-and-forget attack, that
  requires tricky mitigation (§3.3.4)
- Extra complexity (trojan chunks, feeds) is added because Swarm is also a fully
  fledged communication system (§4).
- Offers pinning of content, even though it is inferior to using incentives
  (§5.2.2)
- Recovery is built on top of pinning and messaging (trojan chunks) (§5.2.3)
