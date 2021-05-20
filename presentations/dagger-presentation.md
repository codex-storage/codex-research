---
title: Dagger
theme: solarized
revealOptions:
    controls: false
    progress: false
    transition: 'fade'
---

# Dagger

Decentralized Storage

Note:
Briefly describe what Dagger is.

---


## Why Dagger? 

![IPFS](images/others.svg) <!-- .element: width="30%"-->

Note:
Decentralized storage is a fundamentally unsolved problem.  
P2P storage hasn't taken off, why?  
Without reliable storage, dapps won't take off.  
Needs same guarantees as cloud storage, and then some.

---

## Reliability

predictable

accessible

Note:
Reliability is the property that is most lacking in p2p storage networks.  
Predictable storage duration.  
Storage is always accessible to you.

---

## Tweak the protocol?

Note:

Why is reliability missing in existing networks?  
Is there something we can tweak in the protocol?  
Bittorrent and IPFS became specialized networks around popular data.  
Blockchains require block data to run the blockchain.  
For generic storage, we can't tweak the storage protocol, we need incentives.  

---

## Incentives

storage

bandwidth

![Costs of resources](images/cost-of-resources.svg) <!-- .element: width="60%"-->

Note:
Free market to handle resource allocation  
Incentives have multiple purposes  
Incentives compensate for resources  
Incentives provide security; it makes economic sense to stick to the rules  
Storage incentives provide storage reliability  
Bandwidth incentives provide retrievability (dynamic CDN)  
Bandwidth incentives prevent denial of service, spamming  
Incentives encourage participation in the network  

---

## Proofs

data possession

retrievability


Note:
How do we achieve reliability?  
Proof of data possession over time  
Proof of retrievability (interactive)
Prevents data withholding (ransomware), we do not have legal recourse like cloud services

---

proof of data possession

![Proof of storage 1](images/proof-of-storage-1.svg) <!-- .element: width="60%"-->

Note:
Proof of storage.  
File is divided into chunks.  
Over time, proofs of different randomly selected chunks are requested

---

proof of data possession

![Proof of storage 2](images/proof-of-storage-2.svg) <!-- .element: width="60%"-->

Note:
We improve on this scheme by making sampling events dependent on each other.  
This increases the odds of detecting missing chunks over time.

---

proof of retrievability

![Proof of retrievability](images/proof-of-retrievability.svg)  <!-- .element: width="70%"-->

Note:
Prevents data withholding (ransomware)  
The prover does not know when it's being verified

---

## global cloud storage market

`$` 61 billion in 2020  
`$` 390 billion in 2028

Note:
source: https://www.fortunebusinessinsights.com/cloud-storage-market-102773/s

---

## Privacy & Anonymity

![Privacy Stack](images/privacy.svg) <!-- .element: width="40%"-->

Note:
Dagger layer: identities used for incentives and payments are pseudonymous.  
Libp2p layer: peer identity is pseudonymous.  
IP layer: depending on the need, there are several solutions to choose from

---

## Network Overview

![Network](images/network.svg) <!-- .element: width="65%"-->

---

## Software Stack

![Software Stack](images/stack.svg) <!-- .element: width="70%"-->

---

## Research agenda

  - proofs for large data sets  
  - formal/emperical evidence
  - consensus engine

Note:
Small proofs, constant size, aggregatable, computationally light  
Zero knowledge proofs  
Formal proofs/emperical evidence that our algorithms have the desired properties  
Model the network to observe emergent properties  
How does the storage network interact with a consensus engine  
