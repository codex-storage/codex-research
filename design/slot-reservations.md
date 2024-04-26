# Preventing node and network overload during slot filling and slot repair

When a new storage request is created, slots in the request can be filled by the
first storage provider (SP) to downloaded the slot data, generate a storage
proof, then supply the proof and collateral to the onchain contract. This is
inherently a race and all SPs except the one who "won" will have wasted funds
downloading data that they ulimately did not need, which may lead eventually
lead to higher costs of storage. Additionally, clients will have to serve data
requests for all the racing SPs downloading data for all the slots in the
request. This not only could cause issues with nodes failing to handle the
request load, but also creates unneccessary congestion on the network.

## Proposed solution #1: Fill reward, Pay2Play, and sliding window rate of expansion

One proposed solution to this problem involves using [expanding window
mechanism](https://github.com/status-im/codex-research/blob/ad41558900ff8be91811aa5de355148d8d78404f/design/marketplace.md#dispersal)
as the sole means of throttling node request overload and network congestion.
The expanding window will have a randomised rate of expansion factor to prevent
waiting and collusion. Additionally, a fill reward incentivises fast fills and
disincentivises waiting. Pay2Play is a collateral that is put up by the client
to ensure they don't withhold data from the network.

### Fill reward

A fill reward will be issued to the SP that fills the slot. The reward will
offset the cost of the SPs collateral by a little bit. The fill reward must be
much less than the collateral.

This reward will decrease exponentially over time, so that it is inversely
proportional to the expanding window. This means that while the field of
eligible addresses is small, the fill reward will be high. Over time, the field
of eligible addresses will increase exponentially as the fill reward decreases
exponentially. This incentivises SPs to fill the slot as fast as possible, with
the lucky few SPs that closest to the source point of the expanding window
getting a bigger reward.

### Sliding window randomised rate of expansion factor

The sliding window mechanism starts off with a random source address, defined as
$hash(nonce || slot number)$ and a
distance, $d = 0$, defined as $xor(a, b)$. Over time, $d$ increases and $2^d$ addresses will be eligible
to participate. At time $t_0$, $d == 0$, so only 1 address (the source address)
is eligible. At time $t_1$, the distance increases to 1, and 2 addresses will be
included. At time $t_2$ and kademlia distance of 2, there are 4 addresses, etc,
until eventually the entire address space of SPs participating in the network
are eligible to fill a slot.

The client can set the rate of sliding window expansion by setting the
[dispersal
parameter](https://github.com/status-im/codex-research/blob/ad41558900ff8be91811aa5de355148d8d78404f/design/marketplace.md#dispersal), $dp$
when the storage request is created. Therefore the allowed
distance, $d_a$, for eligible SPs can be defined as:

$d_a = t_e * dp$,

where $t_e$ is the
elapsed time.

This presents an issue where if an SP could pre-calculate how long it would take
for themselves or other SPs to be eligible to fill a slot. This is relevant in a
case where an SP gets "lucky" and is close to the source of the expanding
window. They also know that other big data provider addresses are not close to
the source, meaning there is some before other providers will be eligible to
fill the slot. In that case, they could potentially wait an amount of time
before filling the slot, in the hopes that a better opportunity arises. The goal
should always be to fill slots as fast as possible, so any "waiting" behavior
should be discouraged.

A waiting SP is already disincentivsed by the exponentially decreasing fill
reward, however this may not be a large enough reward to create a change in
behavior. To fully dismantle this attack, the SP's pre-calculation can be
completely prevented by introduce a random factor into the rate calculation that
changes for each time/distance increase. The random factor, $r$, will be a factor
between 0.5 and 1.5, as an example. This means that the expanding window rate
set by the client in the storage request will be randomly increased (up to 150%)
or decreased (50%). The source of randomness for this could be the block hash,
so the value could change on each block. Therefore the allowed
distance for eligible SPs can then be defined as

$d_a = t_e * dp * r$

## Proposed solution #2: slot reservations aka "bloem method"

A proposed solution to this problem is to limit the number of SPs racing to
download the data to fill the slot, by allowing SPs to first reserve a slot
before any data needs to be downloaded. Reserving a slot requires some
collateral, so there is an initial race for SPs who can can deposit collateral
first to secure a reservation, then a second race amongst the SPs with a
reservation to fill the slot (with collateral and the generated proof). However,
not all SPs in the network can reserve a slot initially: the [expanding window
mechanism](https://github.com/status-im/codex-research/blob/ad41558900ff8be91811aa5de355148d8d78404f/design/marketplace.md#dispersal)
dictates which SPs are eligible to reserve the slot. As time progresses for an
unreserved slot (or a slot with less than $R$ reservations), more SPs will be
allowed to reserve the slot, until eventually any SP in the network can reserve
the slot. This ensures fair participation opportunity across SPs in the network.

### Reservation collateral and reward

Reservation collateral is paid to reserve a slot. This will decreases over time to
incentivise participation in aging slots.

Reservation reward is paid to the SP who reserves and eventually fills the slot. This
increases over time, to incentivise participation in aging slots.

[TODO: INSERT GRAPH OF RESERVATION COLLATERAL AND REWARD OVER TIME]

### Reservations expiry

Reservations can expiry after some time to prevent opportunity loss for other
SPs willing to participate.

### Reservation retries

After expire, an SP can retry a slot reservation, but if it was the last SP to
reserve the slot, it can only retry once. In other words, SPs can reserve the same slot
only twice in a row.

### Reservations per slot

Each slot is allowed to have three reservations, which effectively limits the
quantity of racing to three SPs.

### Expanding windows per slot

Each slot will have three reservations per slot, and each reservation will have
its own expanding window (these windows will have a unique starting point). The
purpose of this is to distribute the reservation potentials

### Attacks

Name          | Attack description
:-------------|:--------------------------------------------------------------------
Clever SP     | SP drops reservation when a better opportunity presents itself
Lazy SP       | SP reserves a slot, but doesn't fill it
Censoring SP  | acts like a lazy SP for specific CIDs that it tries to censor
Hooligan host | acts like a lazy SP for many request to damage to the network
Greedy SP     | SP tries to fill multiple slots in a request
Lazy client   | client doesn't release content on the network

#### Clever SP attack

In this attack, an SP could reserve a slot, then if a better opporunity comes
along, forfeit the reservation collateral by reserving and filling another slot,
with the idea that the reward earned in the new opportunity would make the
reservation collateral loss from the original slot worthwhile.

This attack is mitigated by allowing for multiple reservations per slot. All SPs
that have secured a reservation (capped at three) will race to fill the slot.
Thus, if one or more SPs that have reserved the slot decide to pursue other
opportunities, the other SPs that have reserved the slot will still be able to
fill the slot.

In addition, the expanding window mechanism allows for more slots
to participate (reserve/fill) as time progresses, so there will be a larger pool
of SPs that could potentially fill the slot.

The increasing reservation reward over time also incentivises late comers to
reserve slots, so if there are initially SPs that reserve slots but fail to fill
the slot due to better opprotunities elsewhere, other SPs will be incentivised
to participate.

After some time, the slot reservation of the attcking SP will expire, and other
SPs wills will be allowed to reserve and fill the slot. As time will have passed
in this scenario, increased reservation rewards and decreased collateral
requiremnts will incentivise other SPs to participate.

#### Lazy SP attack

The "lazy SP attack" is when an SP reserves a slot, but does not fill it. The
vector is very similar to the "clever SP attack". The slot reservations
mechanism mititgates this attack in the same ways, please see the "Clever SP
attack" section above.

#### Censoring SP attack

A "censoring SP attack" is performed by an SP that wants to disrupt storage of
particular CIDs by reserving a slot and then not filling it.

Mitigation of this attack is exactly the same as the "lazy SP attack".

#### Hooligan SP attack

In this attack, an SP would attempt to disrupt the network by reserving and
failing to fill random slots in the network

#### Greedy SP attack

A "greedy SP attack" is when one SP tries to fill more than M slots (and up to K
slots) of a request in an attempt to control whether or not the contract
fails. In the case of M slots controlled, the attacker could cause the contract
to fail and the client would get only funds not already spent on proof provision
back. All SPs in the contract would forfeit their collateral in this case,
however, so this attack does have a significant cost associated.

In the case of K slots, the SPs could withhold data from the network, and if no
other SPs or caching nodes hold this data, could prevent retrieval and repair of
the data.

This particular attack is difficult to mitigate because there is a sybil
component to it where an entity could control many nodes in the network but all
those nodes could collude on the attack.

At this time, slot reservations does not mitigate against this attack, nor does
it incentivise behaviour that would prevent it.

#### Lazy client attack

This attack happens when a client creates a request for storage, but ultimately
does not release the data to the network when it requested. SPs may reserve the slot,
with collateral, and yet would never be able to fill the slot as they cannot
download the data. The result of this attack is that any SPs who reserve the
slot may lose their collateral.

At this time, slot reservations does not mitigate against this attack, nor does
it incentivise behaviour that would prevent it.

### Open questions

#### Reservation collateral goes to 0 at time of contract expiry?

#### Fill race to start at the same time?

When SPs reserve a slot, the first three SPs can race to fill the slot. However,
if there is no point in time at which all three SPs can start the race, then it
would allow any SP that secures a reservation to immediately start downloading
and filling the slot.

Perso note: no, want to fill slots as fast as possible.

### Trade offs

The main advantage to this design is that nodes and the network would not be overloaded at
the outset of slots being availble for SP participation.

The downside of this proposal is that an SP would have to participate in two
races: one for reserving the slot and another for filling the slot once
reserved, which brings additional complexities in the smart contract.
Additionally, there are additional complexities introduced with the reservation
collateral and reward "dutch aucitons" that change over time. It remain unclear
if the additional complexity in the smart contracts for benefits that may not be
substationally greater than having the sliding mechanism window on its own.

In addition, there are two attack vectors, the "greedy SP attack" and the "lazy
client attack" that are not well covered in the slot reservation design. There
could be even more complexities added to the design to accomodate these two
attacks (see the other proposed solution for the mitigation of these attacks).

// TODO: add slot start point source of randomness (block hash) into
slot start point in the disperal/sliding window design

// THOUGHTS: Perhaps the expanding window mechanism should be network-aware such
that there are always a minimum of 2 SPs in a window at a given time, to
encourage competition. If not, an SP could watch the network, and given a new
opportunity to fill a slot, understand that it could wait some time before
reserving the slot knowning that it is the only SP in the allowed address space
in the expanding window for some time.

The slot reservation mechanism should be able to mitigate client and SP attacks
on the network.




Allowing slots to be claimed by a storage provider (SP) offering both collateral and proof of
storage creates a race condition where the fastest SP to provide these "wins"
the slot. . In other words, a host would need to download the data before it's
allowed to fill a slot.

This can be problematic. Because hosts are racing to fill a slot, by all downloading the data, they could overwhelm the capacity of the client that is offering the data to the network. Bandwidth incentives and [dispersal](https://github.com/status-im/codex-research/blob/ad41558900ff8be91811aa5de355148d8d78404f/design/marketplace.md#dispersal) could alleviate this, but this is far from certain.

This is why it's useful to investigate an alternative: allow a host to claim a slot before it starts downloading the data. A host can claim a slot by providing collateral. This changes the dynamics quite a bit; hosts are now racing to put down collateral, and it's not immediately clear what should happen when a contract fails. The incentives need to be carefully changed to avoid unwanted behavior.