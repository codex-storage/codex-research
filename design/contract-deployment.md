# Codex Contract Deployment, Upgrades and Security

We created this document to document our thoughts on contract deployment. We have explored several
ways how to tackle it, but as it is not only an engineering problem but also involves governance and legal considerations
it took several iterations before we reached our final design.

Our main design goal is to have our system as permissionless as possible, yet we need to understand how to do it in the
most secure way and have prepared scenarios for the worst cases, like discovered unexploited bugs or damage control on
exploited bugs. In this problem space, there are no simple answers, but it requires weighing all sorts of trade-offs.

## Original naive deployment

Our original vision was to have the most permissionless and simple deployment. We wanted to simply deploy the contracts in
which there would not be any "admin roles" that would have the power to affect the whole contract and network. Moreover,
there would not be any "proxy contract" or "upgradable contract," just a simple deployment of our contract suite. The
smart contract's address would then be hardcoded into the Codex client. Hence, we would not possess any "ownership" over
the smart contract or have any decision power that would affect the whole network from the smart contract side.

### Feature upgrades

Of course, we expect and have already planned future upgrades of Codex and its smart contracts; therefore, we thought of
upgrade paths. As mentioned above, we would not have any ownership over the smart contract, so we would propose new
upgrades through new Codex client releases. New smart contract addresses will be changed in the Codex client after
deployment and will be part of the next Codex client release.

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

> [!WARNING]
> ❓**Upgrade period's end**❓
>
> Even when we have the limit on Storage Request's duration, when should we really remove it from the client? We can't
> expect everybody to update the client right on the new release day. For example, we should wait double the amount of the
> duration limit time. Or we could make more advanced decisions based on statistics from the network? Also, the
> fund-withdraw smart contract calls (eq. for expired Requests) can be delayed by the user even indefinitely. But then,
> there will be always the old versions of Codex around, so if somebody will remember that he did not withdraw funds for
> too long, he can always download the old version and spin it up only for the withdrawal calls and then delete it.

There is one open question, though. If some participants in the network do not follow the latest updates of the Codex
client, they might end up with a version that still uses the deprecated smart contracts, even though the rest of the
network might have already moved. We considered some sort of freezing functionality with which we could stop a contract
once its lifespan is finished. However, we are not so fond of the idea because it would require an admin-role user that
would have the power to affect the whole network. We argue that it is the responsibility of the node operators to
update their nodes in a timely manner, and if they wish to fall behind, they are free to stay at their desired version. A potential
mitigation of this problem could be to set a smart contract expiry, after which it would go into "withdraw only" mode.
This would not need any admin-role but would require us not to miss the deadline and release a new version every time
the lifetime of the contract comes to an end.

## Security consideration

Even though we invest significant time and resources to make the smart contracts as safe as possible, there is still a
very possible risk of exploitable bugs being found after deployment. We can think of two main situations that can occur:

1. Exploit is discovered and privately disclosed to us.
2. Exploit is unknown to us and is being/was actively exploited.

In the first situation, we would be given leeway to correct our bug, but the clock would be ticking as we might be in a
race with potential exploiters who could be trying to exploit the bug eventually. In this case, we would have to perform
some sort of emergency upgrade. For such an upgrade, there would need to be no transition period, as the old smart
contract containing the bug would need to be sunset ASAP. This is in contradiction to our original upgrade path, which
is timed according to the Storage Request's duration limit.

In the second situation, we would need to perform the same emergency upgrade, but by the time we
finish the emergency upgrade, funds might already be stolen. Hence, we would need some mechanism to pause the contract
in a way that no malicious transfer of funds could occur during this period.

It is also worth noting that these situations impose a big reputation problem for our project. Some could argue that
"if we get hacked, we are done". While this could be true to some extent, we should not give up on mitigating these
situations. In the first situation presented above, we still have a chance to recover from the situation. In the second
situation, it is our responsibility to do damage control to protect the funds and data of our users, even
though some of it might be lost in the process.

## Mitigations

We explored several ways how we can mitigate such risks. Unfortunately, all of them require us more or less to relax our
initial ideals of a permissionless approach.

### Upgradable contract

