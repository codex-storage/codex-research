An evaluation of the Storj whitepaper
=====================================

2020-12-22 Mark Spanbroek

https://storj.io/storjv3.pdf

Goal of this evaluation is to find things to adopt or avoid while designing
Dagger. It is not meant to be a criticism of Storj.

#### Pros:

+ Performance is considered throughout the design
+ Provides an Amazon S3 compatible API (§2.4)
+ Bandwidth usage of storage nodes is aggressively minimized to enable people
  with bandwidth caps to participate, which is good for decentralization (§2.7)
+ Erasure codes are used for redundancy (§3.4), upload and download speed
  (§3.4.2), proof of retrievability (§4.13) and repair (§4.7)!
+ BIP32 hierarchical keys are used to grant access to file paths (§3.6, §4.11)
+ Ethereum based token for payments (§3.9)
+ Storage nodes are not paid for uploads to avoid nodes that delete immediately
  after upload (§4.3)
+ Proof of Work on the node id is used to counter some Sybil attacks (§4.4)
+ Handles key revocations in a decentralized manner (§4.4)
+ Uses a simplified Kademlia DHT for node lookup (§4.6)
+ Uses caching to speed up Kademlia lookups (§4.6)
+ Uses standard-sized chunks (segments) throughout the network (§4.8.2)
+ Erasure coding is applied after encryption, allowing the network to repair
  redundancy without the need to know the decryption key (§4.8.4)
+ Streaming and seeking within a file are supported (§4.8.4)
+ Micropayments via payment channels (§4.17)
+ Paper has a very nice overview of possible attacks and mitigations (§B)


#### Cons:

- Mostly designed for long-lived stable nodes (§2.5)
- Satellites are the gateway nodes to the network (§4.1.1), whose requirements
  for uptime and reputation lead to centralization (§4.10). They are also a
  single point of failure for a user, because it stores file metadata (§4.9).
- Centralization is further encouraged by having a separate network of approved
  satellites (§4.21)
- Clients have to actively perform for audits (§4.13) and execute repair (§4.14)
  (through their trusted satellite)
- The network has a complex reputation system (§4.15)
- Consecutive micropayments are presented as a solution for the trust problems
  while retrieving (§4.17), which doesn't entirely mitigate withholding attacks.
- Scaling is hampered by the centralization that happens in the satellites
  (§6.1)
- The choice to avoid Byzantine distributed consensus, such as a blockchain
  (§2.10, §A.3) results in the need for trusted centralized satellites
