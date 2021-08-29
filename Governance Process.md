# Governance Process

![](https://i.imgur.com/ikhA3q8.png)


### Submission

Any Celo account can submit a proposal to the [Governance smart contract](https://docs.celo.org/command-line-interface/commands/governance#celocli-governance-build-proposal) to change features on Celo. Using Celo CLI, an account must send a transaction that includes the following: title, link to the proposal description in GitHub, and a deposit of 100 Celo. Once the proposal is issued on-chain, the proposals enter a queue. Each day, the top 3 proposals in the queue move on to the Approval phase. If there are fewer than three proposals in the queue, all of them may move onto the approval phase.

### Approval

If the proposal moves onto this stage, the original proposer can withdraw the 100 CELO deposit. In this phase, 3 of 9 multi-signature addresses held by individuals selected from the Celo foundation must approve the proposal within one day. If the Approvers do not approve the proposal within one day, the proposal expires.

### Referendum

In the Referendum phase, any Locked CELO holder may vote yes, no, or abstain. The more CELO locked, the more voting weight a user has.

The proposal must pass a minimum threshold for participation and agreement:

* Locked CELO holders can vote on the proposal for seven days. 

* A proposal must reach a quorum. This means a certain amount of Locked CELO needs to participate in the vote for it to be implemented. This number is dynamic and changes over time based on the participation levels of previous proposals. The quorum requirement also depends on the type of proposal introduced. These parameters are [viewable on Github](https://github.com/celo-org/celo-monorepo/blob/24c1b65cb3afafc5ff8df767d828aa8b95b702fd/packages/protocol/governanceConstitution.js).  If a proposal does not reach quorum within seven days, it is automatically rejected.

* A proposal must have a majority of "yes" votes relative to “no” votes to pass. 

### Execution

If the proposal passes the Referendum stage, it moves to the Execution phase. Any Celo account can [issue a special transaction](https://docs.celo.org/command-line-interface/commands/governance#celocli-governance-execute) that upgrades the protocol code, but the proposal creator is typically responsible for executing the proposal. If no Celo account sends the execution transaction within three days after it passes, the proposal will be automatically rejected.