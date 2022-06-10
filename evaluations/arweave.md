---
published: false
---
An evaluation of the Arweave paper
==================================

2021-05-18 Dagger Team

https://www.arweave.org/yellow-paper.pdf

Goal of this evaluation is to find things to adopt or avoid while designing
Dagger. It is not meant to be a criticism of Arweave.

#### Pros:

+ There is no distinction between full and light clients, merely clients that
  downloaded more or less of the blockweave. (§2.2)
+ Prefential treatment of peers is discouraged, because nodes are unaware when
  they're being monitored for responsiveness. (§3.4.2)
+ Interesting 'meta-game' on top of tit-for-tat, in which nodes monitor their
  peers on how they rank other peers. (§6.1)
+ Because behaviour of nodes is largely based on local rules and the local view
  that a node has of its peers, the network is able to shift behaviour gradually
  in response to a changing environment. (§6.2)

#### Cons:

- Proof of Work is used for the underlying blockweave (§3.1), which is
  rather wasteful.
- Data is stored indefinitely, which is great for public information, but not so
  great for ephemeral private data. This makes storage unnecessarily expensive
  for data with a short lifespan. (§3.1)
- Network is free at point of use for external users, raising questions about
  scalability of the network when faced with highly popular content. (§3.4.2)
  Incentives for data replication help (§7.1.2), but it is unlikely that it
  will hold up when the network grows in content (§8.2, §8.3). These incentives
  can also lead to unnecessary duplication of unpopular content.
- Nodes with limited connectivity are discouraged from participating in the
  network, which precludes use on mobile devices. (§3.4.3)
- There is an economic incentive for a miner to not to share old blocks with
  other miners, because it increases its chance of "winning" the new block.
  (§4.1.1)
- There is an economic incentive for miners to have the strictest censorship
  rules, because otherwise a block that it mined might be rejected by others.
  (§5.1)
- The majority of the network determines the censorship rules. This could prove
  troublesome should Arweave's Proof of Work lead to similar geographic
  centralization of mining power as we see in Bitcoin. (§5.3)
- Transaction ID is used for addressing, instead of a content hash. (§7.1.1)
- Uses HTTP for inter-node traffic, instead of an established peer-to-peer
  protocol. (§7.1.3)
