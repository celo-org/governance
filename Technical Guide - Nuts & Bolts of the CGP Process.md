# Technical Guide: Nuts & Bolts of the CGP Process

This article explains the minimum steps you should take at each stage in the governance process. There are several best practices that go beyond these minimum steps in order to ensure alignment with the community. Those best practices can be found in the *Best Practices for Proposal Creators* section of the [Governance Overview Article](https://github.com/celo-org/governance/blob/main/README.md).

## Creating & Submitting a Proposal
**Creating a Governance Proposal**

&nbsp;Creating a governance proposal involves creating two documents:
1. JSON File
2. Celo Governance Proposal

*JSON File*

&nbsp;
When a governance proposal passes, the Celo network runs a list of methods to implement the changes that are proposed. The parameters used in those methods are specified in a JSON file—this file is the list of method calls that would be made if the proposal passes *(See an example JSON file [here](https://github.com/celo-org/celo-proposals/blob/master/CGPs/0024/mainnet.json))*. To ensure your JSON file is not buggy, you can message the #​​general-core in Discord to ask someone to review the file.

Each transaction step *(or method call)* should include the following parameters:
- **Transaction Number**: This is the index of the transaction in the list, so it’s not actually listed.  Transactions will run in order.
- **Contract**: The contract with the desired function call for the transaction.
- **Function**: The function in the above contract that will be called.
- **Args**: Arguments that will be passed as the parameters to the above function.
- **Params**: For parameter changes, `Params` will be the same as `Args`.
- **Value**: The value of native token transferred with the transaction.

Here’s an example:
> [
{
  "contract": "BlockchainParameters",
  "function": "setBlockGasLimit",
  "args": ["130000000"],
  "value": "0"
}
]

**Note:** A JSON file is only needed for on-chain changes. Some governance proposals - such as General Governance Proposals and Changes - don’t affect the Celo blockchain *(e.g. changing name from Celo Gold to CELO)*.

*Celo Governance Proposal*

&nbsp;In addition to creating the JSON file, you should create a Celo Governance Proposal *(CGP)* using the [CGP Template](https://github.com/celo-org/governance/blob/main/CGPs/cgp-template.md) and submit a pull request in the Celo Governance repo. Make sure to include enough detail that anybody who’s reasonably knowledgeable about Celo can understand why the proposal is needed and what the proposal will do. When submitted, the CGP Editors will review and may reach out to you with feedback to incorporate. When your CGP pull request has been merged, submit a post in the [Governance section](https://forum.celo.org/c/governance/12) of the Celo forum to allow the community to comment on it. It’s also helpful to include the JSON file in the Github repo as well so others can review—you can create a folder in the top level of the repo named for the CGP number and put the file in it.

**Testing a Governance Proposal**

&nbsp;When a Governance Proposal intends to change smart contract parameters, a CGP should be tested on Alfajores and Baklava Testnet before proposing on mainnet. This ensures that the testnets keep up to date with mainnet and that your parameter changes work as intended. Testing has been mostly done by cLabs so far. You can ask on #general-core or #celo-governance on Discord to find out who can help you.

**Submitting a Governance Proposal**

&nbsp;Your proposal consists of the JSON file *(if required)* and a Celo Governance Proposal.

Before actually submitting the proposal, the community should have sufficient time to discuss in the forum, and you should have discussed the proposal on a governance call. See the Best Practices for Proposal Creators section of the ==
== for all best practices for championing a proposal.

When you’re ready to submit your proposal, send an email to governance@celo.org *(Governance Approvers)* letting them know when you will submit your proposal. You should do this no more than three days before submitting the proposal. The goal of this is to give the Approvers a heads-up so they can plan to evaluate the proposal when it gets to the Approval stage.

Governance proposals are submitted through the Celo Command Line Interface (CLI) using the
>$ celocli governance:propose

command. See [here](https://docs.celo.org/command-line-interface/introduction) to get started with Celo CLI.

This command has several parameters:
- **deposit** The amount of Celo to attach to Celo as a deposit. All amounts are given as wei, i.e units of 10^-18 CELO. For example, 1 CELO = 1000000000000000000. The minimum deposit is 10,000 CELO.
- **descriptionURL**: A URL where people can go to learn more about the proposal. In general, this should be the link to the CGP already merged into main celo-org/governance repo.
- **from**: Your address
- **jsonTransactions**: The path to the JSON file containing all of the transactions that are involved in the proposal.

Here’s an example:
> propose --jsonTransactions ./transactions.json --deposit 10000000000000000000000 --from 
YourAddres --descriptionURL
https://github.com/celo-org/governance/blob/main/CGPs/cgp-XXXX.md

## Submission Stage
Submitted proposals are added to a queue of proposals in the Submission stage. While a proposal is on this queue, voters may use their Locked Celo to upvote the proposal. Once per day, the top three proposals—by weight of the Locked Celo upvoting them—are dequeued and moved into the Approval phase. If a proposal has been on the queue for more than 4 weeks, it expires and the deposit is burned.

- What should I do if my proposal gets enough upvotes to move to the Approval stage?
    - Your proposal will automatically move on to the next stage. There’s nothing you need to do to move it on.
- What should I do if my proposal doesn’t get enough upvotes and expires?
    - As of July 2021, it’s unlikely that a proposal won’t make it past this stage. Unless there are dozens of proposals submitted around the same time, the proposal will almost surely be in the top three in terms of upvotes on one day in the 4 weeks after you submit, which would move it to the next stage. If your proposal does fail to move beyond the Submission stage, there’s nothing you need to do—you just won’t get your deposit back.

## Approval Stage
Once your proposal reaches the Approval stage, you can withdraw your deposit using
> celocli governance:withdraw.

In this phase, the proposal needs to be approved by the Approvers *(a 3 of 9 multi-signature address held by individuals selected by the Celo Foundation)*. The Approval phase lasts 1 day, and if the proposal is not approved in this window, it is considered expired and does not move on to the Referendum phase. The Approvers may reach out with questions, so be ready to communicate with them.

- What should I do if my proposal is approved?
    - If your proposal is approved, it will automatically move on to the Referendum stage.
- What should I do if my proposal is not approved?
     - If your proposal is not approved, you may receive feedback from the Approvers. You can incorporate this feedback and then re-submit the proposal if you’d like.

# Referendum Stage
In the referendum phase, which lasts five days, any user with Locked Celo may vote Yes, No, or Abstain on the proposal.

- What should I do if my proposal passes?
     - Once your proposal passes, you have 3 days to execute the proposal. See the Execution Stage  section below.
- What should I do if my proposal does not pass?
     - If your proposal does not pass the Referendum stage, there’s nothing you need to do.

# Execution Stage
The proposal creator is responsible for executing a proposal once it passes the referendum. In order to execute the proposal, use
> celocli governance:execute

in the Celo Command Line Interface.

If you don’t execute the proposal within 3 days, you lose the ability to execute the proposal and would need to go through the governance process again *(i.e. resubmit proposal)* in order to regain the ability to execute.
