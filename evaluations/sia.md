An evaluation of the Sia whitepaper
===================================

2020-12-07 Mark Spanbroek

https://sia.tech/sia.pdf

Goal of this evaluation is to find things to adopt or avoid while designing
Dagger. It is not meant to be a criticism of Sia.

#### Pros:

+ Clients do not need to actively monitor hosts (§1). Once a contract has been
  agreed upon, the host earns/loses coins based on proofs of storage that the
  network can check.
+ Denial of service attacks can be mitigated by burning funds associated with
  missed proofs (§4).
+ Proof of storage is simple; provide a random piece of the file, and the
  corresponding Merkle proof (§5.1).
+ Promotes erasure codes to safeguard against data loss (§7.2).
+ Suggests to use payment channels for micro-payments (§7.3).
+ The basic reputation system is protected against Sybil attacks (§7.4).

#### Cons:

- Sia has its own blockchain (§1), which makes some attacks more likely
  (§5.2, §5.3). This can be mitigated by adopting a widely used, general purpose
  blockchain such as Ethereum.
- Requires a multi-signature scheme (§2).
- The proof-of-storage algorithm requires that hosts store the entire file (§4),
  instead of a few chunks.
- Contracts can be edited (§4). This feels like an unnecessary complication of
  the protocol.
- Randomness for the storage proofs comes from the latest block hash (§5.1).
  This can be manipulated, especially when using a specialized blockchain for
  storage.
- There is an arbitrary data field that might be used for advertisements in a
  storage marketplace (§6). This feels like a very restrictive environment for a
  marketplace, and an unnecessary complication for the underlying blockchain.
- It is suggested that clients use erasure coding before encryption (§7.2). If
  this were reversed (first encryption, then erase coding) then this would open
  up scenario's for caching and re-hosting by those who do not possess the
  decryption key.
- Consecutive micropayments are presented as a solution for the trust problems
  while downloading (§7.3). This assumes that the whole file, or a large part of
  it, is stored on a single host. It also doesn't entirely mitigate withholding
  attacks.
- The basic reputation system favors hosts that have already earned or bought
  coins (§7.4). It is also unclear how the reputation system discourages abuse.
- Governance seems fairly centralized, with most funds and proceeds going to a
  single company (§8).
