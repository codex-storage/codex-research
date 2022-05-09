# Compact Proofs of Retrievability

## Authors

- Hovav Shacham - hovav@cs.ucsd.edu
- Brent Waters - bwaters@cs.utexas.edu

### DOI

- http://dx.doi.org/10.1007/978-3-540-89255-7_7

## Summary

The paper introduces a remote storage auditing scheme known as Proofs of Retrievability based on work derived from `Pors: proofs of retrievability for large files` by Juels and Kaliski and `Provable data possession at untrusted stores` by Ateniese et al.

It takes the idea of homomorphic authenticators from Ateniese and the idea of using erasure coding from Juels and Kaliski to strengthen the remote auditing scheme. To our knowledge, this is also the first work to provide rigorous mathematical proofs for this type of remote auditing.

The paper introduces two types of schemes - public and private. In the private setting, the scheme requires possession of a private key to perform verification but lowers both the storage and network overhead. In the public setting, only the public key is required for verification but the storage and network overhead are greater than those of the private one.

### Main ideas

- Given a file `F`, erasure code it into `F'`
- Split the file into blocks and sectors
- Generate cryptographic authenticators for each block
- During verification
  - The verifier emits a challenge containing random indexes of blocks to be verified along side random values used as multipliers to compute the proof
  - The prover takes the challenge and using both the indexes and the random multipliers produces an unforgeable proof. The proof consists of the aggregate data and tags for the indexes in the challenge
  - Upon receival, the prover is able to verify that the proof was generated using the original data

### Observations

- Both the data and the tags are employed in the generation and verification of the proof, which guarantees that the original data was used in the generation of the proof. This solves the pre-image attack that other schemes are susceptible to.
- It potentially achieves a level of compression where at most one block worth of data and one cryptographic tag is ever needed to be sent across the network.
- The erasure coding solves several concurrent issues. With an MDS erasure code and a coding ratio of 1 (K=M)
  - It is only necessary to prove that %50 of all the blocks are in place, this lowers the amount of data needed to be sampled making it constant for datasets of any size
  - Having to only verify that only K blocks are still available also protects against adaptive adversaries. For example, if the data is stored in 3 drives and each drive keeps going offline between samples the odds reset between each sampling round. To protect against such an adversarial scenario without erasure coding it would require to sample 100% of the entire file at each round; with erasure coding, since **any** K blocks are sufficient to reconstruct, the odds do not reset across sampling rounds

### Other ideas

- Another important aspect presented in the paper is an `extractor function`. The idea is that given an adversary that is producing proofs but not releasing the data upon request, it would still be possible to eventually extract enough data to be able to reconstruct the entirety of the dataset, this would require extracting an amount of data equivalent to K blocks.
