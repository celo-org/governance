---
cgp: 19X
title: Funding Proposal: Accelerating the Next Phase of Celo’s L2 Development
date-created: 2025-08-01
author: 'cLabs Team'
status: DRAFT
discussions-to: [https://forum.link - <URL of discussion forum>](https://forum.celo.org/t/funding-proposal-accelerating-the-next-phase-of-celo-s-l2-development/11791)
governance-proposal-id:
date-executed:
---
 
## Proposal Description
This proposal requests funding from the Celo Community Fund to support six months (July–December 2025) of core protocol development by the cLabs team as part of the ongoing Season Planning. The focus is on scaling the Celo Layer 2 through critical infrastructure upgrades, enhanced data availability, fault-proof security, and crosschain interoperability. This proposal outlines key technical milestones, updated cost estimates, and a continued commitment to transparency and milestone-based reporting. These milestones reflect those shared in the recently published [Celo L2 roadmap](https://forum.celo.org/t/celo-as-an-ethereum-l2-a-frontier-chain-for-global-impact/11376).


### **Background**

Since transitioning to an Ethereum Layer 2, Celo has entered a new phase of technical development focused on scaling the L2's throughput, improving security as well as L2Beat's rating of Celo, and adding modular capabilities. With the initial upgrade complete, the cLabs team is now focused on delivering the milestones outlined in the post-transition roadmap, including protocol upgrades and integrations with modular infrastructure like Succinct and EigenDA V2.

Following the successful L2 transition, the cLabs team successfully activated the Isthmus hardfork on Mainnet, bringing the L2 stack in line with Ethereum’s Pectra upgrade and laying the groundwork for future enhancements. Upcoming work includes the integration of EigenDA V2, the launch of a new long-lived testnet aligned with Ethereum’s Sepolia (to replace Alfajores after the Holesky sunset), and an evaluation of fast finality solutions like Espresso to improve confirmation speed and crosschain interoperability.


### **Milestones for the Next 6 Months**

|                        |                                                                                                          |                                                                                        |                          |
| :--------------------: | :------------------------------------------------------------------------------------------------------: | :------------------------------------------------------------------------------------: | :----------------------: |
|      **Milestone**     |                                               **Overview**                                               |                                    **Deliverables**                                    | **Estimated Completion** |
|    Isthmus Hardfork    |       Upgrade to incorporate Ethereum Pectra-aligned features and Holocene fault-proof improvements      | Successfully upgraded Mainnet with Isthmus features (EIPs, block header updates, etc.) |          Q3 2025         |
|   New Sepolia Testnet  |           Launch a new long-lived testnet aligned with Ethereum’s Sepolia, replacing Alfajores           |    Fully deployed Sepolia-based Celo L2 testnet with updated infra and documentation   |          Q3 2025         |
| EigenDA v2 Integration |         Integrate EigenDA Blazar to strengthen data availability and reduce confirmation latency         |                   Blazar fully integrated and operational on Mainnet                   |          Q3 2025         |
|    OP Succinct Lite    |       Integrate ZK-enabled fault-proofs (used in the event of a dispute) into the L2 security model      |                 Succinct Lite integrated and live on Mainnet or testnet                |          Q4 2025         |
|  Espresso Exploration  | Pilot integration of Espresso’s BFT-backed confirmation layer for faster finality and crosschain support |          Evaluation report and testnet demo for Espresso confirmations on Celo         |          Q4 2025         |


### **Funding Request**

To deliver on these milestone, this proposal seeks funding for the following budget line items:

|                                |                                                                                                                    |                      |
| :----------------------------: | :----------------------------------------------------------------------------------------------------------------: | :------------------: |
|        **Cost Category**       |                                                     **Details**                                                    | **Total Cost (USD)** |
| Fully Loaded Engineering Costs | 20 full-time contributors focused on core protocol development (13), devops (2), security (3), and dev tooling (2) |      $1,979,774      |
|     Infrastructure & Tools     |                                  Cloud services, testnet hosting, analytics tools                                  |        $90,000       |
|     Communications & Events    |                            Public outreach, L2 developer events, community coordination                            |        $60,000       |
|              Total             |                                                                                                                    |      $2,129,774      |

Note that cLabs will continue to self fund personnel costs related to senior management, finance, legal, people ops, and marketing as well as office, hardware, travel, and other expenses.\
\
Based on the 90-day average CELO price ($0.33 from April 17–July 15, 2025), this totals 6,453,860 CELO, distributed over six monthly installments of 1,075,643.33 CELO, subject to a two-month cliff.


### **Transparency and Accountability**

Consistent with previous cLabs funding proposals, we propose that all funds be disbursed through a ReleaseCelo smart contract with a 2-month cliff and linear vesting thereafter. If milestone commitments are not met, a governance proposal can revoke the contract and return unvested funds to the Community Fund.

Progress updates will be published on the Celo Forum and cLabs will continue to engage ecosystem stakeholders and governance participants to ensure development remains aligned with the network’s needs and Ethereum’s L2-centric scaling roadmap.\
\
**Conclusion**\
\
Together, these milestones will strengthen Celo’s Layer 2 ecosystem, enhance alignment with Ethereum, and drive continued innovation across our community.\
 
## Proposed Changes
 
Fill out the following template for each transaction in the proposal
 
1. Description of transaction 1
  - Destination: A human readable description of the address and method being called
  - Data: A human readable description of the transaction data
  - Value: How much CELO is being sent, and why?
 
## Verification
 
Before approving/voting, fetch the on-chain proposal and verify that the destination address matches the address of the ReleaseGold contract, `0x3a493665dc7a609D94b87adf0aF51bf8d2eDb3f4` and that the amount is 2,792,440 CELO, equivalent to 2792440000000000000000000 or 2.792440e24.

$ celocli governance:show --proposalID TODO -n https://forno.celo.org

Then verify that the same contract is a ReleaseGold contract with parameters that match the proposal:

$ celocli releasecelo:show --contract 0x3a493665dc7a609D94b87adf0aF51bf8d2eDb3f4 -n https://forno.celo.org

In particular check these parameters:
 
## Risks
 
Highlight any risks and concerns that may affect consensus, proof-of-stake, governance, protocol economics, the stability protocol, security, and privacy.
 
## Useful Links
 
* Optional section
* Links to related CIPs or other documents (eg. if this is a proposal to point to a new instance of a smart contract that was updated)
