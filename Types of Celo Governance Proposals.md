# Types of Celo Governance Proposals
### Governable Parameter Changes
#### Purpose of Parameter Change Proposals 
Celo parameter change proposals control all parameters of the core contracts. Parameter change proposals enable the community to vote to enact changes to Celo Core Contracts. For example, these proposals could change the number of active validators during each epoch or raise the penalty for validator downtime.

#### Sub-Categories
See the complete list of parameters that can and cannot be changed via governance [here](https://docs.celo.org/celo-owner-guide/governance-cheat-sheet#governable-parameters).



### New Stablecoin Proposals
#### Purpose of Adding Stablecoins to Celo
Celo benefits from having stablecoins that are selected and supported by the wider community.

#### Requirements
1. _Liquidity_: The token itself has to be traded against CELO in a CELO/X ticker, where X is the asset the stablecoin’s value would be based on. If it cannot be traded against CELO, it must be traded against another, well-known asset that has the ability to be traded 24/7, including weekends. The goal is that the price of X in respect to Celo can be inferred or understood. 
2. _Pre-Mint Addresses and Amounts Must Be Determined_: It is possible to pre-mint a fixed amount of cX at the time of launching cX. The community fund, the foundation, and other entities that are dedicated to distributing tokens in the form of grants or bounties are good recipients of tokens of cX during the pre-mint process.

A good criterion to decide a pre-mint amount is to check how much it would affect the reserve collateralization ratio. The collateralization ratio is all the stable assets divided by all the reserve holdings. Reserve information, as well as collateralization ratios, can be found on the [Reserve website](https://celoreserve.org/).

#### Procedure
Currently, the addition of new assets is tied to the [Contract Release Cycle](https://docs.celo.org/community/release-process/smart-contracts), so check in with cLabs developers when adding a stablecoin to the network. These new contracts inherit from Exchange and StableToken contracts, which are the contracts originally used for cUSD. As stablecoin cX will be initialized by the contract release, key parameters like spread and ReserveFraction should be included, although they can be later modified by setters through a governance proposal. The only value that can't be changed after release is the pre-mint amount.

##### Freezing
These contracts should be set as frozen to prevent cX from being transferable before Mento supports it in a governance proposal. At this point, as there are no oracles, the contract ExchangeX can't update buckets and it is thus impossible to mint and burn cX. There is [an issue open](https://github.com/celo-org/celo-monorepo/issues/7331) to include this step as part of the Contract Release.
For the [deployment of cEUR](https://github.com/celo-org/celo-proposals/blob/master/CGPs/0023.md), this freezing was included as part of the Oracle activation proposal.

#### Constitutional Parameters
As new contracts are added to the registry, new [constitution parameters](https://docs.celo.org/developer-guide/sdk-code-reference/summary-2/classes/_wrappers_governance_.governancewrapper#isproposalpassing) need to be set. There's an [issue open](https://github.com/celo-org/celo-monorepo/issues/7318) to including this in the tooling to support it as part of the Contract Release.

#### Oracle Activation
Before fully activating cX, the proposer has to produce at least one oracle report. This is required by the Reserve contract in [this line](https://github.com/celo-org/celo-monorepo/blob/9b43d07b35c9d50389f5f2f53ddfa0c21f16d0f2/packages/protocol/contracts/stability/Reserve.sol#L223). After reporting, it is worth double-checking that the bucket sizes on StableTokenX are consistent with values reported and it is a good opportunity to test the oracle setup in production with no funds at risk, as the contracts involved are still frozen.

#### Full Activation
The last governance proposal is expected to unfreeze the contract and attach the last strings in the process to get a fully transferable asset stabilized by the Reserve. This propose involves:
1. Unfreezing both StableTokenX & ExchangeX.
2. Making ExchangeX able to pull CELO out of the Reserve for the buckets Reserve.addExchangeSpender
3. Declaring the token to the Reserve as an asset to be stabilized calling Reserve.addToken
4. Enable StableTokenX as a fee currency, so that it can be used to pay for gas FeeCurrencyWhitelist.addToken.
5. In case necessary, parameters such as reserveFraction and spread can also be updated in this governance proposal.
After passing this last proposal, cX should be fully activated.

#### Special Considerations for adding Stablecoins Proposals
Adding a new stable asset involves updating many parts of the tooling, such as:
* Updating the Ledger app integration such that it displays the names of the newly added token.
* Updating oracles and generating their keys and addresses.
* Adding support on contractkit.
* Adding support on [kliento](https://github.com/celo-org/kliento).
* Adding support on [eksportisto](https://github.com/celo-org/eksportisto).
* Update on the cli - an example list of things to add are included on [this issue](https://github.com/celo-org/celo-monorepo/issues/6793).
* Supporting alfajores faucet.
* Supporting on Dapp kit.

### On-Chain Community Fund
#### Purpose of On-chain Community Fund Proposals
On-Chain Community Fund proposals reward and incentivise behaviours that benefit the Celo ecosystem. 

#### Sub-Categories
On-Chain Community Fund proposals may vary in objective and scope, exemplified by the following sub-categories:
* _Seed Funding_: One might propose a structure for providing seed funding to new protocols or tokens on the Celo ecosystem.
* _Community Rewards_: A program of small monetary rewards might be proposed to recognize contributions of community members that may not be recognized with existing incentives or market systems.
* _Marketing_: A program to incentivize the development of educational or marketing materials for the Celo ecosystem.

#### Special Considerations for On-chain Community Fund Proposals
To maximize chances of approval, it is important that disbursement proposals be aligned with the interests of those voting (i.e. CELO holders). It is therefore recommended that disbursement proposals:
1. Direct incentives and rewards specifically toward benefiting the CELO ecosystem, as opposed to other ecosystems. Note that providing support for bridges across ecosystems (e.g. CELO <> Ethereum) may well be seen as a benefit for the CELO ecosystem.
2. Should align with the [mission of Celo](https://celo.org/community), and the Celo Governance Proposal should explain why it aligns with the mission and impacts the community positively.
3. Lay out clearly where funding will come from, e.g. from the on-chain community fund reserve.
4. Lay out who will control the distribution of funding - ideally specifying the public key(s) that will control this decision.

#### Clarification on On-Chain Community Funds vs Celo Foundation Grants
On-chain Community Fund disbursements, as described in this section, are implemented via Celo Governance Proposals (CGPs) and paid from the on-chain treasury of Celo’s Community Fund. This is distinct from Celo Foundation Grants, which are approved by a grant committee at cLabs, a non-profit, and paid from Celo Foundation Funds, as well as from any other “community fund programs”, that are also approved via separate committee and paid from their respective entities. So, while there can be high overlap in the purpose of On-chain Community Funds and Celo Foundation Grants, the authorization and financial support for each is different. This overlap and the promotion of the On-chain Community Fund is to be reviewed in a working group in late 2021.

As of July 2021, the On-chain Community Fund and the [Celo Community Fund](https://celocommunityfund.org/) (which was funded by a disbursement from the On-chain Community Fund) have the following focus areas:
1. _On/Off Ramps_: CELO/fiat or cUSD/fiat CLOB exchange pairs, fiat-to-crypto software, P2P platforms, wallet integrations, point-of-sale integrations, e-commerce integrations, etc.
2. _Community Tools_: Desktop/browser/hardware wallets, developer tools, governance voting applications, block explorers, validator metrics dashboards, etc.
3. _Research_: Support people and projects that want to conduct research. This can include both technical and non-technical areas relevant to Celo.
4. _Education_: Create educational content, host Celo-related talks. We are also open to considering other great teams/projects that might be beneficial to Celo’s mission/ecosystem.

### General Governance Proposals and Changes
This section is a broad category of actions that affect Celo governance but don’t touch anything on-chain (like parameters). These include changes like community suggestions, processes, and best practices.

Governance is, at its core, all about how a group of people working together make decisions. Not everything that the Celo community decides involves a change to the blockchain, but the community still needs a consistent way to make decisions. That’s what this section on General Governance changes is all about: it covers the kinds of decisions the community makes that don’t necessarily don't involve the blockchain.

### Purpose of General Governance Proposals and Changes
Even though Celo’s governance is primarily on-chain, off-chain changes to governance can have a fairly significant impact on the Celo network. That's because there are things that the community does that aren’t necessarily enforced by the way the blockchain works but nonetheless shape the outcomes that the community attains.

#### Sub-Categories
Because General Governance is a broad catch-all category, the list below isn’t exhaustive, but it describes some of the main kinds of changes that fall under the General Governance umbrella.
* _Community Suggestion_: This is an idea from somebody in the community about something that doesn’t necessarily affect any code, like the name of a hard fork.
* _Process Change_: These are changes to the general process for governance that happen off-chain, like changing the Celo Governance Proposal template.
* _Best Practice_: These are changes to the things that people should do to ensure everyone’s voice is heard when a governance decision is made. For example, this could include a change to where or how many discussions happen during a CGP lifecycle.
In practice, the lines between the sub-categories above are relatively blurred, which is why this is a catch-all category.

#### Special Considerations for General Governance Proposals & Other Changes
* _Community Feedback_: All General Governance changes should be run by the community in some form to ensure community buy-in. At a minimum, it’s helpful to have an online community discussion (such as in the Celo forum) and a discussion in a Celo governance call to ensure people have a way to voice their opinion.
* _CGP Optional_: These kinds of changes don't necessarily need a proposal, but they can be helpful for transparency. In general, the more significant a change is, the more helpful it is to make the change through the proposal process.
