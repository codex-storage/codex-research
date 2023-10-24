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
guarantees, it posts a storage Request on the blockchain. Hosts that want to
offer storage can fill a slot in the Request.


                                                             --------
                                          ---- fill slot --- | Host |
                                         |                   --------
                                         |
                                         v
                                 --------------
    ----------                   |            |                     --------
    | Client | --- request  ---> | Blockchain |  <--- fill slot --- | Host |
    ----------                   |            |                     --------
                                 --------------
                                         ^
                                         |
                                         |                   --------
                                          ---- fill slot --- | Host |
                                                             --------


The Request contains the content identifier, so that hosts can locate
and download the content. It also contains the reward that hosts receive for
storing the data and the collateral that hosts are expected to deposit. It
contains parameters pertaining to storage proofs and erasure coding. And
finally, it contains the amount of hosts that are expected to store the content,
including a small amount of host losses that can be tolerated.


    Request

      cid                             # content identifier

      reward                          # tokens payed per second per filled slot
      collateral                      # amount of collateral required per host and slot

      proof probability               # frequency at which proofs are required
      proof parameters                # proof of retrievability parameters
      erasure coding                  # erasure coding parameters
      dispersal                       # dispersal parameter
      repair reward                   # amount of tokens paid for repairs

      hosts                           # amount of storage hosts (including loss)
      loss                            # number of allowed host losses

      slots                           # assigned host slots

      expire                         # slots need to be filled before timeout

Slots
-----

Initially all host slots are empty. An empty slot can be filled by anyone by
submitting a correct storage proof together with collateral.


        proof &                                 proof &
      collateral   proof          missed      collateral               missed
            |        |              |               |                    |
            v        v              v               v                    v
            -------------------------------------------------------------------
     slot:  |///////////////////////|               |////////////////////|
            -------------------------------------------------------------------
                                    |                                    |
                                    v                                    v
                                collateral                           collateral
                                  lost                                 lost



            ---------------- time ---------------->


The time interval that a slot is filled by a host determines the host payout;
for every second of the interval a certain amount of tokens are awarded to the
host. Hosts that fill a slot are required to submit frequent proofs of storage.

When a certain number of proofs is missed, the slot is considered empty again.
The collateral associated with the slot is mostly burned. Some of it is used to
pay a fee to the node that indicated that proofs were missing, and some of it is
reserved for repairs. An empty slot can be filled again once another host
submits a correct proof together with collateral. Payouts for the time interval
that a slot is empty are burned.

Payouts for all hosts are accumulated in the smart contract and paid out at Request
end. This is to ensure that the incentive posed by the collateral is not
diminished over time.

Contract lifecycle
------------------

A Request starts when all slots are filled. Regular storage proofs will be
required from the hosts that filled the slots.

Some Requests may not attract the required amount of hosts, for instance
because the payment is insufficient or the storage demands on the network are
too high. To ensure that such Requests end, we add a timeout to the Request.
If the Request failed to attract sufficient hosts before the timeout is
reached, it is considered cancelled, and the hosts that filled any of the slots
are able to withdraw their collateral. They are also paid for the time interval
before the timeout. The client is able to withdraw the rest of the tokens in the
Request.

A Request ends when the money that was paid upfront runs out. The end time can
be calculated from the amount of tokens that are paid out per second. Note that
in our scheme this amount does not change during the lifetime of the Request,
 even when proofs are missed and repair happens. This is a desirable property
for hosts; they can be sure of a steady source of income, and a predetermined
Request length. When a Request ends, the hosts may withdraw their collateral.

When too many hosts fail to submit storage proofs, and no other hosts take over
the slots that they vacate, then the content can be considered lost. The
Request is considered failed. The collateral of every host in the Request is
burned as an additional incentive for the network hosts to avoid this scenario.
The client is able to retrieve any funds that are left in the Request.

        |
        | create
        |
        v
    -----------       timeout       -------------
    |   new   | ------------------> | cancelled |
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
    ------------
    | finished |
    ------------


Repairs
-------

When a slot is freed because of missing too many storage proofs, some
collateral from the host that previously filled the slot is used as an incentive
to repair the lost content. Repair typically involves downloading other parts of
the content and using erasure coding to restore the missing parts. To incentive
other nodes to do this repair, there is repair fee. It is a partial amount of the original
host's collateral. The size of the reward is a fraction of slot's collateral
where the fraction is parameter of the smart contract.

