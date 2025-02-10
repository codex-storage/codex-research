The Sui Smart Contracts Platform
================================

* [Sui Whitepaper](https://github.com/MystenLabs/sui/blob/main/doc/paper/sui.pdf)
* [Sui Tokenomics paper](https://github.com/MystenLabs/sui/blob/main/doc/paper/tokenomics.pdf), May 2022


Sui is an alternative to blockchains that is geared towards high performance. It
utilizes a UTXO and DAG based design that allows for parallelization. It uses a
delegated proof-of-stake model to keep the number of validators low while
keeping the design permissionless. It uses a storage fund to pay for persistent
storage.

Main ideas
----------

### Consensus ###

Transactions require approval from 2/3 of the validators (as measured by
delegated stake). Sui uses the minimum amount of consensus that is required for
a given transaction:

* For transactions on owned objects (controlled by a key) it uses byzantine
  consistent broadcast. (Whitepaper §4.3, "Sign once, and safety")
* For transactions on shared objects (modifiable by anyone) it uses a byzantine
  agreement protocol only on the *order* of conflicting transactions. Execution
  of the transaction happens after the order has been determined.  (Whitepaper
  §4.4, "Shared Objects" and §5, "Throughput")

Transactions on owned objects require 2 roundtrips to a quorum for byzantine
broadcast. Transactions on shared objects require 4-8 round trips to a quorum
for byzantine agreement. (Whitepaper §5, "Latency")

### Parallelism ###

Sui uses the
[Move](https://github.com/MystenLabs/sui/blob/main/doc/paper/sui.pdf) language
for programming smart contracts. Unlike the EVM languages, this language is
geared towards the inherent parallelism that is afforded by the UTXO and DAG
design. The language is not unique to Sui, it is used in other projects as well.
(Whitepaper §2)

### Storage ###
Persistent storage is paid for using a storage fund, whereby the storage fees
are collected, and the proceeds of investing (staking) this fund are used to pay
for future storage costs (Tokenomics §3.3, §5). Fees are rebated when deleting
data from storage (Tokenomics §5.1). This is designed in such a way that the
opportunity cost of locking up tokens is equal to the fees one would otherwise
pay for storage (Tokenomics §6.2)..

### Proof of stake ###

Avoids "rich-get-richer" forces of other proof-of-stake implementations,
specifically to ensure that validators enjoy viable business models regardless
of their delegated stake. Random selection is avoided, opting instead for a
model where everyone is rewarded according to their stake (Tokenomics §3.2,
§6.3)

Gas fees are payed out to both validators and the people that delegated their
stake to the validators. This is an extra incentive for delegators to keep an
eye on their chosen validator, and to move stake when the validator is not
behaving well. (Whitepaper §4.7, "Rewards and cryptoeconomics")

### Epochs ###
Keeps several parameters of the network constant during epochs, such as the
stake of the validators and (nominal) gas prices. Uses checkpointing to compress
state and allow for committee changes on epoch boundaries. (Whitepaper §4.7)

Promotes predictable gas prices by having validators indicate a gas price
upfront, and diminish their rewards if they do not honour this upfront gas
price. (Tokenomics §4.1, §4.3)

Observations
------------

### Contention ###

The Sui design nicely sidesteps contention issues with shared mutable UTXO state
(e.g. such as in Cardano) by performing the byzantine agreement protocol on the
order of the transactions, not on its execution. Therefore there is no need to
resubmit a transaction when someone else used the object/UTXO that you intended
to use. Uses references to objects/UTXOs without their serial number for mutable
state, to enable this. (Whitepaper §4.4, "Shared objects")

### Recovery ###

It also nicely solves an issue with byzantine consistent broadcast (e.g. as in
ABC) whereby funds are locked forever when conflicting transactions are posted.
Conflicting transactions are cleared on every epoch boundary. (Whitepaper §4.3,
"Disaster recovery" and §4.7, "Recovery")

### Inert stake ###

Sui mitigates the problem whereby an increasing amount of delegated stake can no
longer be re-assigned because the associated keys are lost (as could happen in
e.g. ABC). Stake delegation is an explicit action, instead of an implicit
side-effect of every transaction. The staking logic is implemented in a smart
contract, which allows the network to update the logic to deal with such issues.

### Validator reputation ###

Stake rewards are influenced by the (subjective) reputation that validators
report about other validators. It is unclear how far this can be gamed by
validator wishing to increase their rewards. (Tokenomics §4.1.2, §4.1.3)

### Storage fund viability ###

The storage fund seems based on the assumption that there is enough money to be
made from computation fees to pay for continued storage. The fund ensures that
validators earn a bigger cut of the computation fees based on the size of the
storage fund. This could be problematic when the amount of storage heavily
outweighs the amount of computation; for instance if Sui were used primarily as
a storage network. This is good to keep in mind when comparing the storage fund
model with rent-based models such as employed in Codex. (Tokenomics §3.2, §3.3)

The storage gas price remains constant within an epoch (Tokenomics §3.1). It is
unclear how the network should react when confronted with a sudden spike in
demand for storage. What would happen when the storage is price is low, and a
user decides to store massive amounts of data on the network?
