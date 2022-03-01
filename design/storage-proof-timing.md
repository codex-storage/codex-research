Timing of Storage Proofs
========================

We present a design that allows a smart contract to determine when proofs of
storage should be provided by hosts.

Context
-------

Hosts that are compensated for providing storage of data, are held accountable
by providing proofs of storage periodically. It's important that a host is not
able to pre-compute those proofs, otherwise it could simply delete the data and
only store the proofs.

A smart contract should be able to check whether those proofs were delivered in
a correct and timely manner. Either the smart contract will be used to perform
these checks directly, or as part of an arbitration mechanism to keep validators
honest.

Design 1: block by block
------------------------

A first design used the property that blocks on Ethereum's main chain arrive in
a predictable cadence; about once every 14 seconds a new block is produced. The
idea is to use the block hashes as a source of non-predictable randomness.

From the block hash you can derive a challenge, which the host uses together
with the stored data to generate a proof of storage.

Furthermore, we use the block hash to perform a die roll to determine whether a
proof is required or not. For instance, if a storage contract stipulates that a
proof is required once every 1000 blocks, then each new block hash leads to a 1
in 1000 chance that a proof is required. This ensures that a host should always
be able to deliver a storage proof at a moments notice, while keeping the total
costs of generating and validating proofs relatively low.

Problems with block cadence
---------------------------

We see a couple of problems emerging from this design. The main problem is that
block production rate is not as reliable as it may seem. The steady cadence of
the Ethereum main net is (by design) not shared by L2 solutions, such as
rollups.

Most L2 solutions therefore [warn][2] [against][3] the use of the block interval
as a measure of time, and tell you to use the block timestamp instead. Even
though these are susceptible to some miner influence, over longer time intervals
they are deemed reliable.

Another issue that we run into is that on some L2 designs, block production
increases when there are more transactions. This could lead to a death spiral
where an increasing number of blocks leads to an increase in required proofs,
leading to more transactions, leading to even more blocks, etc.

And finally, because storage contracts between a client and a host are best
expressed in wall clock time, there are going to be two different ways of
measuring time in the same smart contract, which could lead to some subtle bugs.

These problems lead us to the second design.

Design 2: block pointers
------------------------

In our second design we separate cadence from random number selection. For
cadence we use a time interval measured in seconds. This divides time into
periods that have a unique number. Each period represents a chance that a proof
is required.

We want to associate a random number with each period that is used for the proof
of storage challenge, and for the die roll to determine whether a proof is
required. But since we no longer have a one-on-one relationship between a period
and a block hash, we need to get creative.

EVM and solidity
----------------

For context, our smart contracts are written in Solidity and execute on the EVM.
In this environment we have access to the [most recent 256 block hashes][1], and
to the current time, but not to the timestamps of the previous blocks. We also
have access to the current block number.

Block pointers
--------------

We introduce the notion of a block pointer. This is a number between 0 and 256
that points to one of the latest 256 block hashes. We count from 0 (latest
block) to 255 (oldest available block).

         oldest                              latest
     - - - |-----------------------------------|
          255                    ^             0
                                 |
                              pointer

We want to associate a block pointer with a period such that it keeps pointing
to the same block hash when new blocks are produced. We need this because the
block hash is used to check whether a proof is required, to check a proof when
it's submitted, or to prove absence of a proof, all at different times.

To ensure that the block pointer points to the same block hash for longer
periods of time, we derive it from the current block number:

    pointer(period) = (blocknumber + period) % 256

Over time, when more blocks are produced, we get this picture:

     |
     |      - - - |-----------------------------------|
     |           255                          ^       0
     |                                        |
     |                                     pointer
     t
     i      - - - |-----------------------------------|
     m           255                      ^           0
     e                                    |
     |                                  pointer
     |
     |      - - - |-----------------------------------|
     |           255                  ^               0
     |                                |
     v                             pointer

Pointer duos
------------

There is one problem left when we use the pointer as we've just described.
Because of the modulus, there are periods in which the pointer wraps around. It
moves from 255 to 0 from one block to the next. This is undesirable because this
would mean that the proof requirements for a period can change between the
moment a proof is due and the moment a validator checks it. To counter this, we
introduce pointer duos:

    pointer1(period) = (blocknumber + period) % 256
    pointer2(period) = (blocknumber + period + 128) % 256


The pointers are 128 blocks apart, ensuring that when one pointer wraps, the
other remains stable.

     - - - |-----------------------------------|
          255   ^                ^             0
                |                |
              pointer          pointer

We allow hosts to choose which of the two pointers to use. This has implications
for the die roll that we perform to determine whether a proof is required.

Odds with two pointers
----------------------

If we want a host to provide a proof on average once every N blocks, it no
longer suffices to have a 1 in N chance to provide a proof. Should a host be
completely free to choose between the two pointers (which is not entirely true,
as we shall see shortly) then the odds of a single pointer should be 1 in √N to
get to a probability of `1/√N * 1/√N = 1/N` of both pointers leading to a proof
requirement.

In reality, a host will not be able to always choose either of the two pointers.
When one of the pointers is about to wrap before validation is due, it can no
longer be relied upon. A really conservative host would follow the strategy of
always choosing the pointer that points to the most recent block, requiring the
odds to be 1 in N. A host that tries to optimize towards providing as little
proofs as necessary will require the odds to be nearer to 1 in √N.

Future work can determine optimal strategies for hosts to follow for each of the
networks (L1 or L2) that this design is deployed to, and the accompanying odds
that are required. For now, we leave the odds of the die roll to be negotiable
per storage contract so that the market can adapt to changing host strategies on
the network.

[1]: https://docs.soliditylang.org/en/v0.8.12/units-and-global-variables.html#block-and-transaction-properties
[2]: https://community.optimism.io/docs/developers/build/differences/#block-numbers-and-timestamps
[3]: https://support.avax.network/en/articles/5106526-measuring-time-in-smart-contracts
