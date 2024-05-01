# Preventing node and network overload during slot filling and slot repair

When a new storage request is created, slots in the request can be filled by the
first storage provider (SP) to download the slot data, generate a storage proof,
then supply the proof and collateral to the onchain contract. This is inherently
a race and all SPs except the one who "won" will have wasted funds downloading
data that they ultimately did not need, which may eventually lead to higher
costs of storage. Additionally, clients will have to serve data requests for all
the racing SPs downloading data for all the slots in the request. This not only
could cause issues with nodes failing to handle the request load, but also
creates unnecessary congestion on the network.

## Proposed solution #1: Fill reward, Pay2Play, and random sliding window rate of expansion

One proposed solution to this problem involves using the [expanding window
mechanism](https://github.com/status-im/codex-research/blob/ad41558900ff8be91811aa5de355148d8d78404f/design/marketplace.md#dispersal)
as the sole means of throttling node request overload and network congestion.
The expanding window will have a randomized rate of expansion factor to prevent
waiting and collusion. Additionally, a fill reward incentivizes fast fills and
disincentivizes waiting. Pay2Play is a collateral that is put up by the client
to disincentivize bad behavior: withholding data and spamming the network.

### Fill reward

A fill reward will be issued to the SP that fills the slot. The reward will
offset the cost of the SPs collateral by a little bit. The fill reward must be
much less than the collateral.

This reward will decrease exponentially over time, so that it is inversely
proportional to the expanding window. This means that while the field of
eligible addresses is small, the fill reward will be high. Over time, the field
of eligible addresses will increase exponentially as the fill reward decreases
exponentially. This incentivizes SPs to fill the slot as fast as possible, with
the lucky few SPs that closest to the source point of the expanding window
getting a bigger reward.

The fill reward curve would be a configuration parameter in the smart contract,
making it a network-level value, that affects all storage requests.

There is one caveat: the smallest collateral that a client can require must be
greater than the maximum fill reward. If this was not the case, an SP that is
actively filling a slot, that sees a more profitable opportunity with a high
fill reward (ie SPs address was close to the source of the expanding window),
would be incentivized to abandon their existing duties and fill the slot in the
new request. If the collateral for a request is always greater than the largest
fill reward, then the fill reward will never be an incentive for an SP
to abandon their existing duties.

// TODO: the maximum fill reward should be less than the smallest allowed
collateral by some factor. This factor could be a configuration parameter in the
smart contract. It should also be modeled to understand optimal values.

### Expanding window mechanism

The expanding window mechanism prevents node and network overload once a slot
becomes available to be filled (or repaired) by allowing only a very small
number of SP addresses to fill/repair the slot at the start. Over time, the number
of eligible SP addresses increases, until eventually all SP addresses in the
network are eligible.

The expanding window mechanism starts off with a random source address, defined
as $hash(nonce || slot number)$ and a distance, $d = 0$, defined as $xor(a, b)$.
Over time, $d$ increases and $2^d$ addresses will be eligible to participate. At
time $t_0$, $d == 0$, so only 1 address (the source address) is eligible. At
time $t_1$, the distance increases to 1, and 2 addresses will be included. At
time $t_2$ and kademlia distance of 2, there are 4 addresses, etc, until
eventually the entire address space of SPs participating in the network are
eligible to fill a slot.

Because the source address for the expanding window is generated using the
slot number, that means the source address for each slot will be different. This
has the added benefit of preventing a single node from filling all slots in
request.

The client can set the rate of sliding window expansion by setting the
[dispersal
parameter](https://github.com/status-im/codex-research/blob/ad41558900ff8be91811aa5de355148d8d78404f/design/marketplace.md#dispersal),
$p_d$ when the storage request is created. Therefore the allowed distance,
$d_a$, for eligible SP addresses can be defined as:

$d_a = t_e * p_d$, where $t_e$ is the elapsed time.

#### Randomizing the rate of expansion

This presents an issue where if an SP could pre-calculate how long it would take
for themselves or other SPs to be eligible to fill a slot. For example, if an SP
gets "lucky" and is close to the source of the expanding window, and they know
that other SP addresses are not close to the source, they would know there is
some time before other providers will be eligible to fill the slot. In that
case, they could potentially wait an amount of time before filling the slot, in
the hopes that a better opportunity arises. The goal should always be to fill
slots as fast as possible, so any "waiting" behavior should be discouraged. It
should be noted that while all SPs in the network should be reachable, their
addresses may not be known publicly until they fill a slot, when their address
is stored onchain against a storage request. Therefore, only SPs that have
filled a slot would be known to other SPs. It is also not possible to know what
the availabilities of the SP are, meaning that even if that SP is active on the
network and its address may fall into an expanding window, it may not be able to
service new requests. Of note, the DHT does not contain SP addresses, only SP
peer ids, so these values cannot be used in expanding window pre-calculations.
This means that SP pre-calculation is not an exact science: best guesses can be
made using the available information at the time.

A waiting SP is already disincentivized by the exponentially decreasing fill
reward, however this may not be a large enough reward to create a change in
behavior. To further mitigate this attack, the SP's pre-calculation can be
prevented by introducing a random factor into the rate calculation that changes
for each time/distance increase. The random factor, $r$, will be a factor
between 0.5 and 1.5, as an example (the range of $r$ should be configurable as a
network-wide configuration parameter). This means that the expanding window rate
set by the client in the storage request will be randomly decreased (by up to
50%) or increased (by up to 150%). The source of randomness for this could be
the block hash, which means the frequency in which $r$ changes would be
equivalent to the frequency in which new blocks are produced on chain.
Therefore, the allowed distance for eligible SPs can then be defined as:

$d_a = t_e * p_d * r$, where $r \in [0.5, 1.5]$

The range of $r$ should be a smart contract configuration parameter, making it a
network-level value, that affects all storage requests.

$r$ should be unique for each slot to prevent SPs from knowing when all slots of
a request will be open for it to attempt to fill all slots of a request.

#### Expanding window trade-offs

The main trade-off for the expanding window is that after a certain time, many
SP addresses will be eligible to fill a slot if it was not already filled. This
will allow a race between all eligible SP addresses, which can overload the
capacity of the client and cause network congestion. This can be further
exacerbated by a client choosing a large dispersal parameter in their request.

However, the decreasing fill reward should incentivize SPs to fill slots as soon
as possible. This may discourage too many addresses being allowed to fill a
slot, but it will not prevent it entirely. A situation could occur where SPs
close to the source of the sliding window do not have availability or the
request parameters are not within the bounds of SP availabilities, then
inevitably, the slot will open up to more addresses.

Additionally, the rate of sliding window expansion that is set by the client can
be bounded in such a way that expansion does not accelerate too quickly.

#### Expanding window time interval

The time interval duration, $t_i$, of the expanding window mechanism should be a
function of the request expiry and the maximum value of $d_a$. The maximum value
of $d_a$ should occur at the time interval just before expiry, so that only the
very last $t_i$ will have all addresses in the network available. This will
encourage data distribution. The number of eligible addresses at $2*t_i$ before
expiry will have half of the network addresses. Because $d_a$ is a hash, we can
assume 256 bits, and therefore the maximum value of $d$ (kademlia distance) is
`256`.

```
------.------.------.------.------.------> t_elapsed
                    ^      ^      ^
                    |   d_a=256   |
                    |  All addrs  |
                    |  eligible   |
                    |             |
                 d_a=255        expiry
                half addrs
                 eligible

```
$d_a = t_i*i + 1$

$t_e = t_i * i$

$t_i = d_max - 1 / expiry$, eg $t_i = 255/expiry$

The caveat here is that expiry must always be greater than or equal to 255.


## Pay2Play: client fee for cancelled contracts

Pay2Play is a fee that is burned if a contract does not start (all slots were
not filled before expiry). The source of the burned funds comes from the total
value put up by the client to pay for SPs to store their data. However, if the
contract is successfully completed, the fee is not burned and goes toward
payment of the SP/validator rewards. The sole purpose of the collateral is to
disincentivize bad behavior, namely, initially withholding data and spam
prevention. This fee is "pay to play" because the client is taking a risk that
their request will not complete successfully, however this fee is necessary for
mitigation of certain attacks.

When a client submits a request for storage, SPs that fill the slots download
the data from the client. The client could withhold this data to disrupt the
network and create opportunity loss for SPs that are attempting to download the
data. If this happens, then the slot would not be filled and the client would
lose its Pay2Play fee.

A client could also spam the network by submitting many requests for storage
that have conditions that would likely not be met by any SP's availability.
Ultimately, SPs would waste resources acting on these requests, however the
requests still need to be processed by the SP, which could, if numerous enough,
cause unknown issues overloading the SP with requests, and an additional
opportunity loss associated with processing a high volume of untenable requests.
While the transaction cost alone could be a deterrent for this type of behavior,
once deployed on an L2, spamming the network in this way would be achievable.
The Pay2Play fee adds to the expense of such spam and would further
disincentivize this behavior.

### Pay2Play fee as a value

The Pay2Play fee should not be a percentage of total request reward, because in
a situation where a client has created a very cheap request, a percentage of the
total reward (which is small) would be very small. This would make the fee much
less of an incentive for good behavior. Instead, the fee should be a
configuration parameter set at the network level, as a value, not a percentage.

There is a caveat to the Pay2Play fee as a value, however: because the source of
the funds is the total value of the storage request, the total price of a
storage contract cannot exceed the fee value. This could potentially limit how
short in duration requests can be, depending on the value of the fee that is
set. There is an alternative solution that avoids this caveat: client
collateral.

### Pay2Play alternative solution: client collateral

Instead of burning a fee from funds already provided by the client, an
*additional* collateral could be provided. This collateral is deposited by the
client when creating a request for storage, and is returned once the request has
started (all slots have been filled).

This avoids the caveat of forcing minimum request value to be within bounds of a
fee, as the collateral will not be taken from the total request value.

The trade-off however, is that there is an increased barrier to entry due to the
requirement of clients to provide an additional collateral.

### Pay2Play trade-off

However, there is one downside to the Pay2Play fee/collateral. If a client is
behaving correctly, but submits a request for storage that is out of the range
of acceptable market conditions, then the request will not be started, and the
client will lose their collateral.

### Solution #1 attacks

Name               | Attack description
:------------------|:-----------------------------------------------------------------
Clever SP          | SP drops a filled slot when a better opportunity presents itself
Lazy SP            | SP waits to fill a slot to see if better opportunities will arise
Censoring SP       | SP withholds specific CIDs that it tries to censor
Greedy SP          | SP tries to fill multiple slots in a request
Sticky SP          | SP withholds data from other SPs to win re-posted contract
Withholding client | client withholds data after creating a request
Controlling client | like a censoring client, but for specific SPs on the network
Spammy client      | client spams the network with untenable storage requests

#### Clever SP attack

The "clever SP attack" is when an SP has already filled a slot, but finds a more
profitable opportunity in a different request, so the existing slot is abandoned
in order to clear up storage space for the more profitable slot. This attack is
mitigated by several factors. Firstly, payouts for SP duties performed (proofs)
only happen upon contract completion, meaning if an SP abandoned a slot, they'd
be giving up payment for duties already performed and resources already spent.
Secondly, the collateral provided for the slot fill would also be burnt.
Thirdly, the fill reward for the new slot fill must be much less than the
minimum collateral required for the new slot, so even if the SP's address is
close to the source of the expanding window, the fill reward will not be greater
than the collateral being given up. All of these factors together would make it
very difficult to pull off an attack without losing money.

#### Lazy SP attack

In this attack, an SP's address is eligible to fill a slot, but the SP waits to
fill the slot hoping to come across a more profitable opportunity. This attack
is partially mitigated by the additional fill reward provided to fill the slot
early (if their address is close to the source). In addition, SP will not be
able to pre-calculate when other SPs in the network will become eligible due to
the randomized rate of expansion in the expanding window mechanism. This means
that as soon as the window expands, other SPs will be eligible to fill the slot
first.

#### Censoring SP attack

The "censoring SP attack" is when an SP attempts to withhold providing specific
CIDs from the network in an attempt to censor certain content. In this case, the
dataset can be reconstructed from K chunks (provided by other SPs) allowing the
censored CID to be accessed. An SP could also prevent slots from being filled
(eg in the case of repair) while waiting for the expanding window to open up its
address. In this case, the SP would need to control `M + 1` chunks to prevent data
reconstruction by other nodes in the network. The fill reward and expanding
window mechanism seek to prevent SPs from filling multiple slots in the same
request.

#### Greedy SP attack

The "greedy SP attack" mitigation is the same as the censoring SP attack where
`M + 1` chunks would need to be filled before this becomes an issue, which is
already mitigated by the expanding windows and fill reward. However, this is
only discouraged by not impossible if a controlling entity sets up a sybil
attack with many highly distributed nodes.

#### Sticky SP attack

The "sticky SP attack" is created once a new storage request for the same CID
already being stored by the SP is posted (this is how contract renewal works).
SP withholds data from all other SPs until the expanding window allows their
address, then they quickly fill the slot (they are quick because they don't need
to download the data). This should not be a problem, as the distribution of data
around the network for the previous request should be sufficient to be repeated.
And this is only for one slot. If all SPs in the request did the same, the
distribution for a successfully executed contract would still remain the same.
This should not occur for requests with new CIDs as SPs will not already have
the slot data downloaded.

#### Withholding client attack

In this attack, a client might want to disrupt the network by creating requests
for storage but never releasing the data to SPs attempting to fill the slot.
The Pay2Play fee/collateral mitigates this as it would become prohibitively
expensive.

#### Controlling client attack

The "controlling client attack" is when a client withholds data from specific
SPs after creating a storage request. This attack would cause some disruption
for the SP as it attempts to download the data for the slot, and creates
opportunity loss as it could be spending the time and resources filling other
slots. The client, however, cannot do this to too many SPs, or else the slots
will not get filled and they will lose their Pay2Play fee/collateral.

#### Spammy client attack

In this attack, a client seeks to disrupt the network by creating many untenable
requests for storage. The Pay2Play fee/collateral mitigates this as it would
become prohibitively expensive on a large scale.

## Proposed solution #2: slot reservations aka the "bloem method"

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

Reservation collateral is paid to reserve a slot. This will decreases over time
to incentivize participation in aging slots.

Reservation reward is paid to the SP who reserves and eventually fills the slot.
This increases over time, to incentivize participation in aging slots.

[TODO: INSERT GRAPH OF RESERVATION COLLATERAL AND REWARD OVER TIME]

### Reservations expiry

Reservations can expiry after some time to prevent opportunity loss for other
SPs willing to participate.

### Reservation retries

After expiry, an SP can retry a slot reservation, but if it was the last SP to
reserve the slot, it can only retry once. In other words, SPs can reserve the
same slot only twice in a row.

### Reservations per slot

Each slot is allowed to have three reservations, which effectively limits the
quantity of racing to three SPs.

### Expanding windows per slot

Each slot will have three reservations per slot, and each reservation will have
its own expanding window (these windows will have a unique starting point). The
purpose of this is to distribute the reservation potentials

### Solution #2 attacks

Name         | Attack description
:------------|:--------------------------------------------------------------
Clever SP    | SP drops reservation when a better opportunity presents itself
Lazy SP      | SP reserves a slot, but doesn't fill it
Censoring SP | acts like a lazy SP for specific CIDs that it tries to censor
Hooligan SP  | acts like a lazy SP for many request to damage to the network
Greedy SP    | SP tries to fill multiple slots in a request
Lazy client  | client doesn't release content on the network

#### Clever SP attack

In this attack, an SP could reserve a slot, then if a better opportunity comes
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

The increasing reservation reward over time also incentivizes late comers to
reserve slots, so if there are initially SPs that reserve slots but fail to fill
the slot due to better opportunities elsewhere, other SPs will be incentivized
to participate.

After some time, the slot reservation of the attacking SP will expire, and other
SPs wills will be allowed to reserve and fill the slot. As time will have passed
in this scenario, increased reservation rewards and decreased collateral
requirements will incentivize other SPs to participate.

#### Lazy SP attack

The "lazy SP attack" is when an SP reserves a slot, but does not fill it. The
vector is very similar to the "clever SP attack". The slot reservations
mechanism mitigates this attack in the same ways, please see the "Clever SP
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
it incentivize behavior that would prevent it.

#### Lazy client attack

This attack happens when a client creates a request for storage, but ultimately
does not release the data to the network when it requested. SPs may reserve the slot,
with collateral, and yet would never be able to fill the slot as they cannot
download the data. The result of this attack is that any SPs who reserve the
slot may lose their collateral.

At this time, slot reservations does not mitigate against this attack, nor does
it incentivize behavior that would prevent it.

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
the outset of slots being available for SP participation.

The downside of this proposal is that an SP would have to participate in two
races: one for reserving the slot and another for filling the slot once
reserved, which brings additional complexities in the smart contract.
Additionally, there are additional complexities introduced with the reservation
collateral and reward "dutch auctions" that change over time. It remain unclear
if the additional complexity in the smart contracts for benefits that may not be
substantially greater than having the sliding mechanism window on its own.

In addition, there are two attack vectors, the "greedy SP attack" and the "lazy
client attack" that are not well covered in the slot reservation design. There
could be even more complexities added to the design to accommodate these two
attacks (see the other proposed solution for the mitigation of these attacks).

// TODO: add slot start point source of randomness (block hash) into
slot start point in the dispersal/sliding window design

// THOUGHTS: Perhaps the expanding window mechanism should be network-aware such
that there are always a minimum of 2 SPs in a window at a given time, to
encourage competition. If not, an SP could watch the network, and given a new
opportunity to fill a slot, understand that it could wait some time before
reserving the slot knowing that it is the only SP in the allowed address space
in the expanding window for some time.

The slot reservation mechanism should be able to mitigate client and SP attacks
on the network.

Allowing slots to be claimed by a storage provider (SP) offering both collateral and proof of
storage creates a race condition where the fastest SP to provide these "wins"
the slot. . In other words, a host would need to download the data before it's
allowed to fill a slot.

This can be problematic. Because hosts are racing to fill a slot, by all downloading the data, they could overwhelm the capacity of the client that is offering the data to the network. Bandwidth incentives and [dispersal](https://github.com/status-im/codex-research/blob/ad41558900ff8be91811aa5de355148d8d78404f/design/marketplace.md#dispersal) could alleviate this, but this is far from certain.

This is why it's useful to investigate an alternative: allow a host to claim a slot before it starts downloading the data. A host can claim a slot by providing collateral. This changes the dynamics quite a bit; hosts are now racing to put down collateral, and it's not immediately clear what should happen when a contract fails. The incentives need to be carefully changed to avoid unwanted behavior.
