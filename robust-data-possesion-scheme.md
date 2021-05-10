# Robust Proofs of Data Possession and Retrievability

> Proofs of data possession (PoDP) schemes establish if an entity is currently or has been in possession of a data set. Proofs of Retrievability (PoR) schemes attempt to detect with negligible probability that an entity is maliciously or otherwise withholding data.

## Proofs of data possession

In our definition, a robust PoDP scheme is one that can prove with negligible probability that a storage provider is currently or has been in possession of a data set.

To state the obvious first - the most secure data possession scheme is to "show" the data every time it's being requested. In other words, the most secure way of proving that someone has a file is for him/her to show the file every time it is being requested. Alas, due to bandwidth restriction, this is not practical in the majority of cases hence, the main objective of different data possession schemes is overcoming the limitation of _having to show the entire dataset every time_ to prove its possession.

A common technique to overcome this limitation is, random sampling and fraud proofs. This consist in selecting a random subset of the data instead of the entire data set. The rationale is that, if the prover doesn't know which pieces are going to be requested next, it is reasonable to expect that it will keep all the pieces around to prevent being caught; and a well behaved prover would certainly do that.

The mechanism described above sounds reasonable, unfortunately, naive random sampling only provides weak guarantees of possession.

Lets look at a naive, but relatively common random sampling scheme.

- Given a file $F$, split it into a set of chunks $C$, where $C=\{c_1, c_2,...,c_n\}$
- Next, generate a publicly available digest $D$ of the file from the chunks in $C$ - for example a Merkle tree
- To prove existence of the file, provide random chunks from the set $C$, along with a part of the digest $D$
- A verifier, takes the random chunks provided and attempts to verify if they match the digest, if they do, they're assumed to be part of the same set $C$

The problem with this sampling technique however, is that it can only prove existence of those pieces that have been sampled at that particular point in time and nothing more.

For example, lets say that the prover $P$, supplies randomly sampled chunks $c_\alpha$ from the set $C$, at discrete time intervals $T$ to a verifier $V$. At time $t_0$, $P$ successfully supplies the set $\{c_1, c_7, c_9\}$ request by $V$; at time $t_1$ it supplies the set $\{c_2, c_8, c_5\}$; at time $t_2$ it supplies the set $\{c_4, c_3, c_6\}$ and so on.

Each of this sampling steps are statistically independent from one another, ie, the set provided at $t_3$ doesn't imply that the sets $t_2$, $t_1$ and $t_0$ are still being held by the prover, it only implies that it's in possession of the currently provided set. At each verification step, the odds of detecting a malicious or faulty prover are proportional to the amount of sampled chunks. In other words, if the prover can provide %50 of the chunks, the chance of catching it are %50, if it provides %5 the chances of catching a malicious or faulty node are %5. Moreover, this doesn't establish possession over time, which we defined as another property of PoDP.

One common misconception is that increasing the sampling rate will somehow change the odds of detecting missing chunks, but that is not the case, at best it will allow detecting that they are missing faster, but the odds will still be the same.

To understand why, lets do a quick refresher on basic statistics. There are two types of statistical events - independent and dependent. In an independent event, the outcome of the previous event does not influence the next outcome. For example, flipping a coin always has a %50 chance of hitting either heads or tails, and throwing it 10 times vs 100000 times would not change this odds. Dependent events on the other hand are tied and the odds of the next event are dependent on the outcome of the previous event. For example, if there is a bag with 5 marbles, 2 red and 3 blue, the odds of pulling a red marble is 2 in 5 and the odds of pulling a blue one is 3 in 5. Now, if we pull one red marble from the bag, the odds change to 1 in 4 and so on.

To increase the robustness of random sampling schemes and establish possession over time, each sampling event needs to be dependent on the previous event. How can we do this? A potential way is to establish some sort of cryptographic link at each sampling step, such that the next event can only happen after the previous one completed, thus establishing a chain of proofs.

Lets extend our naive scheme with this new notion and see how much we can improve on it. For this we need to introduce a new primitive - a publicly known and verifiable random beacon. This can be anything, from a verifiable random function (VRF) to most blockchains (piggy backing on the randomness properties of the blockchain). In this scheme, we generate the same publicly known and verifiable digest $D$, but instead of supplying just random chunks along with a part of the digest (merkle proofs of inclusion), we also supply an additional digest generated using a value supplied by the random beacon $B$ and the previous digest - $d_{n-1}$. In other words, we establish a cryptographic chain that can only be generated using a digests from previous rounds.

