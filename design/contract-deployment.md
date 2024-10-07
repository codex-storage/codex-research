# Codex Contract Deployment, Upgrades and Security

This document is a rough outline of our current understanding of how we want to handle Codex's smart contract
deployment,
maintanence, ownership, upgrades and security-related questions. Already in our internal discussion we discovered lot of
issues related mainly to security, so this is far from final design. We will first discuss our original naive deployment
approach with upgrade plans, and then we will describe potential security issues and outline possible mitigations.

Our main design goal is to have our system as permissionless as possible, yet we need to understand how to do it in the
most secure way and have prepared scenarios for the worst cases, like discovered unexploited bugs or damage control on
exploited bugs.

## Original naive deployment

Our original vision was to have the most permissionless and simple deployment. We want to simply deploy the contracts in
which there would not be any "admin roles" that would have power to affect the whole contract and network. Moreover,
there would not be any "proxy contract" or "upgradable contract," just simple deployment of our contract suite. The
smart contract's address would then be hardcoded into the Codex client. We would hence not possess any "ownership" over
the smart contract or have any decision power that would affect the whole network from the smart contract side.

### Upgrades

Of course, we expect and have already planned future upgrades of Codex and its smart contracts; therefore, we thought of
upgrade paths. As mentioned above, we would not have any ownership over the smart contract, so we would propose new
upgrades through new Codex client releases. New smart contract addresses would be changed in the Codex client after
deployment and be part of the next Codex client release.

We envision a graceful handover period during which the Codex client will be supporting two smart contracts—the
original deprecated one and the new upgraded one. In this period, the Codex client would create all the new Storage
Requests on the new smart contract, but it will still fulfill the duties of the Storage Requests of the deprecated
contract.

```
                                ┌─────────────────────────────────────────      
                                │                Contract v2                    
┌───────────────────────────────┼────────────────────┬──────────────────────►   
│           Contract v1         │┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼│                      time
└───────────────────────────────┼────────────────────┤                          
                                │    Grace period    │                          
                                │                    │                          
                                │                    │                          
                                │                    │                          
                                │                    │                          
                                │                    │                          
                       Codex release with             Codex release that        
                       new smart contract             removes old contract      
```

An important consideration for this upgrade mechanism is that we plan to limit the maximum duration of Storage Requests.
This ensures that when we release a new version of the Codex client with the upgraded smart contract, we have a
deterministic date upon which we can sunset and remove the original smart contract from the Codex client, as all Storage
Requests will be completed. Initially, we plan to limit the duration to one month, and as the network matures and
upgrades become less frequent, we intend to extend this period.

:::warning
❓**Upgrade period's end**❓

Even when we have the limit on Storage Request's duration, when should we really remove it from the client? We can't
expect everybody to update the client right on the new release day. For example, we should wait double the amount of the
duration limit time. Or we could make more advanced decisions based on statistics from the network? Also the
fund-withdraw smart contract calls (eq. for expired Requests) can be delayed by the user even indefinately.
:::

There is one open question, though. If some participants in the network do not follow the latest updates of the Codex
client, they might end up with a version that still uses the deprecated smart contracts, even though the rest of the
network might have already moved. We considered some sort of freezing functionality with which we could stop a contract
once its lifespan is finished. However, we are not so fond of the idea because it would require an admin-role user that
would have the power to affect the whole network. We argue that it is the responsibility of the node operators to timely
update their nodes, and if they wish to fall behind, they are free to stay at their desired version. A potential
mitigation of this problem could be to set a smart contract expiry after which it would go into "withdraw only" mode.
This would not need any admin-role but would require us not to miss the deadline and release a new version every time
the lifetime of the contract comes to an end.

## Security consideration

Even though we invest significant time and resources to make the smart contracts as safe as possible, there is still a
very possible risk of exploitable bugs being found after deployment. We can think of two main situations that can occur:

1. Exploit is discovered and privately disclosed to us.
2. Exploit is unknown to us and is being/was exploited.

In the first situation, we would be given leeway to correct our bug, but the clock would be ticking as we might be in a
race with potential exploiters who could be trying to exploit the bug eventually. In this case, we would have to perform
some sort of emergency upgrade. For such an upgrade, there would need to be no transition period, as the old smart
contract containing the bug would need to be sunset ASAP. This is in contradiction to our original upgrade path, which
is timed according to the Stoarge Request's duration limit.

In the second situation, we would need to perform the same emergency upgrade, but at the same time, by the time we
finish the emergency upgrade, funds might already be stolen. Hence, we would need some mechanism to pause the contract
in a way that no malicious transfer of funds could occur during this period.

