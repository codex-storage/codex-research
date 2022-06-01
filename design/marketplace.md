A marketplace for storage durability
====================================

We present a new design for a storage marketplace, that is both simpler and
includes incentives for repair.

Context
-------

Our current storage marketplace is designed around the notion of sending out
requests for storage, waiting for hosts to offer storage, and then choosing a
selection from these hosts to start a storage contract with. It requires
separate contracts for each of these hosts, active participation of the client
during the negotiation phase, and does not yet have any provisions for repairing
storage when hosts fail to deliver on their contracts.

In this document we describe a new design that is simpler, requires less
interactions, and has repair incentives built in.

A new design
------------

We propose to create new type of storage contract, containing a number of slots.
Each of these slots represents an agreement with a storage host to store a part
of the content. When a client wants store data on the network with durability
guarantees, it posts a storage contract on the blockchain. Hosts that want to
offer storage can fill a slot in the contract.


                                                             --------
                                          ---- fill slot --- | Host |
                                         |                   --------
                                         |
                                         v
                                 --------------
    ----------                   |            |                     --------
    | Client | --- contract ---> | Blockchain |  <--- fill slot --- | Host |
    ----------                   |            |                     --------
                                 --------------
                                         ^
                                         |
                                         |                   --------
                                          ---- fill slot --- | Host |
                                                             --------


The storage contract contains the content identifier, so that hosts can locate
and download the content. It also contains the reward that hosts receive for
storing the data and the collateral that hosts are expected to deposit. It
contains parameters pertaining to storage proofs and erasure coding. And
finally, it contains the amount of hosts that are expected to store the content,
including a small amount of host losses that can be tolerated.


    StorageContract

      cid                             # content identifier

      reward                          # tokens payed per second per filled slot
      collateral                      # amount of collateral required per host

      proof probability               # frequency at which proofs are required
      proof parameters                # proof of retrievability parameters
      erasure coding                  # erasure coding parameters

      hosts                           # amount of storage hosts (including loss)
      loss                            # number of allowed host losses

      slots                           # assigned host slots

      timeout                         # slots need to be filled before timeout

Slots
-----

Initially all host slots are empty. An empty slot can be filled by anyone by
submitting a correct storage proof together with collateral.


        collateral                              collateral
          proof    proof          missed          proof                missed
            |        |              |               |                    |
            v        v              v               v                    v
            -------------------------------------------------------------------
     slot:  |///////////////////////|               |////////////////////|
            -------------------------------------------------------------------
                                    |                                    |
                                    v                                    v
                                collateral                           collateral
                                  burned                               burned



            ---------------- time ---------------->


The time interval that a slot is filled by a host determines the host payout;
for every second of the interval a certain amount of tokens are awarded to the
host. Hosts that fill a slot are required to submit frequent proofs of storage.

When a proof is missed, the collateral associated with a slot is used to pay a
fee to the one who marked the proof as missing. The rest of the slot collateral
is reserved for repairs. The slot is now considered empty again until another
host submits a correct proof together with collateral. Payouts for the time
interval that a slot is empty are burned.

Contract lifecycle
------------------

A contract starts when all slots are filled. Regular storage proofs will be
required from the hosts that filled the slots.

Some contracts may not attract the required amount of hosts, for instance
because the payment is insufficient or the storage demands on the network are
too high. To ensure that such contracts end, we add a timeout to the contract.
If the contract failed to attract sufficient hosts before the timeout is
reached, it is considered cancelled, and the hosts that filled any of the slots
are able to withdraw their collateral. They are also paid for the time interval
before the timeout. The client is able to withdraw the rest of the tokens in the
contract.

A contract ends when the money that was paid upfront runs out. The end time can
be calculated from the amount of tokens that are paid out per second. Note that
in our scheme this amount does not change during the lifetime of the contract,
 even when proofs are missed and repair happens. This is a desirable property
for hosts; they can be sure of a steady source of income, and a predetermined
contract length. When a contract ends, the hosts may withdraw their collateral.

When too many hosts fail to submit storage proofs, and no other hosts take over
the slots that they vacate, then the content can be considered lost. The
contract is considered failed. The collateral of every host in the contract is
burned as an additional incentive for the network hosts to avoid this scenario.
The client is able to retrieve any funds that are left in the contract.

        |
        | create
        |
        v
    -----------       timeout       -------------
    | created | ------------------> | cancelled |
    -----------                     -------------
        |
        | all slots filled
        |
        v
    -----------   too many losses    ----------
    | started | -------------------> | failed |
    -----------                      ----------
        |
        | money runs out
        |
        v
    ---------
    | ended |
    ---------


Repairs
-------

When a slot becomes empty, the remaining collateral associated with the slot is
used as an incentive to repair the lost content. Repair typically involves
downloading other parts of the content and using erasure coding to restore the
missing parts. This incurs costs for a host. To compensate the host for these
costs it receives not only its own collateral back at the end of the contract,
but also the remaining collateral from the host that failed to hold a slot.

We expect the collateral to be significantly higher than the costs of repair.
This means that hosts in the network can benefit greatly from repairs, and they
may prioritize repairs over filling slots in new contracts. This is intentional,
we want the network to prioritize honoring existing contracts over starting new
ones.

Renewal
-------

When a contract is about to end, and someone in the network wants the contract
to continue for longer, then they can post a new contract with the same content
identifier.

We've chosen not to allow top-ups of existing contracts with new funds. Even
though this has many advantages (it's a very simple way to extend the lifetime
of the contract, it allows people to easily chip in to host content, etc.) it
has one big disadvantage: hosts no longer know for how long they'll be kept to
the contract. When a contract is continuously topped up, they cannot leave the
contract without losing their collateral.

Conclusion
----------

The design that we presented here deviates significantly from the previous
marketplace design.

There is no explicit negotiation phase for storage contracts. Clients are no
longer able to choose which hosts will be responsible for keeping the content on
the network. This removes the selection step that was required in the old
design. Instead a host presents the network with an opportunity to earn money by
storing content.  Hosts can decide whether or not they want to take part in the
contract, and if they do they are expected to keep to their part of the deal
lest they lose their collateral.

The first hosts that download the content and provide initial storage proofs are
awarded slots in the contract. This removes the explicit contract start (and its
associated timeout behavior) that was required in the old design. It also adds
an incentive to quickly start storing the content while slots are available in
the contract.

Instead of receiving a payout at the end of a contract in the old design, now
hosts earn money while the contract is running. This could be used to pay for
running costs on longer contracts.

While the old design required separate negotiations per host, this design
ensures that either the single contract starts with all hosts, or is cancelled.
This is a significant reduction in the amount of interactions required.

The old design required new negotiations when a host is not able to fulfill its
obligations, and a separately designed repair protocol. In this design we
managed to include repair incentives and a repair protocol that is nearly
identical to contract start.

In the old design we had a single collateral per host that could be used to
cover many contracts. Here we decided to include collateral per contract. This
is done to simplify collateral handling, but it is not a requirement of the new
design. The new design can also be made to work with a single collateral per
host.
