Ethereum L2 Rollups
===================

A quick and dirty overview of existing rollups and their suitability for hosting
the Codex marketplace smart contracts. To interact with these contracts, the
participants in the network create blockchain transactions for purchasing and
selling storage, and for providing storage proofs that are then checked
on-chain. It would be too costly for these transactions to happen on Ethereum
main net, which is why this document explores L2 rollups as an alternative.

Main sources used:
- individual websites of the rollup projects
- https://l2beat.com
- https://blog.kroma.network/l2-scaling-landscape-fees-and-max-tps-fe6087d3f690

Requirements
------------

For the storage marketplace to work, we have the following requirements for a
rollup:
1. Low gas costs; if gas is too costly then the business case of storage
   providers disappears
2. EVM compatibility; this shortens our time to market because we already have
   Solidity contracts
3. Support for BN254 elliptic curve precompiles (ecAdd, ecMul, ecPairing) for
   the proof system
4. High throughput; our current proof system that checks all proofs separately
   on chain requires a large number of transactions per second
5. Censorship resistant; an L2 operator should not have the power to exclude
   transactions from certain people or apps

Note that low latency is not a requirement; it's ok to have latency equivalent
to L1, which is in the order of tens of seconds.

Main flavours
-------------

Although there are many L2 rollups, there is a limited number of technical
stacks that underly them.

There is the family of purely optimistic rollups, that rely on fraud proofs to
ensure that they are kept honest:
- Arbitrum
- Optimism / OP Stack
- Fuel

And there are the rollups that rely on zero-knowledge proofs to prove that they
act honestly:
- Polygon zkEVM / CDK
- Linea
- zkSync
- Scroll

And there's Taiko, which uses a combination of zero-knowledge proofs and fraud
proofs to keep the network honest:
- Taiko

Gas prices
----------

A rough approximation of average gas prices for submitting a Codex storage proof
for each rollup:

| Rollup              | Average proof price | Potential profit |
| ------------------- |  ------------------ | ---------------- |
| Mantle              | $0.0000062723       |      $2.58       |
| Boba network        | $0.0016726250       |     -$2.54       |
| Immutable zkEVM     | $0.0073595500       |    -$20.01       |
| Arbitrum            | $0.0083631250       |    -$23.09       |
| zkSync Era          | $0.0209078125       |    -$61.63       |
| Base                | $0.0418156250       |   -$125.86       |
| Optimism            | $0.0836312500       |   -$254.32       |
| Polygon zkEVM       | $0.1254468750       |   -$382.77       |
| Blast               | $0.1672625000       |   -$511.23       |
| Scroll              | $0.2090781250       |   -$639.69       |
| Taiko               | $0.2508937500       |   -$768.15       |
| Metis               | $0.4014300000       | -$1,230.59       |
| Linea               | $0.8363125000       | -$2,566.55       |

This table was created by eyeballing the gas cost and token price graphs for
each L2, and [calculating the USD costs](rollups.ods) for a proof from that. We
did not include rollups that are not EVM compatible.

Potential profit (per month per TB) is calculated by assuming operational costs
of $1.40 and revenue of $4.00 per TB per month, an average slot size of 10 GB,
and an average of 1 proof per slot per day.

EVM compatibility
-----------------

This shows which rollups are EVM compatible, and whether they support the BN254
elliptic curve precompiles that we require for verification of our storage
proofs (ecAdd, ecMul, ecPairing).

| Rollup                | EVM compatible | Elliptic Curve operations |
| --------------------- | -------------- | ------------------------- |
| Arbitrum              | Yes            | Yes                       |
| Base                  | Yes            | Yes                       |
| Blast                 | Yes            | Yes                       |
| Boba network          | Yes            | Yes                       |
| Immutable zkEVM       | Yes            | Yes                       |
| Linea                 | Yes            | Yes                       |
| Mantle                | Yes            | Yes                       |
| Metis                 | Yes            | Yes                       |
| Optimism              | Yes            | Yes                       |
| Polygon zkEVM         | Yes            | Yes                       |
| Scroll                | Yes            | Yes                       |
| Taiko                 | Yes            | Yes                       |
| zkSync Era            | Yes            | No                        |
| Fuel L2 V1            | No             | N/A                       |
| Fuel Rollup OS        | No             | N/A                       |
| Immutable X           | No             | N/A                       |
| Polygon Miden         | No             | N/A                       |
| Starknet              | No             | N/A                       |
| zkSync lite           | No             | N/A                       |


Throughput
----------

A rough approximation of the maximum number of transactions that a rollup can
handle, and the maximum size of the storage network that it might support:

| Rollup                | Maximum TPS | Maximum storage |
| --------------------- | ----------- | --------------- |
| zkSync Era            | 750         | 1236 PB         |
| Starknet              | 484         |  798 PB         |
| Optimism              | 455         |  750 PB         |
| Base                  | 455         |  733 PB         |
| Mantle                | 400         |  659 PB         |
| Metis                 | 357         |  588 PB         |
| Polygon zkEVM         | 237         |  391 PB         |
| Arbitrum              | 226         |  372 PB         |
| Boba network          | 205         |  338 PB         |
| Scroll                |  50         |   82 PB         |
| Taiko                 |  33         |   54 PB         |
| Blast                 |   ?         |    ?            |
| Immutable zkEVM       |   ?         |    ?            |
| Linea                 |   ?         |    ?            |
| Fuel L2 V1            |   ?         |    ?            |
| Fuel Rollup OS        |   ?         |    ?            |
| Immutable X           |   ?         |    ?            |
| Polygon Miden         |   ?         |    ?            |
| zkSync lite           |   ?         |    ?            |

Maximum size of the storage network is [calculated](rollups.ods) assuming an
average 1 proof per 24 hours per slot, average slot size 10 GB, and average
erasure coding rate of 1/2. In practice the calculated maximum storage is going
to be less, because we can't use up the entirety of the rollup capacity.

Maximum TPS figures are taken from an [overview document by
Kroma](https://blog.kroma.network/l2-scaling-landscape-fees-and-max-tps-fe6087d3f690)

Censorship resistance
---------------------

Censorship resistance can be achieved by having a decentralized architecture,
where anyone is allowed to propose blocks and there are are no admin rights that
allow a rollup operator to change the rules in their favour.

Only Fuel L2 V1 has all these properties, the others don't. And because Fuel L2
V1 is a payment network without smart contracts it is not suitable for the Codex
marketplace. This means that at this moment there is no censorship resistant
rollup that can host the Codex marketplace.

Taiko is one of the few rollups that has a decentralized architecture, and it's
committed to becoming permissionless. However, at the moment it is not.

| Rollup                | Decentralized | Permissionless  | Adminless    |
| --------------------- | ------------- | --------------- | ------------ |
| Fuel L2 V1            | Yes           | Yes             | Yes          |
| Metis                 | Yes           | No              | No           |
| Taiko                 | Yes           | No              | No           |
| Arbitrum              | No            | N/A             | N/A          |
| Base                  | No            | N/A             | N/A          |
| Blast                 | No            | N/A             | N/A          |
| Boba network          | No            | N/A             | N/A          |
| Fuel Rollup OS        | No            | N/A             | N/A          |
| Immutable X           | No            | N/A             | N/A          |
| Immutable zkEVM       | No            | N/A             | N/A          |
| Linea                 | No            | N/A             | N/A          |
| Mantle                | No            | N/A             | N/A          |
| Optimism              | No            | N/A             | N/A          |
| Polygon zkEVM         | No            | N/A             | N/A          |
| Polygon Miden         | No            | N/A             | N/A          |
| Scroll                | No            | N/A             | N/A          |
| Starknet              | No            | N/A             | N/A          |
| zkSync lite           | No            | N/A             | N/A          |
| zkSync Era            | No            | N/A             | N/A          |

Conclusion
----------

There seems to be no rollup that matches all the requirements that we listed in
the beginning of the document. The most pressing problem is that only Mantle
seems to be cheap enough to allow storage providers to turn a profit, given the
assumptions of an average 10 GB slot size and 1 proof per 24 hours. It is
unclear whether these low prices are sustainable in the long run. If we want to
have more choice on where to deploy, then we either need to reduce the number of
on-chain proofs in Codex drastically, or we need to find a way to reduce rollup
transaction costs.

Luckily we're already working on reducing the number of proofs by introducing
proof aggregation, but the analysis in this document shows that we might not be
able to launch  a storage network without it. Reducing the number of proofs also
ensures that the network can grow to a larger total size.

When we look at reducing the transaction costs, then the best thing to focus on
is getting rid of the need to post transactions on L1 in blobs. This is by far
the most expensive part of running a rollup, and this is most likely also why
Mantle is the only rollup in this overview that is cheap enough; it uses EigenDA
instead of posting to L1. In this respect, it might also be interesting to look
at Arbitrum AnyTrust, which has a similar design. We could also consider
creating a fork of an existing rollup and use Codex as the DA layer. Some of the
new modular architectures for creating rollups, such as
[Espresso](https://www.espressosys.com/), [Astria](https://www.astria.org/),
[Radius](https://www.theradius.xyz/), [Altlayer](https://www.altlayer.io/) and
[NodeKit](https://www.nodekit.xyz/) could also make it easier to experiment with
different rollup designs.
