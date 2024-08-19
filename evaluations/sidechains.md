Side chains
===========

This document looks at the economics of running the Codex marketplace contracts
on an Ethereum side chain. Both existing side chains and running a dedicated
sidechain for Codex are considered. Existing Ethereum [rollups][1] seem to be
too expensive by about a factor of 100 for our current storage proof scheme
(without proof aggregation). We'd like to find out if using a side chain could
sufficiently lower the transactions costs.

[1]: ../evaluations/rollups.md


Existing side chains
--------------------

First we'll take a look at Polygon PoS and Gnosis chain to determine the average
gas costs for submitting a storage proof on these chains. Then we'll estimate
what the operational costs are of running these chains and compare that against
their revenue in gas fees. This is done to see whether there is any room for
reducing prices should we want to run a dedicated side chain for Codex.

### Gas prices ###

A rough approximation of average gas costs for submitting a Codex storage proof
for these chains:

| Side chain          | Average proof costs | Potential profit |
| ------------------- |  ------------------ | ---------------- |
| Polygon PoS         | $0.0070250250       |    -$18.98       |
| Gnosis chain        | $0.0050178750       |    -$12.81       |

This table was created by eyeballing the gas cost and token price graphs for
each chain over the past 6 months, and [calculating the USD
costs](sidechains.ods) for a proof from that.

Potential profit (per month per TB) is calculated by assuming operational costs
of $1.40 and revenue of $4.00 per TB per month, an average slot size of 10 GB,
and an average of 1 proof per slot per day.

### Throughput ###

A rough approximation of the maximum number of transactions that a chain can
handle, and the maximum size of the storage network that it might support:

| Side chain            | Maximum TPS | Maximum storage |
| --------------------- | ----------- | --------------- |
| Polygon PoS           | 255         |  420 PB         |
| Gnosis chain          | 156         |  257 PB         |

Maximum size of the storage network is [calculated](sidechains.ods) assuming an
average 1 proof per 24 hours per slot, average slot size 10 GB, and average
erasure coding rate of 1/2.

### Decentralization ###

Polygon PoS has substantially less validators than Gnosis chain:

| Side chain            | Number of validators |
| --------------------- | -------------------- |
| Polygon PoS           |                  100 |
| Gnosis chain          |              200 000 |

### Network costs ###

To get an idea of the actual costs for running a chain, we estimate the hardware
costs needed to keep the network running. We take the cost of running a single
validator and multiply this by the number of validators. This should give us an
idea how much of the gas price is used to cover operational costs, and how much
is profit. These are [back of the envelope calculations](sidechains.ods) using
data from the past 6 months to get an idea of the order of magnitude, not meant
to be very accurate:

| Side chain   |  hardware costs    | network fees     | cost / revenue ratio  |
| ------------ | ------------------ | -----------------| --------------------- |
| Polygon PoS  |    $28 000 / month | $840 000 / month |                    3% |
| Gnosis chain | $4 000 000 / month |  $15 000 / month |                26667% |

While Polygon PoS seem to have a healthy margin for profit, the validators of
the Gnosis chain are spending about 250x more on hardware costs than is covered
by the network fees. This is mostly due to the large amount of validators, and
seems to be compensated for by reserving tokens and using them for paying out
[validator rewards][2]. Also, Polygon PoS has a utilization of about 90%,
whereas Gnosis chain has a utilization of about 25%.

[2]: https://forum.gnosis.io/t/gno-utility-and-value-proposition/2344#current-gno-distribution-and-gno-burn-5


A custom side chain for Codex
-----------------------------

Next, we'll look at ways in which we could reduce gas costs by deploying a
dedicated side chain for Codex.

### EVM opcode pricing ###

Ethereum transactions consist of EVM operations. Each operation is priced in
amount of gas. Some operations [are more expensive than others][3], mainly
because they require more resources (cpu, storage) than others. Gas costs are
also specifically engineered to withstand DoS attacks on validators.

