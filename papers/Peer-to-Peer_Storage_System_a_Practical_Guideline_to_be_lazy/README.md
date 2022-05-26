# Peer-to-Peer Storage Systems: a Practical Guideline to be Lazy

## Authors

- Frederic Giroire - frederic.giroire@sophia.inria.fr
- Julian Monteiro - julian.monteiro@sophia.inria.fr
- Stephane Perennes - stephane.perennes@sophia.inria.fr

### DOI

- https://doi.org/10/c47cmb

## Summary

The paper presents the different trade-offs for implementing erasure code reconstruction after failures. The paper focuses on Reed Solomon encoding and analyses the number of encoding blocks (called fragments in the paper) the number of parity blocks as well as the minimum number of redundant blocks before triggering block repairs. The authors propose a Markov chain model and they look at the impact of these parameters on network bandwidth as well as block loss rate.

### Main ideas

* Every reconstruction implies data traffic over the network
* If we reconstruct after every single block loss (eager repair), we consume too much bandwidth
* If we wait for several blocks to be lost (Lazy repair), we can reconstruct the missing block just one time and save bandwidth
* If we wait too long before reconstruction, data might be lost if multiple erasures occur simultaneously
* A model can help us understand the impact of the parameters s, r and r0 on bandwidth and loss rate
* The distribution of blocks redundancy is a bit counter-intuitive
 

### Observations

* It is assumed that the block reconstruction process is much faster than the peer failure rate
* In P2P networks, failures are considered independent and memory-less a=1/MTTF
* The probability for a peer to be alive after T time steps is P_a = (1 − a)^T
* They work on the Galois Field GF (2^8)), which leads to the practical limitation s + r ≤ 256
* The failure rate (1 year for 1 disk) is very conservative
* Overall the model is elegant and the results are very clear and interesting
 
### Other ideas

* The stretch factor is computed as follows: k+m/k
* Block sizes can be chosen depending on the main purpose of the storage system
  * Archival mode: Good with large blocks because few reads
  * Filesystem mode: Good with small blocks because it allows easy reads and edits

