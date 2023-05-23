Ethereum Account Abstraction
============================

A high level overview of what the current state of account abstraction in
Ethereum is and what role it might play in the Codex design.

TL;DR: Account abstraction does not impact the design of Codex

Current state
-------------

There have been several proposals to introduce [account abstraction][roadmap]
for Ethereum. Most of them required changes to the consensus mechanism, and were
therefore postponed and have not made it into mainnet. [ERC-4337][4337] is a
newer proposal that uses smart contracts and does not require changes to the
consensus mechanism. It uses a separate mempool for transaction-like objects
called "user operations". They are picked up by bundlers who bundle them into an
actual transaction that is executed on-chain. ERC-4337 is the closest to being
usable on mainnet.

An ERC-4337 entry point [contract][entrypoint] is deployed on mainnet since
March 2023. One bundler seems to be active ([Stackup][stackup]), although at the
time of writing it seems to be running neither regularly nor without errors.

Codex use cases
---------------

Potential Codex use cases for account abstraction are:

- Paying for storage without requiring ETH to pay for gas
- Checking for missing storage proofs

Clients pay for storage and hosts put down collateral in the Codex marketplace.
They need both ERC-20 tokens for payment and collateral and ETH for gas. We
expect wallet providers to make full use of ERC-4337 to implement transactions
where gas is paid for by ERC-20 tokens instead of ETH. These wallets can then be
used to interact with the Codex marketplace. This does not require a change to
the design of Codex itself.

In our current design for the Codex marketplace we require hosts to provide
[storage proofs][proofs] at unpredictable times. If they fail to provide a
proof, then a simple [validator][validator] can mark a proof as missing. Even
though the marketplace smart contract has all the logic to determine whether a
proof is actually missing, we need the validator to initiate a transaction to
execute the logic.

Some of the write-ups on account abstraction seem to indicate that account
abstraction would allow for contracts to initiate transactions, or for
subscriptions and repeat payments. However, I could not find any indications in
the specifications that this would be the case. Certainly ERC-4337 does not
allow for this. This means that account abstraction as it currently stands
cannot be used to replace the validator when checking for missing storage
proofs.

[roadmap]: https://ethereum.org/en/roadmap/account-abstraction/
[4337]: https://eips.ethereum.org/EIPS/eip-4337
[entrypoint]: https://etherscan.io/address/0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789
[stackup]: https://www.stackup.sh/
[proofs]: https://github.com/codex-storage/codex-research/blob/33cd86af4d809c39c7c41ca50a6922e6b5963c67/design/storage-proof-timing.md
[validator]: https://github.com/codex-storage/nim-codex/pull/387
