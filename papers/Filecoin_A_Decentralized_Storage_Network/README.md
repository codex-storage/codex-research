# Filecoin: A Decentralized Storage Network

## Authors

- Juan Benet - juan.benet.ai

### DOI

-

## Summary

This paper describes the mechanis behind the decentralized storage network called Filecoin.

### Main ideas

**DSN: Decentralized storage Network** (No trusted parties)
DSN must guarantee:
 * Data integrity
 * Data retrievability (Clients can eventually retrieve the data)
 * Management fault tolerance
 * Storage fault tolerance

Other Properties:
 * Publicly verifiable
 * Auditable
 * Incentive-compatible

**Proof of Storage** : Provable Data Possession and Proof of Retrievability.

 * Sybil attacks: multiple fake identities storing only 1 copy of the data.
 * Outsourcing Attacks: Quick request to other storage node.
 * Generation Attacks: regenerate the data on the fly when possible.

**PoRep**: Proof of Replication, not to confuse with Proof of Retrievability.

**Proof of spacetime**: Repeat PoRep over time.

Seal operation makes a permutation of the replica, so that proofs can only work for the specific replica, therefore storing n replicas implies allocating n times the size of the dataset.
Setup needs to be 10-100 times more time consuming than the proof, otherwise setup, request and proofs can be generated on the fly.

Clients pay to store data and also to retrieve it. Retrieval Miners can be the same as Storage Miners, or simply ask from Storage nodes and send to the client, keeping some data in cache. This is some kind of cache mechanism. The benefit of only being a Retrieval Miner is that you are not responsible for storage, you don't lose money if you lose data.

Achieving Retrievability: The Put specifies (f,m)-tolerant, meaning m storage miners storing the data and a maximum of f faults need to be tolerated.

The Market Place is off-chain. Data sent by mini-blocks accompanied with micro-payments for each mini-block.

Power fault tolerance: N is total “power” of the network and f is the part of the power controlled by adversarial nodes.

More storage in use = more power on the network, more probability to be elected and create blocks.

### Observations

(Copy-paste from Mark's evaluation)

**Pros**:

 * Clients do not need to actively monitor hosts. Once a deal has been agreed upon, the network checks proofs of storage.
 * The network actively tries to repair storage faults by introducing new orders in the storage market. (§4.3.4).
 * Integrity is achieved because files are addressed using their content hash (§4.4).
 * Marketplaces are explicitly designed and specified (§5).
 * Micropayments via payment channels (§5.3.1).
 * Integration with other blockchain systems such as Ethereum (§7.2) are being worked on.

**Cons**:

 * Filecoin requires its own very specific blockchain, which influences a lot of its design. There is tight coupling between the blockchain, storage accounting, proofs and markets.
 * Proof of spacetime is much more complex than simple challenges, and only required to make the blockchain work (§3.3, §6.2)
 * A miners influence is proportional to the amount of storage they're providing (§1.2), which is an incentive to become big. This could lead to the same centralization issues that plague Bitcoin.
 * Incentives are geared towards making the particulars of the Filecoin design work, instead of directly aligned with users' interest. For instance, there are incentives for storage and retrieval, but it seems that a miner would be able to make money by only storing data, and never offering it for retrieval. Also, the incentive for a miner to store multiple independent copies does not mean protection against loss if they're all located on the same failing disk.
 * The blockchain contains a complete allocation table of all things that are stored in the network (§4.2), which raises questions about scalability.
 * Zero cash entry (such as in Swarm) doesn't seem possible.
 * Consecutive micropayments are presented as a solution for the trust problems while retrieving (§5.3.1), which doesn't entirely mitigate withholding attacks.
 * The addition of smart contracts (§7.1) feels like an unnecessary complication.

### Other ideas

Nice Figure 1 showing the state machine for each component.

Figure 2 shows a nice workflow.

What is the relationship between m and f? Can’t m be just f+1? Or is this to have some margin?

The parameters f and m are never shown in the PUT description in figure 7.


