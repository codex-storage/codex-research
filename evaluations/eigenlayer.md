Eigenlayer
==========

2024-05-29

A review of the Eigenlayer and EIGEN token whitepapers, with some thoughts on
how this could be applied to Codex.

* [Eigenlayer whitepaper](https://docs.eigenlayer.xyz/assets/files/EigenLayer_WhitePaper-88c47923ca0319870c611decd6e562ad.pdf)
* [EIGEN token whitepaper](https://docs.eigenlayer.xyz/assets/files/EIGEN_Token_Whitepaper-0df8e17b7efa052fd2a22e1ade9c6f69.pdf)

Eigenlayer
----------

The core idea of Eigenlayer is to reuse the collateral that is already staked on
the Ethereum beacon chain for other protocols beside Ethereum. The collateral
that Ethereum validators put up to ensure that they stick to the Ethereum
consensus protocol, is used to also ensure that they also follow to the rules of
other protocols. In exchange for this, they get rewarded additional fees from
these protocols.

Eigenlayer has an open marketplace in which protocols advertise themselves, and
validators can opt in to help secure these protocols by restaking their
collateral (§2).

The main mechanism that is used, is to have the Ethereum validators set the
withdrawal address of their collateral to an Eigenlayer smart contract (§2.1).
This means that when the validator behaved nicely on the Ethereum network and
wants to exit the network, their stake will then be passed to an Eigenlayer
contract. This Eigenlayer contract will then perform additional checks to ensure
that the validator wasn't slashed by any additional protocols that the validator
participated in, before releasing the stake (§3.1).

### Incentives and centralization ###

This raises the question: what happens to the incentive for the validator to
behave nicely if their collateral has already been forfeited in Eigenlayer. And
what would the consequences for the Ethereum beacon chain be if this were to
happen to a large number of validators simultaneously? In the whitepaper two
mitigations are mentioned: security audits (§3.4.2) and the ability to veto
slashings (§3.5). Before a protocol is allowed onto the marketplace it needs to
be verified through a security audit. And if the protocol were to inadvertently
slash a large group of validators (e.g. through a bug in its smart contract),
then there is a governing group that can veto these slashings. The downside to
these mitigations is that they are both centralizing forces, because there is
now a small group of people that decide whether a protocol is admitted to the
marketplace, and a small group of people that can veto slashings.

Eigenlayer claims to incentivize decentralization by allowing protocols to
specify that they only want to make use of stake that is put up by home stakers
(§4.4). However, given the permissionless nature of Ethereum, it is not possible
to distinguish home stakers from a large centralized player with many
validators, each having its own address.

A further centralizing force in Eigenlayer is its license, which is not an open
source license. This means that only the Eigenlayer developers can change the
Eigenlayer code, and forking is not allowed.

### Potential use cases for Codex ###

There are a couple of places in Codex that might benefit from restaking. We
could allow Ethereum validators to use (a part of) their stake on the beacon
chain for filling slots in storage contracts. There are a few downsides to this.
It becomes rather difficult to reason about how high the stake for a storage
contract should be when when the stake behind a storage provider's promise can
be shared with a number of other protocols (§3.4.1). Codex uses part of the
slashed stake to incentivize repair, which would not be possible with restaking,
because the stake only becomes available in Eigenlayer after the validator stops
validating the beacon chain, and withdraws its collatoral. That is, if the stake
hasn't already been slashed by the beacon chain. Also, the hardware requirements
for running an Ethereum validator are sufficiently different from the
requirements of running a Codex provider, that we do not expect there to be many
people that run both.

We might also use restaking to keep proof aggregators honest (§4.1, point 6).
Preferably using a combination of staked Codex tokens and restaked ETH (§4.4),
so that we increase the utility of the Codex token while also guarding against
value loss of the token.

And finally, we might use restaking to keep participants in a nano payments
scheme honest (§4.1, point 2 and 8). We intend to add bandwidth payments to
Codex, and for this we need nano payments, for which a blockchain is too slow.
Ideally we'd have a lighter form of consensus for these payments. The validators
of this lighter form of consensus could be kept honest by restaking.

EIGEN Token
-----------

The EIGEN token is a separate project only marginally related to Eigenlayer. It
allows staking to disincentivize subjective faults. In contrast to objective
faults, subjective faults cannot be coded into a smart contract, but need to be
adjucated by people (§1.2).

This is implemented though a forkable token (§2.3.1) called EIGEN. Every time a
subjective decision needs to be made, someone can create a new EIGEN' token, and
start using that instead of the old token. If everyone agrees, then the new
token will gain in perceived value, while the perceived value of the old token
approaches 0.

In the whitepaper a protocol is described to ensure that forking the token
doesn't impact long-term holders of the token (§2.7).

A centralizing force in the design is the security council, a small group of
people in charge of freezing and/or upgrading the smart contracts (§2.7.4).

Conclusion
----------

Given the centralizing aspects of Eigenlayer, it is probably not a good
foundation to build parts of the Codex protocol. The idea of restaking is an
interesting one, but not without its own risks that are not easy to quantify.

The EIGEN token is probably not interesting for Codex, because we've taken great
effort to ensure that bad behaviour on the network is either objectively
punishable or economically disincentivized, negating the need for human
adjucation.