The size of the reward should be chosen carefully. It should not be too low, to
incentivize hosts in the network to prioritize repairs over filling new slots in
the network. It should also not be too high, to prevent malicious nodes in the
network to try to disable hosts in an attempt to collect the reward.

Renewal
-------

When a Request is about to end, and someone in the network wants the Request
to continue for longer, then they can post a new Request with the same content
identifier.

We've chosen not to allow top-ups of existing Requests with new funds. Even
though this has many advantages (it's a very simple way to extend the lifetime
of the Request, it allows people to easily chip in to host content, etc.) it
has one big disadvantage: hosts no longer know for how long they'll be kept to
the Request. When a Request is continuously topped up, they cannot leave the
Request without losing their collateral.

Dispersal
---------

Here we propose an an alternative way to select hosts for slots that is a
variant of the "first come, first serve" approach that we described earlier. It
intends to alleviate these problems:

  1. a single host can fill all slots in a Request
  2. a small group of powerful hosts is able to fill most slots in the network
  3. resources are wasted when many hosts try to fill the same slot

For a client it is beneficial when their content is stored on as many different
hosts as possible, to guard against host failures. Should a single host fill all
slots in the Request, then the failure of this single host could mean that the
content is lost.

On a network level, we also want to avoid that a few large players are able to
fill most Request slots, which would mean that the network becomes fairly
centralized.

When too many nodes compete for a slot in a Request, and only one is selected,
then this leads to wasted resources in the network. Wasted resources ultimately
lead to a higher cost of storage.

To alleviate these problems, we introduce a dispersal parameter in the Request.
The dispersal parameter allows a client to choose the amount of
spreading within the network. When a slot becomes empty then only a small amount
of hosts in the network are allowed to fill the slot. Over time, more and more
hosts will be allowed to fill a slot. Each slot starts with a different set of
allowed hosts.

The speed at which new hosts are included is chosen by the client. When the
client choses a high speed, then very quickly every host in the network will be
able to fill slots. This increases the chances of a single host to fill all
slots in a Request. When the client choses a low speed, then it is more likely
that different hosts fill the slots.

We use the Kademlia distance function to indicate which hosts are allowed to
fill a slot.

    distance between a and b:   xor(a, b)
    slot start point:           hash(nonce || slot number)
    allowed distance:           elapsed time * dispersal parameter


Each slot has a different start point:

      slot 4   slot 0             slot 2              slot 3        slot 1
        |        |                  |                   |             |
        v        v                  v                   v             v
    ----·--------·------------------·-------------------·-------------·----

A host is allowed to fill a slot when the distance between its id and the start
point is less that the allowed distance.

                                 start point
                                      |           Kademlia distance
                t=3    t=2    t=1     v
          <------(------(------(------·------)------)------)------>
                          ^                            ^
                          |                            |
                     this host is                 this host is
                    allowed at t=2               allowed at t=3

Note that even though we use the Kademlia distance function, this bears no
relation to the DHT. We use the blockchain address of the host, not its peer id.

This dispersal mechanism still requires modeling to check that it meets its
goals, and to find the optimal value for the dispersal parameter, given certain
network conditions. It is also worth looking into simpler alternatives.

Conclusion
----------

The design that we presented here deviates significantly from the previous
marketplace design.

There is no explicit negotiation phase for Requests. Clients are no
longer able to choose which hosts will be responsible for keeping the content on
the network. This removes the selection step that was required in the old
design. Instead, a host presents the network with an opportunity to earn money by
storing content. Hosts can decide whether they want to take part in the
Request, and if they do they are expected to keep to their part of the deal
lest they lose their collateral.

The first hosts that download the content and provide initial storage proofs are
awarded slots in the Request. This removes the explicit Request start (and its
associated timeout behavior) that was required in the old design. It also adds
an incentive to quickly start storing the content while slots are available in
the Request.

While the old design required separate negotiations per host, this design
ensures that either the single Request starts with all hosts, or is cancelled.
This is a significant reduction in the amount of interactions required.

The old design required new negotiations when a host is not able to fulfill its
obligations, and a separately designed repair protocol. In this design we
managed to include repair incentives and a repair protocol that is nearly
identical to Request start.

In the old design we had a single collateral per host that could be used to
cover many Requests. Here we decided to include collateral per Request. This
is done to simplify collateral handling, but it is not a requirement of the new
design. The new design can also be made to work with a single collateral per
host.
