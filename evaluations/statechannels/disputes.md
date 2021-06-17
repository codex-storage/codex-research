State Channel Disputes
======================

A problem with state channels is that participants have to remain "online"; they
need to keep an eye on latest state of the underlying blockchain and be able to
respond to any disputes about the final state of the state channel. Ironically
this problem stems from the mechanism that allows a state channel to be closed
when a participant goes offline. Closing a channel unilaterally is allowed, but
there is a period in which the other participant can dispute the final state of
the channel. Therefore participants should be monitoring the blockchain so that
they can respond during a dispute period.

### Pisa

https://www.cs.cornell.edu/~iddo/pisa.pdf

The PISA protocol enables a participant to outsource monitoring of the
underlying blockchain to an untrusted watchtower. The main idea is that a hash
of the latest state channel update is sent to the watchtower. The watchtower
responds with a signed promise to use this information to settle any disputes
that may arise. Should the watchtower fail to do so, then the signed promise can
be used as proof of negligence and it will lose its substantial collateral.

A potential problem with this scheme is that the collateral is shared among all
state channels that the watchtower is monitoring, which could lead to bribing
attacks.

### Brick

https://arxiv.org/pdf/1905.11360.pdf

The BRICK protocol provides an alternative to the dispute period based on
byzantine consistent broadcast. Participants in a state channel assign a
committee that is allowed to sign off on channel closing in case they are not
able to do so themselves. Instead of waiting for a period of time before
unilaterally closing the channel, with BRICK you wait for a threshold number of
committee members to confirm the latest state of the channel. This is much
faster.

Each state channel update contains a sequence number, which is signed by the
channel participants and sent to the committee members. For a channel to be
closed unilaterally, the BRICK smart contract requires a signed state update,
and signed sequence numbers provided by a majority of the committee. The highest
submitted sequence number should match the submitted state update. Committee
members that submit a lower sequence number lose the collateral that they
provided when the channel was opened.

A potential problem with the implementation of BRICK as outlined in the paper is
that the collateral scheme is vulnerable to sybil attacks; committee members can
attempt to steal their own collateral by providing proof of their own
wrongdoing.

Unilateral closing is also rather heavy on blockchain transactions; each
committee member has to separately perform a transaction on chain to supply
their sequence number.
