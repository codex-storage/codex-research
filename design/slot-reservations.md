# Slot reservations

Competition between storage providers (SPs) to fill slots has some advantages,
such as providing an incentive for SPs to become proficient in downloading
content and generating proofs. It also has some drawbacks, for instance it can
lead to network inefficiencies because multiple SPs do the work of downloading
and proving, while only one SP is rewarded for it. These inefficiencies lead to
higher costs for SPs, which leads to an overall increase in the price of storage
on the network. It can also lead to clients inadvertently inviting too much
network traffic to themselves. Should they for instance post a very lucrative
storage request, then this invites a lot of SPs to start downloading the content
from the client simultaneously, not unlike a DDOS attack.

Slot reservations are a means to avoid these inefficiencies by only allowing SPs
who have secured a slot reservation to fill the slot. Furthermore, slots can
only be reserved by eligible SPs, governed by a window of eligible addresses
that starts small and grows larger over time, eventually encompassing the entire
address space on the network.

## Proposed solution: slot reservations

Before downloading the content associated with a slot, a limited number of SPs
can reserve the slot. Only SPs that have reserved the slot can fill the slot.
After the SP downloads the content and calculates a proof, it can move the slot
from its reserved state into the filled state by providing collateral and the
storage proof. Then it begins to periodically provide storage proofs and accrue
payments for the slot.

```
         reserve         proof & collateral
            |                  |
            v                  v
            ---------------------------------------------
     slot:  |/ / / / / / / / / |/////////////////////////
            ---------------------------------------------
            |                  |
            v                  v
          slot                slot
         reserved            filled


            ---------------- time ---------------->
```

