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

## Proposed solution: Slot reservations aka the "bloem method"

Competition between hosts to fill slots has some advantages, such as providing
an incentive for hosts to become proficient in downloading content and
generating proofs. It also has some drawbacks, for instance it can lead to
network inefficiencies because multiple hosts do the work of downloading and
proving, while only one host is rewarded for it. These inefficiencies lead to
higher costs for hosts, which leads to an overall increase in the price of
storage on the network. It can also lead to clients inadvertently inviting too
much network traffic to themselves. Should they for instance post a very
lucrative storage request, then this invites a lot of hosts to start downloading
the content from the client simultaneously, not unlike a DDOS attack.

Slot reservations are a means to avoid these inefficiencies. Before downloading
the content associated with a slot, a limited number of hosts can reserve the
slot. Only hosts that have reserved the slot can fill the slot. After the host
downloads the content and calculates a proof, it can move the slot from its
reserved state into the filled state by providing collateral and the storage
proof. Then it begins to periodically provide storage proofs and accrue payments
for the slot.

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

Reserving a slot requires some collateral, so there is an initial race for SPs
who can can deposit collateral first to secure a reservation, then a second race
amongst the SPs with a reservation to fill the slot (with collateral and the
generated proof). However, not all SPs in the network can reserve a slot
initially: the [expanding window
mechanism](https://github.com/status-im/codex-research/blob/ad41558900ff8be91811aa5de355148d8d78404f/design/marketplace.md#dispersal)
dictates which SPs are eligible to reserve the slot. As time progresses for an
unreserved slot (or a slot with less than $R$ reservations), more SPs will be
allowed to reserve the slot, until eventually any SP in the network can reserve
the slot. This ensures fair participation opportunity across SPs in the network.
Additionally, the SP that fills the slot will be rewarded with a fill reward
that decreases linearly from the time the slot is available to fill to the
request expiry.

### Expanding window mechanism

The expanding window mechanism prevents node and network overload once a slot
becomes available to be filled (or repaired) by allowing only a very small
number of SP addresses to fill/repair the slot at the start. Over time, the
number of eligible SP addresses increases, until eventually all SP addresses in
the network are eligible.

The [expanding window
mechanism](https://github.com/status-im/codex-research/blob/ad41558900ff8be91811aa5de355148d8d78404f/design/marketplace.md)
starts off with a random source address, defined as $hash(block number, request
id, slot index)$ and a distance defined as $XOR(A, A_0)$. Over time, $t_i$, the
allowed distance [can be defined as $2^{256} *
F(t_i)$](https://hackmd.io/@bkomuves/BkDXRJ-fC). As this value gradually
increases, only addresses that have less of a distance than this value will be
eligible to participate. In total, eligible addresses are those that satisfy:

$XOR(A, A_0) < 2^{256} * F(t_i)$

Because the source address for the expanding window is generated using the slot
number, that means the source address for each slot will be different. Note that
the reservation index is not included, meaning that a single node could
potentially fill all slots in a request. The reason this was done was to
simplify the expanding window design. The reservation index could be added in if
necessary.

The client can set the rate of expansion by defining the [parameter
$h$](https://hackmd.io/@bkomuves/BkDXRJ-fC#Parametrizing-the-speed-of-expansion).
Changing the value of $h$ will [affect the curve of the rate of
expansion](https://www.desmos.com/calculator/pjas1m1472) (interactive graph).

### Fill reward

A fill reward will be issued to the SP that fills the slot. The client will deposit
an additional fee when creating a request for storage to cover the maximum fill
reward for all slots. Any difference in fill reward paid versus fill reward
deposited will be returned to the client after the request is completed
(including failed and cancelled requests).

This reward will decrease linearly over time, starting with the maximum value
at the time the slot is available to fill, and decreasing to zero at the request
expiry. This incentivizes SPs to fill the slot as fast as possible, with
the lucky few SPs that closest to the source point of the expanding window
getting a bigger reward.

The fill reward maximum value is specified by the client in the request for
storage.

#### Fill reward versus request collateral

There is one caveat to the fill reward: if the fill reward is larger than the
required collateral in an active request, an SP that is actively filling a slot
will see a more profitable opportunity with a high fill reward (assuming SP's
address was close to the source of the expanding window), and would be
incentivized to abandon their existing duties and fill the slot in the new
request.

There are two ways to approach this issue. The first approach is to set bounds
in the protocol restricting the minimum collateral of new storage requests to be
greater than the average fill reward in all active requests, increased by a
percentage (specified at the network-level). The average fill reward at time of
slot fill would need to be persisted in the contract to calculate what the next
available minimum collateral limit would be. New slot fills would append to the
average and completed contracts to detract from this persisted value. This
method was inspired by the way the base gas fee is calculated in
[EIP-1559](https://consensys.io/blog/what-is-eip-1559-how-will-it-change-ethereum).
If the fill reward is continually getting

The second approach does not set any protocol bounds, allowing any request
collateral and fill reward for new storage requests. This approach may
potentially be harmful to the health of existing storage requests if the fill
reward is higher compared to the collateral of active storage requests. The lack
of disturbance in market dynamics may be enough for this behavior to be
acceptable. Clients that set a high fill reward should likely also set a high
collateral so that the same does not happen to their storage requests. The high
collateral may be a deterrent to SPs filling the slots, and other aspects of
their request should be sufficient to attract SPs. In other words, normal market
behaviors will determine what the values should be. Codex's UI available to
clients should help guide them when making decisions on their storage request
parameters.

Without empirical data on the real world behaviors of SPs, the types of
behaviors to guard against may be purely speculative and not worth the
complexity impact on the protocol design. In that regard, perhaps moving forward
with the second approach is the right choice, and then moving to the first
approach if real world SP behavior warrants its implementation.

### No reservation collateral and reward

In this simplified slot reservations proposal, there will not be reservation
collateral and reward requirements until the behavior in a live environment can
be observed and it is determined this are necessary mechanisms.

### No reservations expiry and retries

As a difference from the originally proposed slot reservations, there will be no
reservation expiry and no reservation retries until actual behavior on the
network is observed and it is determined this is a needed mechanism.

### Reservations per slot

Each slot is allowed to have three reservations, which effectively limits the
quantity of racing to three SPs.

### Expanding windows per slot

The slot will have one expanding window of eligible SP addresses that can
reserve the slot. This expanding window is shared across all three reservations
in the slot. This is different to the originally proposed slot reservations,
which had a unique expanding window per reservation.

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
along, forfeit the reservation by reserving and filling another slot,
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

There is also a decreasing fill reward that incentivizes the SP to fill the
slot as fast as possible to gain the most reward. By waiting to see if there are
better opportunities that arise, the SP will miss out on a larger fill reward.

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
it incentivize behavior that would prevent it, however the large cost associated
with this attack is a natural deterrent and is less probably to occur.

#### Lazy client attack

This attack happens when a client creates a request for storage, but ultimately
does not release the data to the network when it requested. SPs may reserve the
slot, with collateral, and yet would never be able to fill the slot as they
cannot download the data. The result of this attack is that any SPs who reserve
the slot may lose their collateral.

At this time, slot reservations does not mitigate against this attack, nor does
it incentivize behavior that would prevent it.

### Open questions

Perhaps the expanding window mechanism should be network-aware such
that there are always a minimum of two SPs in a window at a given time, to
encourage competition. The downside of this is that active SPs need to be
persisted and tracked in the contract, with larger transaction costs resulting
from this.

### Trade offs

The main advantage to this design is that nodes and the network would not be
overloaded at the outset of slots being available for SP participation.

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
