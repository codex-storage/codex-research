Codex side chain
================

This document looks at the economic viability of running an Ethereum side chain
that is specifically tailored for the Codex marketplace. Existing Ethereum
[rollups][1] and side chains seem to be too expensive by about a factor of 100
for our current storage proof scheme (without proof aggregation). We'd like to
find out if running our own side chain could sufficiently lower the transactions
costs.

[1]: ../evaluations/rollups.md

EVM opcode pricing
------------------

Ethereum transactions consist of EVM operations. Each operation is priced in
amount of gas. Some operations [are more expensive than others][2], mainly
because they require more resources (cpu, storage) than others. Gas costs are
also specifically engineered to withstand DoS attacks on validators.

Tweaking the gas prices of EVM opcodes does not seem to be the most viable path
to lowering transaction costs, because it only determines how expensive
operations are relative to one another, they don't determine the actual price.
It is also difficult to oversee the security risks.

[2]: https://notes.ethereum.org/@poemm/evm384-update5#Background-on-EVM-Gas-Costs

Gas pricing
-----------

The biggest factor that determines the actual costs of transactions is the gas
price. The transaction costs is [determined according to the following
formula][3] as specified by [EIP-1559][4]:

`fee = units of gas used * (base fee + priority fee)`

The base fee is calculated based on how full the latest blocks are. If they are
above the target block size of 15 million gas, then the base fee increases. If
they are below the target block size, then the base fee decreases.
The base fee is burned when the transaction is included.

The priority fee is set by the transaction sender, and goes to the validators.
It is a mechanism for validators to prioritize transactions. It also acts as an
incentive for validators to not produce empty blocks.

Both priority base fee and transaction fee go up when there is more demand
(submitted transactions) than there is supply (maximum transactions per second).
This is the main reason why transactions are as expensive as they are:

"No transaction fee mechanism, EIP-1559 or otherwise, is likely to substantially
decrease average transaction fees; persistently high transaction fees is a
scalability problem, not a mechanism design problem" -- [Tim Roughgarden][5]

[3]: https://ethereum.org/en/developers/docs/gas/#how-are-gas-fees-calculated
[4]: https://eips.ethereum.org/EIPS/eip-1559
[5]: http://timroughgarden.org/papers/eip1559.pdf


The scalability problem
-----------------------

Ultimately high transaction costs is a scalability issue. And unfortunately
there are [no easy solutions][6] for increasing the amount of transactions that
the chain can handle. For instance, just increasing the block size introduces
several issues. Increasing block size increases the amount of resources that
validators need (cpu, memory, storage, bandwidth). This means that it becomes
more expensive to run a validator, which leads to a decrease in the number of
validators, and an increase in centralization. It also increases block time,
because there is more time needed to dissemminate the block. And this actually
decreases the capacity of the network in terms of transactions per second, which
counters the positive effect that you get from increasing the block size.

[6]: https://cryptonews.com/news/contrary-to-musk-s-idea-you-can-t-just-increase-block-size-s-10426.htm

Validator costs
---------------

To get an idea of the actual costs for running a chain, we estimate the hardware
costs associated with executing one gas. This should give us an idea of the
lowest price at which it is still economically viable to run validators.

Back of envelope calculations

Pylogon PoS:
- has about 100 validators
- requires [amazon m5d.4xlarge][8]
- which costs [$285][9] per month
- gas limit is `30 000 0000`
- in a month there are approximately `1 100 000 000` blocks
- which means costs per gas are `100 * $285 / (30 000 0000 * 1 100 000 000) = $ 0.0000000000008`
- while average gas price is `$0.00000002` (a factor of 25000 higher than the cost)

Ethereum:
- has about 1 000 000 validators
- validator costs: [$20 / month][7]
- gas limit is 15 000 0000 on average
- in a month there are approximately 215 000 blocks
- which means costs per gas are 1 000 000 * $20 / (15 000 000 * 215 000) = $ 0.000006
- while current gas price is $0.000035 (a factor of 6 higher than the cost)

TODO: check calculations

It seems that Ethereum gas price is about 1 order of magnitude higher than the
the actual costs for the resources required.

The Polygon PoS gas price is about 4 orders of magnitude higher than the actual
costs for the resources needed.

[7]: https://www.launchnodes.com/ln_products/ethereum-validator-node-prysmatic-client/
[8]: https://docs.polygon.technology/pos/how-to/validator/validator-system-requirements/#recommended-system-requirements
[9]: https://instances.vantage.sh/aws/ec2/m5d.4xlarge

Conclusion
----------

The main reason why transactions are too expensive on existing chains and
rollups is because they are utilized to their capacity. This creates a higher
demand than there is supply, increasing prices. The actual costs of running a
chain seem to be ok for running the Codex marketplace, but we need to either
increase capacity or limit the amount of transactions to ensure that transaction
prices do not become too high.

So it seem to be viable to start with a side chain for Codex, while there is no
high demand yet. This gives us time to work on reducing the number of
transactions (by aggregating proofs for instance), and increasing the
transactions per second (by sharding for instance) as the Codex network becomes
more popular.