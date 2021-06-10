State Channels
==============

State channels are a level 2 solution to enable fast and cheap transactions
between parties, whose trust is anchored on a blockchain.

We'll go through the evolution of state channels in somewhat chronological
order. Starting with the most simple form: uni-directional payment channels.

Uni-directional payment channels
--------------------------------

Payments are one-to-one, and flow in one direction only. They are easy to
understand and are the base upon which further enhancements are built.

Flow:

  1. Alice locks up an amount of coins (e.g. 1 Eth) in a smart contract
     on-chain. This opens up the payment channel. She's not able to touch the
     coins for a fixed amount of time. Bob is the only one able to withdraw at
     any time.
  2. She then sends Bob payments off-chain, which basically amount to signed
     "Alice owes Bob x Eth" statements. The amount owed is strictly increasing.
     For instance, if Alice first pays Bob 0.2 Eth, and then 0.3 Eth, then Bob
     first receives a statement "Alice owes Bob 0.2 Eth", and then "Alice owes
     Bob 0.5 Eth".
  3. Bob sends the latest statement from Alice to the smart contract, which pays
     Bob the total amount due. This closes the payment channel.


                      ------------
                      | Contract | <------ 1 ----  Alice
                      |          |
                      |          |                 | | |
                      |          |                 | | |
                      |          |                 2 2 2
                      |          |                 | | |
                      |          |                 | | |
                      |          |                 v v v
                      |          |
                      |          | <------ 3 ----   Bob
                      ------------


Bi-directional payment channels
-------------------------------

Payments are one-to-one, and are allowed to flow in both directions.

Flow:

  1. Both Alice and Bob lock up an mount of coins to open the payment channel.
  2. Alice and Bob send each other payments off-chain, whereby they sign the
     total amount owed for both parties. For instance, when Bob sends 0.3 Eth
     after Alice sent 0.2 Eth, he will sign the statement:
     "A->B: 0.2, B->A: 0.3". These statements have a strictly increasing
     version number.
  3. At any time, Alice or Bob can use the latest signed statement and ask
     the smart contract to pay out the amounts due. This closes the payment
     channel. To ensure that Alice and Bob do not submit an old statement,
     there is a period in which the other party can provide a newer statement.

Because of the contention period these channels take longer to close in case of
a dispute. Also, both parties need to remain online and keep up with the latest
state of the blockchain.

                      ------------
                      | Contract | <------ 1 ----  Alice ----
                      |          |                          |
                      |          |                 | ^ ^    |
                      |          |                 | | |    |
                      |          |                 2 2 2    |
                      |          |                 | | |    |
                      |          |                 | | |    |
                      |          |                 v | |    |
                      |          |                          |
                      |          | <------ 3 ----   Bob     |
                      |          |                          |
                      |          | <------ 3 ----------------
                      ------------

Payment channel networks
------------------------

Opening up a payment channel for every person that you interact with is
impractical because they need to be opened and closed on-chain.

Payment channel networks solve this problem by routing payments through
intermediaries. If Alice wishes to pay David, she might route the payment
through Bob and Carol. Hash-locks are used to ensure that a routed payment
either succeeds or is rejected entirely. Intermediaries typically charge a fee
for their efforts.

Routing algorithms for payment channel networks are an active area of research.
Each routing algorithm has its own drawbacks.


                      Alice --> Bob --> Carol --> David


State channels
--------------

Payment channels can be generalized to not just handle payments, but also state
changes, to enable off-chain smart contracts. Instead of signing off on amounts
owed, parties sign off on transactions to a smart contract. Upon closing of a
state channel, only a single transaction is executed on the on-chain contract.
In case of a dispute, a contention period is used to determine which transaction
is the latest. This means that just like bi-directional payment channels there
is a need to remain online.

Virtual channels
----------------

When routing payments over a payment channel network, all participants in the
route are required to remain online and confirm all payments. Virtual channels
alleviate this by involving intermediary nodes only for opening and closing
a channel. They are built around the idea that state channels can host a smart
contract for opening and closing a virtual channel.

Existing solutions
------------------

| Name              | Bi-directional | State | Routing | Virtual |
|-------------------|----------------|-------|---------|---------|
| raiden.network    | ✓              | ✕     | ✓       | ✕       |
| perun.network     | ✓              | ✓     | ✓       | ✓       |
| statechannels.org | ✓              | ✓     | ✓       | ✓       |
| ethswarm.org      | ✓              | ✕     | ✓       | ✕       |

References
----------

  * [SoK: Off The Chain Transactions][1]: a comprehensive overview of level 2
    solutions
  * [Raiden 101][2]: explanation of payment channel networks
  * [Perun][3] and [Nitro][4]: explanation of virtual state channels

[1]: https://nms.kcl.ac.uk/patrick.mccorry/SoKoffchain.pdf
[2]: https://raiden.network/101.html
[3]: https://perun.network/pdf/Perun2.0.pdf
[4]: https://magmo.com/nitro-protocol.pdf