It looks roughly like this. We chunk a file and generate a well known digest $(D)$, lets say it is the root of the merkle tree derived from the chunks. This is also the content address used to refer to the file in the system. Next, we use the digest and a random number from the random beacon to derive a _verification digests_ at each round. The first iteration uses the digest derived by concatenating the random number from the random beacon and the digest $D$ to generate a new verification digest $d_0$, subsequent rounds use the previous digest (ie $d_{n-1}, d_{n-2}, d_{n-3}$, etc..) to generate new digests at each round. Like mentioned above, this creates a chain of cryptographic proofs, not unlike the ones in a blockchain, where the next block can only be generated using a valid previous block.

More formally:

($||$ denotes concatenation)

- Given a file $F$, split it into a set of chunks, where $C=\{c_1, c_2,...,c_n\}$
- Using the chunks in $C$, generate a digest $D$ such that $D=H(C)$
- To prove existence of the file
  - Select random chunks $c_\alpha = \{c_1, c_3, c_5\}$, $c_\alpha \subset C$
  - Get a random value $r$ from $B$ at time $t_n$, such that $r_n=B(t_n)$
  - Using $r_n$, plus $d_{n-1}$, generate a new digest, such that $C_n = \forall \sigma \in C: d_{n-1} || r_n || \sigma$ , and $d_n = H(C_n)$
    - At time $t_0$, the digest $d_0$ will be constructed as $C_n = \forall \sigma \in C: D || r_0 || \sigma$ , and $d_0 = H(C_n)$
  - We then send $d_n$ and $c_\alpha$ to the verifier
- A verifier, takes the supplied values and using a function first verifies that $V(H(c_\alpha), D)$ it the takes $V(H(\forall \sigma \in c_\alpha: d_{n-1} || r_n || \sigma), d_n)$

The first question to ask is how much has this scheme improved on our naive random sampling approach? Assuming that our cryptographic primitives have very low chances of collision and our randomness source is unbiased, the chances of forging a proof from a subset of the data are negligible, moreover, we can safely reduce the number of sampled chunks to just a few and still preserve the high level of certainty that the prover is in possession of the data, thus keeping the initial requirement of reducing bandwidth consumption.

However, in its current non-interactive form the digest can be forged by combining the already known requested chunks and complementing the rest with random chunks. In order to prevent this, we need to split the digest generation and verification into independent steps, ie make it interactive.

In an interactive scheme, where the prover first generates and sends a digest $d_n$ and the verifier then requests random chunks from the prover we can prevent these types of attacks. However every interactive scheme comes with the additional overhead of the multiple rounds, but as we'll see next, we can use this property to build a robust proof of retrievability scheme from it.

## Proofs of Retrievability

A robust PoR scheme is one that can detect with negligible probability that a node is maliciously or otherwise withholding data.