It is also worthy to note that these situations impose a big reputation problem for our project. Some could argue that 
"if we get hacked, we are done". While this could be true to some extent, we should not give up on mitigations of these
situations. In the first situation presented above, we still have a chance to recover the situation. In the second
situation, it is our responsibility to do damage control in the way to protect the funds and data of our users even
though some of it might be lost in the process.

## Mitigations

We explored several ways how we can mitigate such risks. Unfortunately, all of them require us more or less to relax our
initial ideals of a permissionless approach.

### Upgradable contract

OpenZeppelin has tooling for writing [Upgradable contracts](https://docs.openzeppelin.com/upgrades-plugins/1.x/). While
this approach has some limitations, it should be sufficient for realizing bug fixes as part of emergency upgrades. This
would require to have admin role that have this ability.

While this solution provides the most capable and flexible way to ensure security, it also gives "too much power" for
the admin role. With these upgrades one could change the contract to for example withdraw all funds to certain address
without consent of the network. Therefore it creates liabilities, centralize control over our decentralized network and
have potential legal implications, therefore we are reluctant to take this path.

Another part that is often found in the ecosystem coupled with upgradable contracts
are [timelocks](https://blog.openzeppelin.com/protect-your-users-with-smart-contract-timelocks). They allow for the
users to take action in case they do not agree with proposed upgrade before it is applied. This though contradicts the
need for timely action as we are describing emergency upgrade here and not "feature upgrades"

### Freezing contract

Another approach would be to have an admin role that would be allowed only to freeze the contract. The frozen contract
would transition to a "withdraw-only" mode, where all the Storage Requests that were running in the contract would get
terminated up to the time when the contract was frozen, and the funds would be split between the Client and Storage
Provider according to the service rendered.

:::info
OpenZeppelin has support for
writing [Pausable contracts](https://docs.openzeppelin.com/contracts/2.x/api/lifecycle#pausable).
:::

The big problem with this approach is that it effectively purges the network. Upon the release of the new version, the
new contract won't have any of the old Storage Requests. As a result, SPs won't have an incentive to keep the data they
originally stored. Clients could potentially recreate the old Storage Requests, but they might fail to do so for two
reasons. First, Clients might not be available in time to do so as they are the most ephemeral participants in the
network. Second, they might not be in possession of the original dataset at the time of Storage Requests recreation, and
by that time, the data might already be removed from the original SPs.

Wiping the network is a big problem for a project that is so focused on durability like ours. Therefore, we should find
a solution to prevent this. The good news is that generally, participants are motivated to keep the network working in
the case of these "catastrophic events." It could be expected from them to provide some leeway in the form of downtime,
unpaid hosting time, sacrificing some payout, etc., in order for the network to recover.

:::warning
❓**Unfreezing**❓

Should it be possible to also have the capability to "unfreeze" the smart contract? This would require us to rethink
the "withdraw-only" mode, but could be beneficial in some circumstances.
:::

:::info
The account that has this role assigned, should be most probably handled with multi-sig.

There are questions about how this multi-sig should be setup: the number of participants, the requirements for quorum
etc.

In future there might be also included trusted 3rd-parties from the community.
:::

#### Warchest

We have come up with an idea that should prevent the wiping of the network. As it is our responsibility to deploy secure
contracts, we should also be ready to "pay the price" when our work has an exploit in it. We therefore envision a war
chest of Codex tokens that would be drafted for this occasion. Its funds would then be used to fund the recreation of
the Storage Requests on the newly deployed smart contracts, which would incentivize original SPs not to ditch the data
that they were hosting prior to the freezing of the old smart contract.

The process would then go along these lines:

1. The old contract is frozen - everybody can only withdraw their funds (SPs: collateral + partial payout; Clients: rest
   of the payout).
2. We deploy a new contract with the fix.
3. We reconstruct the state of the old contract's Storage Requests prior to the exploit being used from the blockchain
   logs.
4. We recreate the Storage Requests from the rebuilt state using the funds from the war chest. Requests are reserved for
   some time for the original SPs that hosted them.
5. We release a new version with a fixed smart contract.
6. SPs update to the new version and upon starting, the node checks for reservations. If found, they deposit collateral
   back to the Storage Request and continue their original hosting.
7. (?) Clients can potentially top up the Storage Request to its original price.

### Locked funds limit

Another possibility would be to limit the amount of funds locked inside the contract in order not to attract the
attention of black hats. We already plan to have the limitation of Storage Request's duration, which already contributes
in this direction. Although other limitations are a bit questionable. While we want to do mitigations of possible
attacks, we do not want to hinder the usability and usefulness of the network by enforcing some artificial limitations
upon the participants. On the other hand, this could be a potentially useful strategy for initial deployment with clear
messaging that we will slowly be removing these artificial constraints as the network and smart contract suite matures.

### Contract modularization

The latest approach we came up with combines the "Freezing" and "Upgradable" approaches.
We suggest splitting the contract into two new contracts — business logic contract and vault contract.

Business logic contract would contain the Marketplace logic, and it would be possible to perform emergency upgrades using concepts
described in [Upgradable contract](#upgradable-contract) section. In this way if there is bug/exploit that would, 
for example, affect the funds, it would be possible to quickly patch it. The original "feature upgrade" path still holds
with this approach, where this business logic contract would get upgraded as discussed in [Upgrades](#upgrades) section.
The admin role would belong to multisig maintained inside the organization. This contract would not hold any funds as
they would be delegated to vault contract. 

Vault contract has the responsibility to safe-keep user's fund. It should have minimal logic incorporated to minimize
attack surface. This contract would not incorporate the upgradibility capabilities, but as a safety measure, it would be 
possible to freez it as described in [Freezing contract](#freezing-contract) section. Freezing the Vault would be done
in case of severe exploitable bug. It would be possible to trigger it with multisig maintained inside the organization,
which could be later on extended to members of the community. Once freezed the contract would not be able to unfreez later
on, hence freezing the vault contract is a very impactful action which should not be taken lightly. This action would
most probably lead to deploying a new token contract as part of a token upgrade, together with redeploying the whole
marketplace contract's suite.

The Vault contract should have logic that prevents draining all the funds at once. We came up with two designs for 
this - time-based locking and recipient-based locking. Time-based locking vault is described in the depth below.
The recipient-base vault works with locking schema where the funds have a predefined set of recipients to which the funds
can be transferred to. In this way it is not possible for the hacker to redirect the funds to their controlled accounts.
Unfortunately, this concept is not applicable for Marketplace because of slot repairs, when one slot's host is replaced
with another, which would require reallocating funds and hence open an opportunity for hackers to redirect the funds to 
their accounts.

#### Time-based Vault

This vault works on locking the funds until a certain time threshold, when it allows them to be spent. In this way
there is only a tiny fraction of the funds possible to be spent at a given time by the "business logic" contract as
we assume nodes will proactively and quickly collect their funds when able. If there is exploit on the business logic 
contract, the attacker could withdraw only a small amount of funds.

```solidity
contract TimeVault {
   /// Creates new deposit with given amount transferred from account "fromAccount" and lock it till spendable_from_timestamp
   function deposit(uint256 amount, addr fromAccount, uint256 spendable_from_timestamp) returns (DepositId)
   /// Deposits more funds to already existing deposit 
   function deposit(uint256 amount, addr fromAccount, uint256 spendable_from_timestamp, DepositId id) returns (DepositId)
   
   /// Extends the timelock of the specified deposit 
   function extend(DepositId id, uint256 spendable_from_timestamp)
   
   /// Lower deposit amount of funds from specified deposit
   function burn(DepositId id, uint256 amount)
   
   /// Transfer given amount to recipient, provided the block's timestamp is after deposit's time lock 
   function spend(DepositId id, addr recipient, uint256 amount)
}
```

_Important note is that this is a standalone contract it needs to keep track of the "owner of the deposit". 
Hence, only the address that performs initial deposit can manipulate with the funds later on._

Integration into the Marketplace contract would be in the following way:

 - `deposit()` reward funds upon `requestStorage()` call with time-lock until the Request's `expiry`
   - If Request starts, the time-lock is extended till Request's end
   - If Request expires, then funds (partial payouts for hosts and remaining funds for a client) can be withdrawn when requested
 - `deposit(depositId)` collateral funds to existing Request's deposit upon `fillSlot()`
   - If Request expires, the collateral can be withdrawn together with partial payouts
 - Upon Slot's being freed because of host being kicked out then `burn()` host's collateral lowered by amount dedicated repair reward
 - Upon Request's end, collateral and rewards can be `spend()`
 - Upon Request's failure, all host's collateral is `burn()`. The original reward can be `spend()` back to the client, but only after the Request's end

The main disadvantage of this approach is that when Request fails, the client will be able to collect its original funds only after Request's end.

## Resources

- [Ethereum:Smart contract security](https://ethereum.org/pcm/developers/docs/smart-contracts/security/#implement-disaster-recovery-plans)
- [OpenZeppelin: Strategies for Safer Governance systems](https://blog.openzeppelin.com/smart-contract-security-guidelines-4-strategies-for-safer-governance-systems)
- [OpenZeppelin: Timelocks](https://blog.openzeppelin.com/protect-your-users-with-smart-contract-timelocks)
