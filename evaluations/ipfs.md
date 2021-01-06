An evaluation of the IPFS paper
===============================

2021-01-06 Mark Spanbroek

https://ipfs.io/ipfs/QmR7GSQM93Cx5eAg6a6yRzNde1FQv7uL6X1o4k7zrJa3LX/ipfs.draft3.pdf

Goal of this evaluation is to find things to adopt or avoid while designing
Dagger. It is not meant to be a criticism of IPFS.

#### Pros:

+ IPFS is designed by simplifying, evolving, and connecting proven techniques
  (§3)
+ Consists of a stack of separately described sub-protocols (§3)
+ Uses Coral DSHT to favor data that is nearby, reducing latency of lookup
  (§2.1.2)
+ Uses proof-of-work in S/Kademlia to discourage Sybil attacks (§2.1.3)
+ Favors self-describing values such as multihash (§3.1) and multiaddr (§3.2.1)
+ BitSwap protocol for exchanging blocks supports multiple strategies (§3.4.2)
+ Uses content addressing (§3.5)
+ The Merkle DAG is simple, yet allows constucting filesystems,
  key-value stores, databases, messaging system, etc.. (§3.5)

#### Cons:

- Kademlia prefers long-lived nodes, which is not ideal for mobile enviroments
  (§2.1.1)
- BitSwap falls just short of introducing a currency with micro payments,
  necessitating additional work for nodes to find blocks to barter with (§3.4)
- Merkle DAGs and Paths (§3.5.1) feel like an unnecessary complication at the
  protocol level; they could have been implemented on top of a system consisting
  solely of content addressable chunks
- Object pinning (§3.5.3) inevitably leads to centralized gateways to IPFS, such
  as Infura and Pinata
- There are no self-describing multiformats for encryption and signing (§3.5.5)
- IPFS uses variable size blocks instead of fixed-size chunks (§3.6)
- Supporting version control directly in IPFS feels like an unnecessary
  complication (§3.6.5)
- Handles mutable state by hacking it into the routing DHT (§3.7.1), instead of
  using a separate mutable naming system like ENS