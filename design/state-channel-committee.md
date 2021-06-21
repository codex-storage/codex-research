A State Channel Committee Scheme
================================

It should in general be possible to close payment and state channels when one of
its participants goes offline. This presents a problem: how do we know that the
single party that attempts to close the channel presents the *latest* state of
the channel. It could be beneficial to present an older state, where more money
was allocated to that party.

Most channel schemes therefore introduce a dispute period; a period of time in
which the state at which a channel is closed can be disputed. During the dispute
period the other party can prove that a state is old by providing a newer state
that was signed by all parties.

But dispute periods do not help when they are needed the most; when a party goes
offline. An offline party cannot participate in the dispute mechanism.

Schemes such as [PISA][1] solve this problem by introducing a monitoring
service. This monitoring service will engage in the dispute process on behalf of
the offline party. To ensure that the monitoring service acts honestly, it puts
up collateral that can be claimed when any wrongdoing is detected.

More recently, the [BRICK][2] scheme was introduced that does away with the
dispute period all together. Instead it employs a committee that can sign off on
the closing of a channel. Committee members are kept honest by the collateral
that they put up.

Here, we'd like to introduce a scheme that improves on BRICK by requiring less
blockchain interactions and smaller signatures. We simplify payment of fees, and
provide a mitigation against sybil attacks regarding collateral.

Updates
-------

Updates to the channel state are only valid when they are signed by all
participants and committee members. For efficiency, these signatures can be
combined into a single signature using Schnorr or BLS. Each new update contains
an incremental sequence number.

Fees
----

Fees to compensate the committee members for their efforts can be paid by
increasing the committee member's balances in each channel update.

Unilateral closing
------------------

Closing a channel by a single participant requires a valid state update, and a
signed statement by a committee majority that this is the latest state update.

Collateral
----------

Committee members are only allowed to participate once they've secured
collateral on-chain.

If they sign a state update, and then are found to have signed off on closing
the channel on an older state update, then they lose their collateral. This
collateral is mostly burned to prevent sybil attacks. A small part of the
collateral is paid to the party that provided proof of wrongdoing. This allows a
single honest committee member to keep the rest of the committee in check.

Bribing
-------

To prevent bribing attacks the collateral that is burned when a committee
majority cheats should be larger than the value of whatever is exchanged in the
channel.

Withholding
-----------

To prevent withholding attacks by the committee majority, they should not be
able to retrieve their collateral when they are still participating in state
channels.

Note that a committee member is free to initiate the closing of channels that it
participates in to retrieve its collateral.

Privacy
-------

To prevent committee members from learning about the contents of intermediate
state updates, everything in the state may be blinded, except for the balances
of the committee members (so that they can check the fee), and the sequence
number (so that they know which state is the latest).

Improvements on the state of the art
------------------------------------

We improve on the PISA and BRICK protocols by removing the need for extra
unidirectional payment channels to pay the monitoring service / committee.
Because we require all state updates to be co-signed by the committee they can
ensure that fees are paid there.

We improve on the BRICK protocol by allowing signatures from all participants
and committee members to be combined into a single signature using Schnorr or
BLS signatures.

We improve on the BRICK protocol by requiring less interaction with the
blockchain when closing unilaterally. In particular, we do not require each
committee member to perform a transaction during closing; instead we accept a
single transaction with the combined signatures of a majority of the committee.

We mitigate a sybil attack that is possible in the BRICK protocol, by burning
collateral in case of wrongdoing.

Further work
------------

Our scheme requires a smart contract to open and close state channels. It would
be interesting to see whether we can remove the need for a smart contract so
that this scheme could be used on asynchronous blockchains such as [ABC][3].

Our scheme still lacks a formal proof.

It also lacks a proof-of-concept implementation and performance measurements.

[1]: https://www.cs.cornell.edu/~iddo/pisa.pdf
[2]: https://arxiv.org/pdf/1905.11360.pdf
[3]: https://arxiv.org/pdf/1909.10926.pdf