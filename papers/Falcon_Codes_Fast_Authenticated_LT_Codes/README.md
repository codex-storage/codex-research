# Falcon Codes
## Authors

  - Ari Juels
  - James Kelley
  - Roberto Tamassia
  - Nikos Triandopoulos

## DOI

https://doi.org/10.1145/2810103.2813728.

## Bibliography entry

Juels, Ari, James Kelley, Roberto Tamassia, and Nikos Triandopoulos. ‘Falcon Codes: Fast, Authenticated LT Codes (Or: Making Rapid Tornadoes Unstoppable)’. In Proceedings of the 22nd ACM SIGSAC Conference on Computer and Communications Security, 1032–47. CCS ’15. New York, NY, USA: Association for Computing Machinery, 2015. https://doi.org/10.1145/2810103.2813728.

## Summary

The paper addresses the problem of **adversarial erasures** in case of **non-MDS codes**, in a **private coding setting**.
LT-codes, and their derivatives (RaptorQ, etc.) are known to provide fast(even linear-time) encode and decode both asymptotically and in practice, and are useful both as large block codes and as rateless codes. However, their guarantees are w.h.p only, while minimum code distance can be small in practice. This means that adversarial erasure patterns exist that can eliminate the advantages of an otherwise strong redundancy. Falcon codes aim to solve this by hiding the coding pattern. Note that this hiding can only work in a private setting, where there is a shared secret between encoder and decoder.

### Main ideas

The main idea is to:
- Take an LT encoder, which already uses and RNG to pick from a random degree distribution when generating bipartite coding graph.
- Employ a PRG parametrised by a secret to make the random coding graph secret.
- Encoding is now using a secret graph, but since encoding is done using XOR, it would be easy to infer the graph by observing segments. Protect this by adding a layer of encryption over segments. 
- Optionally add a MAC to convert corruptions to erasure.

### Other ideas

Other ideas in the paper include:
- reduce MAC overhead: batching MACs amplifies error but reduces overhead.
- Scalability (FalconS): original Falcon needs access to all segments. Change this by applying Falcon in `b` blocks. This improves encoder locality but introduces adversarial erasure. Thus, apply a random permutation over all parity symbols over all blocks to avoid the adversarial erasures.
- Rateless (FalconR): split original to `b` blocks, and set up a different Falcon for each, but do not encode yet. Then, generate the next parity symbol by one of the `b` Falcon encoders, randomly selecting which one to use.

There is also a whole section dedicated to the use of Falcon in PoR …. this needs further study.