OpenZeppelin has tooling for writing [Upgradable contracts](https://docs.openzeppelin.com/upgrades-plugins/1.x/). While
this approach has some technical limitations, it should be sufficient for realizing bug fixes as part of emergency upgrades.
This would require an admin role that would have this capability.

While this solution provides the most capable and flexible way to ensure security, it also gives "too much power" for
the admin role. With these upgrades, one could change the contract to, for example, withdraw all funds to a certain address
without the consent of the network. Therefore, it creates liabilities, centralizes control over our decentralized network, and
has potential legal implications. Therefore, we are reluctant to take this path.

Another part that is often found in the ecosystem coupled with upgradable contracts
is [timelocks](https://blog.openzeppelin.com/protect-your-users-with-smart-contract-timelocks). They allow the
users to take action if they disagree with the proposed upgrade before it is applied. This, though, contradicts the
need for timely action as we are describing emergency upgrades here and not "feature upgrades".

### Freezing contract

Another approach would be to have an admin role that would be allowed only to freeze the contract. The frozen contract
would transition to a "withdraw-only" mode, where all the Storage Requests that were running in the contract would get
terminated up to the time when the contract was frozen, and the funds would be split between the Client and Storage
Provider according to the service rendered.

> [!TIP]
> OpenZeppelin has support for writing [Pausable contracts](https://docs.openzeppelin.com/contracts/2.x/api/lifecycle#pausable).

The big problem with this approach is that it effectively purges the network. Upon the release of the new version, the
new contract won't have any of the old Storage Requests. As a result, SPs won't have an incentive to keep the data they
originally stored. Clients could recreate the old Storage Requests, but they might fail to do so for two
reasons. First, Clients might not be available in time to do so as they are the most ephemeral participants in the
network. Second, they might not be in possession of the original dataset at the time of Storage Requests recreation, and
by that time, the data might already be removed from the original SPs.

Wiping the network is a big problem for a project that is so focused on durability like ours. Therefore, we should find
a solution to prevent this. The good news is that generally, participants are motivated to keep the network working in
the case of these "catastrophic events." It could be expected from them to provide some leeway in the form of downtime,
unpaid hosting time, sacrificing some payout, etc., in order for the network to recover.

> [!WARNING]
> ❓**Unfreezing**❓
>
> Should it be possible to also have the capability to "unfreeze" the smart contract? This would require us to rethink
> the "withdraw-only" mode, but could be beneficial in some circumstances.

> [!IMPORTANT]
> The account that has this role assigned should most probably be handled with multi-sig.
>
> There are questions about how this multi-sig should be set up: the number of participants, the requirements for quorum
> etc.
>
> In the future, trusted 3rd-parties from the community might also be included.

#### Warchest

We have devised an idea to prevent the network from wiping. As it is our responsibility to deploy secure
contracts, we should also be ready to "pay the price" when our work has an exploit in it. We, therefore, envision drafting a war
chest of Codex tokens for this occasion. Its funds would then be used to fund the recreation of
the Storage Requests on the newly deployed smart contracts, which would incentivize original SPs not to ditch the data
they were hosting before freezing the old smart contract.

The process would then go along these lines:

1. The old contract is frozen - everybody can only withdraw their funds (SPs: collateral + partial payout; Clients: rest
   of the payout).
2. We deploy a new contract with the fix.
3. We reconstruct the state of the old contract's Storage Requests prior to the exploit being used from the blockchain
   logs.
4. We recreate the Storage Requests from the rebuilt state using the funds from the war chest. Requests are reserved for
   some time for the original SPs that hosted them.
5. We release a new version with a fixed smart contract.
6. SPs update to the new version, and upon starting, the node checks for reservations. If found, they deposit collateral
   back to the Storage Request and continue their original hosting.
7. (?) Clients can potentially top up the Storage Request to its original price.

### Locked funds limit

Another possibility would be to limit the amount of funds locked inside the contract in order not to attract the
attention of black hats. We already plan to have the limitation of Storage Request's duration, which already contributes
in this direction. Although other limitations are a bit questionable. While we want to mitigate possible
attacks, we do not want to hinder the usability and usefulness of the network by enforcing some artificial limitations
upon the participants. On the other hand, this could be a potentially useful strategy for initial deployment with clear
messaging that we will slowly be removing these artificial constraints as the network and smart contract suite matures.

## Final design - Contract modularization

The final design combines the "Freezing" and "Upgradable" mitigation approaches described above.
This proposal's core is refactoring our current monolithic smart contract structure and splitting it into two new
contracts — a business logic contract and a funds vault contract.

We will reference the business logic contract as **Marketplace contract** as it will contain the Marketplace logic.
It will be possible to perform emergency upgrades using concepts described in the [Upgradable contract](#upgradable-contract) section.
In this way, if there is a bug/exploit that would affect the funds, it is possible to patch it quickly.
The original "feature upgrade" path still holds with this approach, where this business logic contract would get upgraded
as discussed in the [Feature upgrades](#feature-upgrades) section.
The admin role would belong to multisig and be maintained inside the organization. This contract would not hold any funds as
it would delegate them to the Vault contract.

Vault contract will have the responsibility to keep users' funds safe. It should have minimal logic incorporated to minimize
the attack surface. Ideally, the Vault contract will be deployed once and never altered as it will have one simple task
to do, and there should not be a need to extend it. This contract will not incorporate the upgradability capabilities,
but as a safety measure, it will be possible to freeze it as described in the [Freezing contract](#freezing-contract) section.
Freezing the Vault would be done in case of severe exploitable bugs.

Thanks to this splitting of the contract, we will limit the liabilities over funds control as described
in the [Upgradable contract](#upgradable-contract) section, but at the same it gives us the flexibility to react to
unforeseen situations.

The Vault contract should have logic that prevents the simultaneous draining of all the funds. We came up with two ideas for
this - time-based locking and recipient-based locking. The Vault described below utilizes both ideas.

### Vault

This Vault works on locking the funds until a certain time threshold is reached when it allows them to be withdrawn. In this way
there is only a tiny fraction of the funds possible to be redirected at a given time by the "business logic" contract as
the vault only allows manipulation of funds while they are time-locked. If there is an exploit on the business logic
contract, the attacker could withdraw only a small amount of funds.

We envision the following API of the Vault contract:

```solidity
contract Vault {
  /// Locks the fund until the expiry timestamp. The lock expiry can be extended
  /// later, but no more than the maximum timestamp.
  function lock(Fund fund, Timestamp expiry, Timestamp maximum) {}

  /// Deposits an amount of tokens into the vault, and adds them to the balance
  /// of the recipient. ERC20 tokens are transfered from the caller to the vault
  /// contract.
  function deposit(Fund fund, Recipient recipient, uint128 amount) {}

  /// Takes an amount of tokens from the recipient's balance and designates them
  /// for the recipient. These tokens are no longer available to be transfered
  /// to other accounts.
  function designate(Fund fund, Recipient recipient, uint128 amount) {}

  /// Transfers an amount of tokens from the acount of one recipient to the
  /// other.
  function transfer(Fund fund, Recipient from, Recipient to, uint128 amount) {}

  /// Transfers tokens from the account of one recipient to the other over time.
  function flow(Fund fund, Recipient from, Recipient to, TokensPerSecond rate) {}

  /// Delays unlocking of a locked fund.
  function extendLock(Fund fund, Timestamp expiry) {}

  /// Burns an amount of designated tokens from the account of the recipient.
  function burnDesignated(Fund fund, Recipient recipient, uint128 amount) {}

  /// Burns all tokens from the account of the recipient.
  function burnAccount(Fund fund, Recipient recipient) {}

  /// Burns all tokens from all accounts in a fund.
  function burnFund(Fund fund) {}

  /// Transfers all ERC20 tokens in the recipient's account out of the vault to
  /// the recipient address.
  function withdraw(Fund fund, Recipient recipient) {}

  /// Allows a recipient to withdraw its tokens from a fund directly, bypassing
  /// the need to ask the controller of the fund to initiate the withdrawal.
  function withdrawByRecipient(Controller controller, Fund fund) {}
}
```

_Important note is that this is a standalone contract, and it needs to keep track of the "controller of the fund".
Hence, the funds for each controller are independent, and each controller can only manipulate its own funds._

Integration into the Marketplace contract would be in the following way:

- `RequestId`s are used as `Fund` identifiers in the vault.
- When storage is requested by a client, it leads to the following calls on the
  vault:
   - `lock(requestId, request.expiry, request.end)`
   - `deposit(requestId, request.client, request.price)`
- When a slot is filled by a provider, the associated collateral is deposited
  and designated, and some of the client tokens flow to the provider:
   - `deposit(requestId, provider, collateral)`
   - `designate(requestId, provider, collateral - repairReward)`
   - `flow(requestId, client, provider, pricePerSlotPerSecond)`
- When a request starts, the time lock is extended:
   - `extendLock(requestId, request.end)`
- When a request ends, then the vault will allow hosts and client to withdraw
  their tokens. This consists of collateral and partial payouts for hosts and
  any remaining funds for the client:
  - either: `withdraw(requestId, recipient)`
  - or: `withdrawByRecipient(marketplace, requestId)`
- When a provider misses a storage proof, then a part of its collateral is
  burned:
  - `burnDesignated(requestId, provider, slashAmount)`
- When a slot is freed because a provider missed too many proofs, then the
  repair reward is set aside, the flow of tokens to the provider is reversed,
  and the rest of the provider tokens are burned:
  - `transfer(requestId, provider, client, repairReward)`
  - `flow(requestId, provider, client, pricePerSlotPerSecond)`
  - `burnAccount(requestId, provider)`
- When a slot is repaired then the repair reward is transfered to the new
  provider:
  - `transfer(requestId, client, provider, repairReward)`
- When a request fails, the entire fund is burned, including the client tokens:
  - `burnFund(requestId)`

The main downsides of this approach are:
- when the request fails, then the client also loses its tokens
- when a request ends, then everyone can withdraw directly from the vault,
  so it's not possible for the marketplace to e.g. request one final storage
  proof before allowing withdrawal

We believe that the added safety of using a time vault is important enough to
accept these downsides.

### Contract's architecture

With the contract's split, the dependencies between them will be simple. The Marketplace contract will
get the address of the Vault contract upon deployment, which it will utilize for all the funds keeping.
Codex node will not have to be bothered about Vault's existence as every fund's interaction will be proxied
through the Marketplace contract. The Codex node will have a hardcoded Marketplace contract address with which it will interact.

```
┌────────────┐     ┌──────────────────────┐     ┌────────────────┐
│            │     │                      │     │                │
│ Codex Node ├────►│ Marketplace contract ├────►│ Vault contract │
│            │     │                      │     │                │
└────────────┘     └──────────────────────┘     └────────────────┘
 ```

### Scenarios handling

With this design, three main scenarios can happen. For completeness and clarity, we will briefly describe how they
will be handled, even though they have already been described in previous chapters.

#### Normal feature upgrade

In a routine feature upgrade, a new version of the Marketplace contract will be deployed. It will utilize the original Vault contract
, which address is specified upon contract deployment. After that, the deployed contract's address is updated in the
Codex's auto contract discovery mechanism (eq., hard-coded based on the deployed chain). The old version of the Marketplace contract
will be deprecated in the Codex node implementation, which will lead to  creating all new storage requests in the new Marketplace contract
. The old Marketplace contract will be kept around only to fulfill still-running requests and allow the withdrawal of funds.
For more details about feature upgrades, see the [Feature upgrades](#feature-upgrades) section.

> [!IMPORTANT]
> Because of the tracking of the deposit owners in the Vault contract, the funds are safely separated, so multiple versions of
> Marketplace contract can utilize the same Vault contract.

#### Emergency logic upgrade

If an exploitable bug is found in the Marketplace contract, we will utilize the upgradability capability to patch
this bug. This patch will be applied using a multisig account.

This capability will allow us to fix major problems in the network without wiping it as described
in the [Freezing contract](#freezing-contract) section.

> [!WARNING]
> The multisig account will have an admin role in the network with capabilities to affect the whole network.
> Because of this, the participants in the multisig should be trusted, and the quorum should be balanced in order
> to prevent a hostile takeover while allowing timely response when needed.

> [!CAUTION]
> The multisig account will not have direct control over the funds as they will be in the safekeeping of the Vault.
> But with the current Vault design, only the controller can manipulate the funds, which in our case
> is the Marketplace contract that the multisig has control over. This is why users can withdraw funds from the
> Vault directly without interacting through the Marketplace contract.

#### Vault emergency

The most impactful bug that could be discovered would be in the Vault. If such a bug were discovered and exploited,
we would have the only possibility to permanently freez the Vault. Such an action would again originate from a multisig
account. This action would lead to a hard fork of the whole network, where a new token contract would
probably have to be deployed, and the whole community would have to coordinate around migrating to the new token contract. Most probably, a snapshot of the token distribution before the hack would be taken, and that would be used to instantiate the new
token. This situation would definitely be disruptive for the whole network, and in the future, we should look more into how this would
play out in order not to lose the data of users of the network when this happens.

> [!NOTE]
> It is a question if the multisig account used for freezing Vault should be the same multisig as the one for the
> Marketplace's emergency upgrades.

> [!WARNING]
> It is a question if _unfreezing_ should be supported. For example, It could help handle the Emergency Marketplace
> upgrades, where any funds movement could be halted until a bugfix could be applied. But then in the case of a Vault emergency
> and freezing the Vault because of problem directly with it, it would be desired to ensure that it will never be unfrozen again.
> It could be possible to implement this by giving up the admin role, where the "allowed account" to make these changes
> would be set to zero address after the freezing call.


## Resources

- [Ethereum:Smart contract security](https://ethereum.org/pcm/developers/docs/smart-contracts/security/#implement-disaster-recovery-plans)
- [OpenZeppelin: Strategies for Safer Governance systems](https://blog.openzeppelin.com/smart-contract-security-guidelines-4-strategies-for-safer-governance-systems)
- [OpenZeppelin: Timelocks](https://blog.openzeppelin.com/protect-your-users-with-smart-contract-timelocks)