Tweaking the gas prices of EVM opcodes does not seem to be the most viable path
to lowering transaction costs, because it only determines how expensive
operations are relative to one another, they don't determine the actual price.
It is also difficult to oversee the security risks.

[3]: https://notes.ethereum.org/@poemm/evm384-update5#Background-on-EVM-Gas-Costs

### Gas pricing ###

The biggest factor that determines the actual costs of transactions is the gas
price. The transaction costs is [determined according to the following
formula][4] as specified by [EIP-1559][5]:

`fee = units of gas used * (base fee + priority fee)`

The base fee is calculated based on how full the latest blocks are. If they are
above the target block size of 15 million gas, then the base fee increases. If
they are below the target block size, then the base fee decreases. The base fee
is burned when the transaction is included. The priority fee is set by the
transaction sender, and goes to the validators. It is a mechanism for validators
to prioritize transactions. It also acts as an incentive for validators to not
produce empty blocks.

Both priority base fee and transaction fee go up when there is more demand
(submitted transactions) than there is supply (maximum transactions per second).
This is the main reason why transactions are as expensive as they are:

"No transaction fee mechanism, EIP-1559 or otherwise, is likely to substantially
decrease average transaction fees; persistently high transaction fees is a
scalability problem, not a mechanism design problem" -- [Tim Roughgarden][6]

[4]: https://ethereum.org/en/developers/docs/gas/#how-are-gas-fees-calculated
[5]: https://eips.ethereum.org/EIPS/eip-1559
[6]: http://timroughgarden.org/papers/eip1559.pdf


### The scalability problem ###

Ultimately high transaction costs is a scalability issue. And unfortunately
there are [no easy solutions][7] for increasing the amount of transactions that
the chain can handle. For instance, just increasing the block size introduces
several issues. Increasing block size increases the amount of resources that
validators need (cpu, memory, storage, bandwidth). This means that it becomes
more expensive to run a validator, which leads to a decrease in the number of
validators, and an increase in centralization. It also increases block time,
because there is more time needed to dissemminate the block. And this actually
decreases the capacity of the network in terms of transactions per second, which
counters the positive effect that you get from increasing the block size.

[7]: https://cryptonews.com/news/contrary-to-musk-s-idea-you-can-t-just-increase-block-size-s-10426.htm

Conclusion
----------

The gas prices on existing side chains that we looked are not low enough for
storage providers to turn a profit, as long as we haven't implemented proof
aggregation yet.

From the costs analysis of Polygon PoS it seems feasible to launch a
not-for-profit dedicated side chain for Codex that reduces transaction costs by
about a factor of 10. This should be enough for storage providers to start
making a very modest profit if they charge $4/TB/month. Polygon PoS achieves
this by keeping a relatively low amount of validators, which is something to
keep in mind when deploying a side chain for Codex. Also, as soon there are more
transactions than fit in the blocks, and the chain is running at capacity, then
the gas price will go up.

For the short term it seems viable to start with a dedicated side chain for
Codex, while there is no high demand yet. This gives us time to work on reducing
the number of transactions, for instance by aggregating storage proofs. In the
beginning the number of transactions won't be sufficient to cover the costs of
running validators, so some sponsoring of validators will be required to
bootstrap the chain.

For the medium term we can consider to have multiple side chains depending on
demand. If demand is reaching capacity of the existing side chain(s) then
another side chain is started. This ensures that none of the side chains runs at
full capacity, keeping the prices low. Because each side chain can be bridged to
main net, funds can be moved from one side chain to the other. The obvious
downside of this is fragmentation of the marketplace. However, the reason to add
a side chain is because demand is high, so each fragment should have a healthy
marketplace. Also, the Codex peer-to-peer network would not be fragmented, only
the marketplace. Meaning that there is still a single content-addressable data
space.

For the long term we should probably move to a blockchain that supports a higher
number of transactions at a lower cost than is currently available.