There is an initial race for eligible SPs who are first to secure a reservation,
then a second race amongst the SPs with a reservation to fill the slot (with
collateral and the generated proof). However, not all SPs in the network can
reserve a slot initially: the [expanding window
mechanism](https://github.com/status-im/codex-research/blob/ad41558900ff8be91811aa5de355148d8d78404f/design/marketplace.md#dispersal)
dictates which SPs are eligible to reserve the slot.

### Expanding window mechanism

The expanding window mechanism prevents node and network overload once a slot
becomes available to be filled (or repaired) by allowing only a very small
number of SP addresses to fill/repair the slot at the start. Over time, the
number of eligible SP addresses increases, until eventually all SP addresses in
the network are eligible.

The expanding window mechanism starts off with a random source address, defined
as $hash(block hash, request id, slot index, reservationindex)$, with a unique
source address for each reservation of each slot. The distance between each SP
address and the source address can be defined as $XOR(A, A_0)$ (kademlia
distance). Once the allowed distance is greater than SP's distance, the SP is
considered eligible to reserve a slot. The allowed distance for eligible
addresses over time $t_i$ can be [defined
as](https://hackmd.io/@bkomuves/BkDXRJ-fC) $2^{256} * F(t_i)$, where $2^{256}$
represents the total number of 256-bit addresses in the address space, and
$F(t_i)$ represents the expansion function over time. As this allowed distance
value increases along a curve, more and more addresses will be eligible to
participate in reserving that slot. In total, eligible addresses are those that
satisfy:

$XOR(A, A_0) < 2^{256} * F(t_i)$

Furthermore, the client can change the curve of the rate of expansion, by
setting a [dispersal
parameter](https://github.com/codex-storage/codex-research/blob/ad41558900ff8be91811aa5de355148d8d78404f/design/marketplace.md#dispersal)
of the storage request, $h$, which represents the percentage of the network
addresses that will be eligible halfway to the time of expiry. $h$ can be
defined as:

$h := F(0.5)$, where $0 \lt h \lt 1$ and $h \neq 0.5$

Changing the value of $h$ will [affect the curve of the rate of
expansion](https://www.desmos.com/calculator/pjas1m1472) (interactive graph).

#### Expansion function, $F(t_i)$, in-depth

$F(t_i)$ defines the expansion factor of eligible addresses in the network over
time.

##### Assumptions

It is assumed network addresses are randomly, and more-or-less uniformly,
selected from a space of $2^{256}$.

It is also assumed that the window can only change in discrete steps, based on
some underlying blockchain's cadence (for example this would be approx every 12
seconds in the case of Ethereum), and that we measure time based on timestamps
encoded in blockchain blocks.

However, with this assumption given, it is desired to be as granular and tunable
as possibly.

There is a time duration in which it is desired to go from a single network
address to the whole address-space.

To be able to make this work nicely, first a linear time function $t_i$ which
goes from 0 to 1, is defined.

##### Implementation

At any desired block with timestamp $timestamp_i$, simply compute:

$$t_i := \frac{timestamp_i - start}{expiry - start}$$

Then to get a network range, any kind of expansion function $F(x)$ with $F(0)=0$
and $F(1)=1$ can be plugged in; for example, a parametric exponential:

 $$ F_s(x) = \frac{\exp(sx) - 1}{\exp(s) - 1} $$

Remark: with this particular function, is is likely desired to have $s<0$
(resulting in fast expansion initially, slowing down later). Here is a
Mathematica one-liner to play with this idea:
```
    Manipulate[
      Plot[ (Exp[s*x]-1)/(Exp[s]-1), {x,0,1}, PlotRange->Full ],
        {s,-10,-1} ]
```
As an alternative, the same can easily be done with eg. the online
[Desmos](https://www.desmos.com/calculator) tool.

##### Address window

Finally, an address $A$ becomes eligible at block $i$ if the Kademlia distance
from the "window center" $A_0$ is smaller than $2^{256}\times F(t_i)$:

 $$ XOR(A,A_0) < 2^{256}\cdot F(t_i) $$

Note: since $t_i$ only becomes 1 exactly at expiry, to allow the whole network
to participate near the end, there should be a small positive $\delta > 0$ such
that $F(t)=1$ for $t>1-\delta$, leaving the last about $100\delta$ percentage of
the total slot fill window when the whole network is eligible to participate.

Alternatively, $t_i$ could be rescaled to achieve the same effect:

$$ t_i' := \min(\; t_i/(1-\delta)\;,\;1\;) $$

The latter is probably simpler because it allows complete freedom in selecting
the expansion function $F(x)$.

##### Parametrizing the speed of expansion

While, in theory, arbitrary expansions functions could be used, it is likely
undesirable to have more than an one parameter family, that is, a single
parameter to set the curve. However, even with a single parameter, there
could be any number of different ways to map a number to the same family of
curves.

In the above example $F_s(t)$, while $s$ is quite natural from a mathematical
perspective, it doesn't really have any meaning for the user. A possibly better
parametrization would be the value $h:=F_s(0.5)$, meaning "how big percentage of
network is allowed to participate at half-time". $s$ can be computed from $h$:

$$ s = 2\log\left(\frac{1-h}{h}\right) $$

### Abandoned ideas

#### No reservation collateral

Reservation collateral was thought to be able to prevent a situation where an SP
would reserve a slot then fail to fill it. However, collateral could not be
burned as it created an attack vector for clients: clients could withhold the
data and cause SPs to lose their reservation collateral. The reservation
transaction itself creates a signal of intent from an SP to fill the slot. If
the SP were to not fill the slot, then other SPs that have reserved the slot
will fill it.

#### No reservation/fill reward

Fill rewards were originally proposed to incentivize filling slots as fast as
possible. However, the SPs are already being paid out for the time that they
have filled the slot, thus negating the need for additional incentivization. If
additional incentivization is desired by the client, then an increase in the
value of the storage request is possible.

Adding a fill reward for SPs who ultimately fill the slot is not necessary
because, like the SP rewards for providing proofs, fill rewards would be paid
once the storage request successfully completes. This would mean that the fill
reward is effectively the same as an increase in value of the storage request
payout. Therefore, if a client is so inclined to provide a fill reward, they
could instead increase the total reward of the storage request.

In this simplified slot reservations proposal, there will not be reservation
collateral nor reward requirements until the behavior in a live environment can
be observed to determine these are necessary mechanisms.

### Slot reservation attacks

Name         | Attack description
:------------|:--------------------------------------------------------------
Clever SP    | SP drops slot when a better opportunity presents itself
Lazy SP      | SP reserves a slot, but doesn't fill it
Censoring SP | acts like a lazy SP for specific CIDs that it tries to censor
Greedy SP    | SP tries to fill multiple slots in a request
Sticky SP    | SP tries to fill the same slot in a contract renewal
Lazy client  | client doesn't release content on the network

#### Clever SP attack

In this attack, an SP could fill a slot, and while fulfilling its duties, see
that a better opportunity has arisen, and abandon its duties in the first slot
to fill the second slot.

This attack is mitigated by the SP losing its request collateral for the first
slot once it is abandoned. Additionally, once the SP fills the first slot, it
will accrue rewards over time that will not be paid out until the request
successfully completes. These rewards act as another disincentive for the SP to
abandon the slot.

The behavior of SPs filling better opportunities is not necessarily an attack.
If an SP is fulfilling its duties on a slot and finds a better opportunity
elsewhere, it should be allowed to do so. The repair mechanisms will allow the
abandoned slot to be refilled by another SP that deems it profitable.

#### Lazy SP attack

In this attack, a SP reserves a slot, but waits to fill the slot hoping a better
opportunity will arise, in which the reward earned in the new opportunity would
be greater than the reward earned in the original slot.

This attack is mitigated by allowing for multiple reservations per slot. All SPs
that have secured a reservation (capped at three) will race to fill the slot.
Thus, if one or more SPs that have reserved the slot decide to pursue other
opportunities, the other SPs that have reserved the slot will still be able to
fill the slot.

In addition, the expanding window mechanism allows for more SPs to participate
(reserve/fill) as time progresses, so there will be a larger pool of SPs that
could potentially fill the slot. Because each reservation will have its own
unique expanding window source, SPs reserving one slot in a request will likely
not have the same opportunities to reserve/fill the same slot in another
request.

#### Censoring SP attack

The "censoring SP attack" is when an SP attempts to withhold providing specific
CIDs from the network in an attempt to censor certain content. An SP could also
try this attack in the case of repair, hoping to prevent a freed slot from being
repaired.

Even if one SP withholds specific content, the dataset, along with the withheld
CID can be reconstructed from K chunks (provided by other SPs) allowing the
censored CID to be accessed. In the case of repair, the SP would need to control
M+1 chunks to prevent data reconstruction by other nodes in the network. The
expanding window mechanism seeks to prevent SPs from filling multiple slots in
the same request, which should prevent any one SP from controlling M+1 slots.

#### Greedy SP attack

The "greedy SP attack" is when one SP tries to fill multiple slots in a single
request. Mitigation of this attack is achieved through the expanding windows for
each request not allowing a single SP address to fill all the slots. This is
only effective for the majority of time before expiry, however, meaning it is
not impossible for this attack to occur. If a request is offered and the slots
are not filled after some time, the expanding windows across the slots may open
up to allow all SPs in the network to fill multiple slots in the request.

A controlling entity may try to circumvent the expanding window by setting up a
sybil attack with many highly distributed nodes. Even with many nodes covering a
large distribution of the address space, the randomness of the expanding window
will make this attack highly improbable, except for undervalued requests that do
not have slots filled early, in which case there would be a lack of motivation
to attack data that is undervalued.

#### Sticky SP attack

The "sticky SP attack" is where an SP tries to withhold data for a contract
renewal so they are able to fill the slot again. The SP withholds data from all
other SPs until the expanding window allows their address, then they quickly
fill the slot (they are quick because they don't need to download the data). As
in the censoring SP attack, the SP would need to control M+1 slots for this to
be effective, because that is the only way to prevent the CID from being
reconstructed from K slots available from other SPs.

#### Lazy client attack

In this attack, a client might want to disrupt the network by creating requests
for storage but never releasing the data to SPs attempting to fill the slot. The
transaction cost associated with this type of behavior should provide some
mitigation. Additionally, if a client tries to spam the network with these types
of untenable storage requests, the transaction cost will increase with the
number of requests due to increasing block fill rate and rising gas costs
associated. However, this attack is not impossible.

### Open questions

Perhaps the expanding window mechanism should be network-aware such
that there are always a minimum of two SPs in a window at a given time, to
encourage competition? The downside of this is that active SPs need to be
persisted and tracked in the contract, with larger transaction costs resulting
from this.

### Trade offs

The main advantage to this design is that nodes and the network would not be
overloaded at the outset of slots being available for SP participation.

The downside of this proposal is that an SP would have to participate in two
races: one for reserving the slot and another for filling the slot once
reserved, which brings additional complexities in the smart contract.

In addition, there are two attack vectors, the "greedy SP attack" and the "lazy
client attack" that are not well covered in the slot reservation design. There
could be even more complexities added to the design to accommodate these two
attacks (see the other proposed solution for the mitigation of these attacks).