A particularly tricky problem in PoR schemes is the "fisherman" dilemma as described by [Vitalik Buterin](https://github.com/ethereum/research/wiki/A-note-on-data-availability-and-erasure-coding).

To illustrate the issue, lets look at a simple example:

- Suppose that $P$ is storing a set $C=\{c_1, c_2..c_n\}$
- A node $\rho$, attempts to retrieve $C$ from $P$
- If $P$ is maliciously or otherwise unable to serve the request, $\rho$ needs to raise an alarm

However, due to the "fishermans" dilemma, proving that $P$ withheld the data is impossible. Here is the relevant quote:

> because not publishing data is not a uniquely attributable fault - in any scheme where a node ("fisherman") has the ability to "raise the alarm" about some piece of data not being available, if the publisher then publishes the remaining data, all nodes who were not paying attention to that specific piece of data at that exact time cannot determine whether it was the publisher that was maliciously withholding data or whether it was the fisherman that was maliciously making a false alarm.

From the above, we can deduce that unless the entire network is observing the interaction between the requesting node and the responding node, it's impossible to tell for sure who is at fault.

There are two problems that the "fisherman" dilemma outlines:

- "all nodes who were not paying attention to that specific piece of data at that exact time"
- "was the publisher that was maliciously withholding data or whether it was the fisherman that was maliciously making a false alarm"

This can be further summarized as:

1. All interactions should be observable and
2. All interactions should be reproducible and verifiable

The first requirement of observability can be broken down into observing the requester and observing the responder.

1. In the case of the responder, if it knows that no-one is observing then, there is no way anyone can prove that it withheld the data
2. In the case of the requester, it is both impossible to prove wrongdoing on behalf of the responder and prove that the requester is being honest in its claims

We can invert the first proposition and instead of it being "if it knows that no-one is observing" we can restate it as "if it doesn't know when it's being observed" and introduce uncertainty into the proposition. If the responder never knows for sure that it's being observed, then it's reasonable for a rational responder to assume that it is being observed at all times.

There isn't a way of directly addressing the second issue because there is still no way of verifying if the requester is being honest without observing the entire network, which is intractable. However, if we instead delegate that function to a subset of dedicated nodes that observe both the network and each other, then the requester never needs to sound the alarm itself, it is up to the dedicated nodes to detect and take action against the offending responder.

However, this scheme is still incomplete and it's reasonable to assume that the responder can deny access to regular requesters, but respond appropriately to the dedicated verifiers. The solution is to anonymize the validators so that it is impossible to tell wether the requester is being audited or simply queried for data. This guarantees that storing nodes always respond to any request as soon as possible.

Our second requirement states that all interactions should be reproducible and verifiable. It turns out that this is already partially solved by our PoDP scheme. In fact, the seemingly undesirable interactive property, can be used to extend the PoDP scheme to a PoR scheme.

## Extending PoDP to PoR

To extend the PoDP with PoR properties, we simply need to turn it into an interactive scheme.

Suppose that we have a trustless network of storing (responders), validating and regular (requesters) nodes. Storing nodes generate and submit a verification digest $d_n$ at specific intervals $t_n$. Validator nodes, collectively listen (observe) this proofs (which consist of only the digest). Proofs are aggregated and persisted, such that it is possible retrieve them at a later time to precisely establish when the node was last in possession of the dataset. Proofs are only valid for a certain window of time, so if the node went offline and failed to provide a proof for several intervals, it would be detect and the node would be marked offline. This by itself is not sufficient to prove neither possession nor availability, but it does establish a verifiable chain of events.

Next, at random intervals, an odd subset of the validators is selected and each validator requests unique random set of chunks from the storing node. Each validator then verifies the chunks against $d_n$. If the chunks match for all validators, then each will generate an approval stamp which will be aggregated and persisted in a blockchain.

If chunks only match for some validators and since there is an odd number of validators, then the majority decides if they are correct or invalid, thus avoiding a tie. Neither the validators nor the storing nodes know ahead of time which subset they will end up being part of and each validator generates its own random set to probe.

In order to reduce bandwidth requirement and load on the network, validation happens periodically, for example, every two hours in a 24 hour window. If a faulty node misses a window to submit its proof (digest) it's marked offline and penalized, but if a malicious node submits several faulty proofs in succession, it should be detected during the next window of validation and penalized retroactively for every faulty proof. If enough proofs are missed and assuming that all participants are bound by a collateral, then the faulty or malicious node gets booted from the set of available storing nodes and looses it's stake.

In a similar manner, if a node from the validators subset failed to submit its stamp on time, it gets penalized with a portion of its collateral and eventually booted off the network.

Well behaved nodes get rewarded for following the protocol correctly, faulty or malicious nodes are detected, penalized and eventually booted out.

## Conclusion

To understand whether the described PoDP and PoR schemes satisfy the requirements of being robust, lets first outline what those are:

1. Establish possession of data over time
2. Establish possession of data at the current time
3. Detect faulty or malicious nodes that are withholding data
4. Circumvent the "fishermans" dilemma

Now, does our proposed scheme satisfy this requirements?

- We can reliably say that a node has been in possession of data over time by issuing a cryptographically linked chain of proofs - this satisfies 1.
- We can reliably tell whether a node is currently in possession of a data set by interactively probing for randomly selected chunks from the original data set and matching them agains the current digest - this satisfies 2.
- We introduced uncertainty through anonymity and randomness into the interactive verification process, which allows us to satisfy 3 and 4.
  - Only dedicated nodes need to monitor the network, which makes observability tractable
  - Since nodes don't know when they are observed, rational nodes can only assume that they are always observed, thus preventing data withholding and encouraging availability

Furthermore, assuming that the broadcasted proofs are smaller than the original data set, we keep the bandwidth requirements low. We can further improve on it by reducing the probing frequency. Since faults can still be reliably traced back to their origin, nodes can be retroactively punished, which further reduces the possibility of gaming the protocol.
