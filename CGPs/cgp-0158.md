---
cgp: 157
title: Enhancing Ecosystem Security Through Subsidized Services
date-created: 2024-12-02
author: "Benjamin Speckien (benjamin.speckien@clabs.co), Nikolaos Frestis (nikolaos.frestis@clabs.co), Stefan Ioja (stefan.ioja@clabs.co)" 
status: DRAFT 
discussions-to: https://forum.celo.org/t/celo-ecosystem-security-services-program-enhancing-ecosystem-security-through-subsidized-services
governance-proposal-id: 
date-executed: 
---
 
## Overview 
 
- CGP - Celo Governance Proposal 0157  
 
### Status 

- DRAFT = Feedback collection

### Proposal Description
An initiative to subsidize the cost of security services for Celo ecosystem partners. This will involve collaboration with leading security vendors to provide on-chain monitoring, automated security testing, brand protection, security architecture reviews, anti-money laundering (AML) compliance, and software supply chain security. We aim to leverage industry-leading practices and provide tools that empower partners to adopt and improve their security postures, reducing the risk of exploits that could impact the broader ecosystem.

Funding Request: 768,500 Celo ( $580,000 at 90 day average of celo:usd on 12/05/2024 = .675 )
 
## Background
 
Every security incident in our ecosystem directly impacts CELO token value, degrades users’ trust, makes mainstream adoption more difficult, and gives ammunition to crypto skeptics. These impacts ripple through every project building on Celo.

Traditional security reviews often exceed $150,000 per project, forcing most teams building on Celo to choose between proper security and core development. This isn’t just about individual projects, it’s about protecting Celo’s entire ecosystem value.

This initiative transforms security from a luxury into a standard feature of building on Celo and aims to:

Make enterprise-grade security services accessible to Celo ecosystem projects
Reduce the financial barrier to implementing robust security measures
Protect user funds and maintain ecosystem trust
Enable projects to focus resources on development while maintaining security

 
## Milestones & Verfication
 
Phase 1: Program Setup (Q1 2025)
   - Program infrastructure setup
   - Security vendor onboarding
   - Application process launch
   - Community awareness campaign

Phase 2: Initial Partner Enrollment (Q1-Q2 2025)
   - First batch of partner applications
   - Initial security assessments
   - Service implementation begins
   - First monthly report publication

Phase 3: Full Program Operation (Q2-Q4 2025)
   - Continuation of partner onboarding
   - Service delivery and monitoring
   - Monthly reporting and community updates
   - Mid-program assessment and adjustments

Phase 4: Evaluation and Planning (Q4 2025)
   - Program impact assessment
   - Community feedback collection
   - Sustainability planning
   - Renewal proposal preparation


Key Performance Indicators:
   - Number of Partners Onboarded: Successfully onboard at least 10 partners within the first three months.
   - Reduction in Vulnerabilities: Reduction in the number of vulnerabilities identified by scanning tools by 30% by the end of the project.
   - Competitive Bug Bounty Participation: At least 20 bug bounty submissions, with 5 critical vulnerabilities addressed.
   - Partner Satisfaction: Gather feedback from partners; aim for an average satisfaction score of 7/10 or higher.
   - Security Maturity: Increase in overall security maturity scores from a scale of 1 to 5 for at least 70% of the participating projects, with a target of moving projects from an average score of 2 to an average score of 4 by the end of the program.

## Proposed Changes
### Transactions
   - Unique Transaction Approval of 768,500 cUSD to Multisign ```0x35ff861a0b6215CeC71EA282B0D32AfefA661795```
   -  Initial transfer: 384,250 Celo (Upon approval)
   -  Second transfer: 384,250 Celo (End of H1 2025, subject to milestone completion)

Expenditure Breakdown ( amounts in cUSD )
   - Smart Contract, Wallet, and WebApp Security Review	120,000
   - Brand Protection	50,000
   - Attack Surface Monitoring	45,000
   - Secrets Managment	45,000
   - Supply Chain Security	45,000
   - Secure Deployment Workflows	45,000
   - Static/Dynamic Security Testing	40,000
   - Competitive Bug Bounty Program	150,000
   - Security Program Review	30,000
   - Program Administration	10,000
   - Total	580,000 cUSD


### Json Script
```
[
    {
      "contract": "GoldToken",
      "address": "0x471EcE3750Da237f93B8E339c536989b8978a438",
      "function": "increaseAllowance",
      "args": [
        "0x35ff861a0b6215CeC71EA282B0D32AfefA661795"
        "580000000000000000000000000"
      ],
      "value": "0"
    }
]
```

## Verification
A human readable version of this proposal can be found using the following command (on-chain ID determined after submission):

`$ celocli governance:show --proposalID TBD --node https://forno.celo.org`




## Risks
 
Security controls may not improve security posture at maxiumum efficiency.

CELO equals total grant (contract sends 1 CELO when beneficiary registers a vote signing key)
Risks.

All unused funds will be returned to the community fund. 

This proposal does not deploy or upgrade contracts or change network parameters so represent minimal risk to the network.

This proposal does transfer funds from the Community Fund. The major risk is an incorrect destination address that would leave the funds in the wrong account, or an incorrect releaseOwner on the ReleaseGold account. So long as those are correct, if any other parameter is incorrect, the contract can be revoked, the funds returned, and the grant reissued.

 
## Useful Links
 [Celo Forum Post](https://forum.celo.org/t/celo-ecosystem-security-services-program-enhancing-ecosystem-security-through-subsidized-services/9360)

