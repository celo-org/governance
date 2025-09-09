# Celo Governance Repository

This is the Celo Governance repository used for coordination by the community members.

The Celo Governance Guardians *(Previously named CGP Editors)* are:
* Eric Nakagawa (@ericnakagawa)
* Celo Governance (@celogovernance)
* 0xj4an (@0xj4an-work)
* Zoz (@0xzoz)
* 0xgoldo (@0xGoldo)

Emeritus CGP Editors are:
* Ronan McGovern (@Pinotio)
* Elizabeth Barnes (@ebethbarnes)
* Yaz Khoury (@YazzyYaz)
* Chris Wilson (@calicokittencat)
* Will Kraft (@willkraft)
* Maya Richardson-Brown (@Maya-R-B)

We regularly hold governance calls to discuss proposals. 

## Historical Call Summary

Find the summary of past calls [here](https://github.com/celo-org/governance/blob/main/Call%20Log.md).



# Governance Overview
Governance is, at its core, all about how a group of people working together makes decisions. Celo has an on-chain governance mechanism for working as a community to make decisions. 

This documentation is designed for proposal creators and people interested in creating proposals, and it aims to give them the base of knowledge necessary for creating and championing a proposal. This article summarizes the most important details proposal creators should be aware of, and the following links provide additional details:
* [Governance Process](https://github.com/celo-org/governance/blob/main/Governance%20Process.md)
* [Types of Celo Governance Proposals](https://github.com/celo-org/governance/blob/main/Types%20of%20Celo%20Governance%20Proposals.md)
* [Technical Guide - Nuts & Bolts of CGP Process](https://github.com/celo-org/governance/blob/main/Technical%20Guide%20-%20Nuts%20%26%20Bolts%20of%20the%20CGP%20Process.md)


The following points summarize the key context for Celo governance:
<details>
	<summary>What is Celo Governance?</summary>

&nbsp;
Celo Governance is the structure and process that allows stakeholders to make changes to the Celo protocol or request fund from the [Celo Community Fund](https://www.celocommunityfund.xyz/).
</details>

<details>
	<summary>Why does governance matter?</summary>

&nbsp;
Governance allows anyone to shape the direction of the Celo community. This is vital for the operation and longevity of the protocol.
</details>

<details>
	<summary>Who is involved in governance?</summary>

&nbsp;
Key stakeholders in Celo’s governance process include: Proposal Creator, Celo Governance Guardians *(formerly known as 'CGP Editors')*, Approvers, Voters and Validators. See the Governance Process Roles section of this article below.
</details>

<details>
	<summary>When and where do votes happen?</summary>

&nbsp;
Discussions about changes to the protocol happen on forum.celo.org and are announced in the Celo Discord [#📢︱governance-announc channel](https://discord.gg/celo). Token holders can vote on on-chain proposals at [Celo Mondo](https://mondo.celo.org/).
</details>

<details>
	<summary>How much time is involved?</summary>

&nbsp;
Once a proposal is submitted on Github, it can be submitted on-chain along with a deposit of 10,000 CELO, and community members have 28 days to signal they’d like to vote for the proposal on-chain. It will be proposed onto the chain one day later for token holders to vote on it. After seven days, if it passes, anyone will be able to introduce it on-chain. 
</details> 

&nbsp;

## Governance Process & Steps for Proposal Creators
This is an abbreviated description of the governance process and the steps needed to move the proposal through each phase. See the [Governance Process](https://github.com/celo-org/governance/blob/main/Governance%20Process.md) and [Technical Guide](https://github.com/celo-org/governance/blob/main/Technical%20Guide%20-%20Nuts%20%26%20Bolts%20of%20the%20CGP%20Process.md) articles for more details.

These are the minimum steps needed to move a proposal through the governance process. There are several best practices that are strongly encouraged in order to ensure adequate community buy-in, and these are covered in the Best Practices for Proposal Creators section below.

<details>
	<summary>1. Create Proposal</summary>

1. Create a JSON file that would execute the changes you’re proposing if passed.
1. Create a Celo Governance Proposal *(CGP)* with a description of the changes and submit to GitHub. 
1. After submitting to GitHub, Celo Governance Guardians *(formerly known as 'CGP Editors')* will review the clarity and feasibility of the CGP and may reach out with feedback.
</details>

<details>
	<summary>2. Submission</summary>
    
1. Submit your proposal using the Celo Command Line Interface *(Celo CLI)*. This includes a 10,000 CELO deposit.
1. Locked CELO holders vote on proposals in this phase each day, and the top 3 proposals each day move on to the Approval phase.
1. If your proposal is not in the top 3 on any day for 28 days, it expires and your deposit is burned. In practice, the volume of proposals is low enough that proposals generally clear this phase *(i.e. not dozens of proposals per month)*.
</details>

<details>
	<summary>3. Approval</summary>

1. Withdraw your deposit using Celo CLI.
1. To move on from this phase, the proposal needs to be approved by the Approvers *(a 3 of 9 multi-signature address held by individuals selected by the Celo Foundation)*.
1. Approvers have 1 day to review the proposal.
1. The Approvers may reach out with questions, so be ready to communicate with them.
</details>

<details>
	<summary>4. Referendum</summary>

1. This is the main phase of the governance process, as it determines whether the community will adopt your proposal.
1. This phase is a community vote that lasts one week, and any Locked CELO holder can vote. Their votes are weighted by the number of Locked CELO they have.
</details>

<details>
	<summary>5. Execution</summary>

1. The proposal creator is generally responsible for implementing the proposal when it passes the referendum.
1. The proposal must be executed within 3 days of passing the referendum. The proposal is executed using the Celo CLI.
</details>

&nbsp;
![](https://i.imgur.com/y5Co5Y5.png)


## Best Practices for Proposal Creators
Celo governance is community-driven, and because of that, a lot of the tips below revolve around soliciting and incorporating community feedback and keeping all key stakeholders and the broader community informed and engaged throughout the process. Although individuals or small groups generally create proposals, the proposal creation process should feel less like an individual effort and more like solving a problem by working together with the broader community. To that end, we recommend following these best practices:

<details>
	<summary>1. Before Drafting a Proposal</summary>

1. **Evaluate Whether Necessary:** Before doing any work, make sure the proposal is needed and isn’t already being worked on by checking on celo.forum.org and asking on Discord. Skim through active CGP proposals and the Celo forum to ensure that the idea isn’t already being discussed or proposed and warrants its own CGP.
1. **Initial Community Feedback:** Get high-level feedback from the community to improve and gauge your idea’s support. Create a forum post summarizing your idea and share it in the [Governance Proposals section of the Celo forum](https://forum.celo.org/c/governance/governance-proposals/) to get initial feedback.
1. **Targeted Feedback:** Reach out to stakeholders who would be impacted to get their opinion. Reach out to people with established reputations in the community for feedback *(e.g. validators, cLabbers - reachable on the Discord)*, especially if the proposal would impact them. This can help build support among community members that will be helpful in later stages in the process.
</details>

<details>
	<summary>2. Drafting a Proposal</summary>

1. **Create Draft Proposal:** Make a GitHub account, create a fork in the governance repository, and draft a proposal. The CGP template can be found [here](https://github.com/celo-org/governance/blob/main/CGPs/cgp-template.md). 
1. **Get Community Feedback:** This step should be the main feedback-gathering effort and will be crucial to finalizing your draft into a version you’re confident has broad support.
    1. Post the draft proposal in the [Celo Forum](https://forum.celo.org) with the [following template](https://docs.google.com/document/d/1NVu510uye--5NcCWa4RpRrm4N4MfpNIY1OrSkQ3RfMo/edit?tab=t.0#heading=h.s2iiti5xrfrz) and get feedback on the draft from the community. The Celo Forum is the main place for discussion of governance proposals.
    1. Let people in [Discord](https://chat.celo.org/), [Celo Twitter community](https://twitter.com/CeloOrg), and [Celo Telegram groups](https://t.me/celoplatform) know about the discussion in the Celo Forum and encourage them to contribute their feedback. Consider posting in [#🗳︱governance-general](https://discord.gg/celo), channel in Discord. To reach Validators, send an update in the Celo Signal newsletter.
1. **Discuss on Governance Call:** Give people a chance to discuss the proposal in real-time by discussing the proposal on a governance call. Sign up to [Celo Signal](https://docs.celo.org/validator-guide/celo-signal) and reply to a Celo Signal email to get an item on the agenda for governance calls. This will give stakeholders a final opportunity to contribute their opinion before you submit the proposal on-chain. To ensure the conversation is as effective as possible, let all active conversations *(i.e., forum, Discord, etc.)* know about the call.
1. **Pre-Vote Outreach:** Give the community a heads up about the timing of the vote, so they’re ready when it happens.
</details>

<details>
	<summary>3. Shepherding Proposal through Voting</summary>
  
1. **Notify Community:** Engage the same groups you engaged in the pre-draft process to let them know that the vote is happening. This includes the Celo governance discord, Celo subReddit, Celo Telegram groups, validators, and other key stakeholders who the proposal would impact *(see Step 2b for the full list)*. You can use these templates to share key information about the proposal simply:
    1. [Social Media Post Template](https://docs.google.com/presentation/d/1B8NTXtTysX3tzf6RdttmN17ZwG8B47FgPgiPksJseSE/edit#slide=id.gcba387afa4_0_0)
    1. [Medium Post Template](https://docs.google.com/document/d/1QpOS--Px2ClQg6PtJSjWxWM-eRZjZmD1pO7-DBCM4yg/edit)
1. **Engage Validators:** Once voting starts, engage with validators directly via the validator channel on Discord (can use @validators to notify them) to make sure they understand the proposal, why it’s important, and when the deadline for voting is. Validators may need multiple reminders, but make sure to be respectful in your outreach.
</details>

&nbsp;
**Note:** Once a proposal is submitted on-chain, the process moves pretty quickly, so #1 and #2 above happen before the proposal is submitted on-chain.

## Governance Process Roles


<details>
	<summary>Proposal Creators</summary>

&nbsp;
Anyone with a minimum of 10,000 CELO can submit a proposal for a change to the Celo network. The proposal creator is responsible for creating the proposal, getting community buy-in, and championing the proposal throughout the process.
</details>

<details>
	<summary>Celo Governance Guardians *(formerly known as 'CGP Editors')*</summary>

&nbsp;
Celo Governance Guardians *(formerly known as 'CGP Editors')* review proposal drafts submitted on Github, either accepting pull requests or rejecting pull requests and providing feedback. This review is conducted to ensure the proposal draft conforms to the guidelines on Github. Celo Governance Guardians *(formerly known as 'CGP Editors')* are volunteer positions with ideally a majority filled by Celo community members outside of cLabs. 
</details>

<details>
	<summary>Approvers</summary>

&nbsp;
Before a proposal is voted on, it must be approved by Approvers to ensure the proposal is in the best interests of the community and that it’s worth voting on. Nominees of the Celo Foundation serve to approve proposals via a 3 of 9 multi-sig approval.
</details>

<details>
	<summary>Voters</summary>

&nbsp;
Any wallet address that owns Locked CELO is eligible to vote on governance proposals.
</details>

<details>
	<summary>Validators</summary>

&nbsp;
Validators support the proof of stake mechanism of the Celo platform by validating blocks of transactions on the network. Validators must own at least 10,000 locked CELO tokens and be elected as validators by holders of Locked CELO.	
</details>
