Title: Mento reserve: Return a combination of cUSD and CELO (Revised)

Authors: Luuk Weber and Roman Croessmann

### Executive Summary

This proposal aims to utilize a share of the 95M CELO to be returned to the Community
Treasury to mint cUSD to the Celo Community Treasury. The Mento Reserve will mint
10,000,000 cUSD in exchange for the equivalent value of CELO using the 30-day moving
average price on January 22nd, 2024, using CoinGecko’s price feeds. The remaining
81,633,000 CELO will be sent to the Celo Community Treasury at a later stage through a
separate proposal. This minting of cUSD will grant the Celo Community Treasury a significant
amount of stablecoins for operations, increase the distribution of cUSD, and increase the
stability of CELO, which the Mento reserve also benefits from.

### Motivation

The [Celo Community Treasury](https://celoscan.io/address/0xD533Ca259b330c7A88f74E000a3FaEa2d63B7972) has primarily held and distributed CELO tokens to proposals. Relying on CELO for operations has some downsides for the Community Treasury. Most grantees need to convert their CELO to stablecoins at some point to pay for operations, resulting in increased CELO sales pressures. Also, because CELO’s price fluctuates, it is harder to account for and estimate budgets.

  

Following the passing of [CGP102](https://celo.stake.id/?#/proposal/102), Mento started the process of returning a total of 120M CELO it received from the Genesis Block to Bootstrap the cUSD reserve. An initial 25M was sent back to the Celo Community Treasury, leaving 95M to be returned.

  

This proposal aims to utilize a share of the 95M CELO to be returned to mint cUSD to be able to send a combination of cUSD and CELO to the Celo Community Treasury.

  

By having the Mento reserve return a combination of cUSD and CELO instead of purely CELO, the Celo Community Treasury can gain a significant amount of stablecoins, increase the distribution of cUSD, and increase the stability of CELO, which Mento reserve also benefits from.

### Specifications

Following [CGP102](https://celo.stake.id/?#/proposal/102) and the initial transfer of 25M CELO from the Mento Reserve to the Celo Community Treasury, there is a total of 95M CELO left to be sent from the Mento Reserve to the Celo Community Treasury.

  

To determine the suitable value cUSD to be sent to the Community Treasury, we made a complete overview of the [Celo Community Treasury spending to date](https://forum.celo.org/t/celo-community-proposals-and-treasury-overview-apr-2020-nov-2023/), analyzed the current outstanding payments, and [simulated reserve parameters](https://docs.google.com/spreadsheets/d/1C7AynpmqsY8zL-M8jZw6mbIMkj5JC21Zr-WWGwhI5wI/edit?usp=sharing) required for the Mento Reserve to remain in excellent condition and ensure the stability of cStables.

  

Based on these data points, we believe a transfer of 10,000,000 (ten million) cUSD to be the correct amount. Depending on the spending patterns of the Celo Community Treasury, this amount would ensure between 14 and 24 months of stablecoin runway.

### Action Plan

The step-by-step process for completing this transfer would look as follows:

-   After completing the analysis and running final simulations, an equivalent value of non-stablecoin assets from the Mento Reserve (ETH and BTC) would be sold and converted to Stablecoins to add to the Mento Reserve to maintain the 100% stablecoin backing that Mento utilizes for all cStables including the 10,000,000 cUSD to be minted.  
      
    
-   The Mento Reserve will mint 10,000,000 cUSD to the Celo Community Treasury.  
      
    
-   13.367.000,00 CELO, the equivalent value of 10,000,000 cUSD using the 30-day moving average price on January 22nd, 2024, using CoinGecko’s price feeds is subtracted from the remaining 95M CELO.  
      
    
-   Send the LP tokens of the reserve-owned Curve USD pool from the Governance Proxy to the Reserve Proxy  
      
    
-   The reserve mandate is following from the above and [CGP150](https://celo.stake.id/#/proposal/150) as follows - goals in order of priority):
    

-   Keep 1:1 backing of cUSD and cBRL in USDC and DAI (USDC and DAI equally weighted)
    
-   Keep 1:1 backing of cEUR in EUROC and stEUR (at 75% and 25% weight respectively)
    
-   Keep a 50/50 allocation in BTC and ETC
    
-   Keep CELO in the reserve as a passive allocation that is not actively traded unless it is required for satisfying the goals above
    

  

Description  
Below is an overview of the transactions associated with this section.
    
1.  Mint 10,000,000 cUSD to the Celo Governance contract
    
2.  Transfer curve LP tokens from the Governance contract to the Mento Reserve
    

### Risk Considerations

Minting an additional 10,000,000 cUSD will decrease the overall Reserve Ratio to
approximately 3.51. This means each cStable would still be backed by over triple the value. As
long as the share of Stablecoin collateral equals or is larger than the outstanding amount of
cStables, which is currently the case, the new Reserve Ratio should not lead to significant
additional risks for cStable users.

##### Useful Links

-   [CGP 102: Mento Reserve Returning CELO](https://celo.stake.id/?#/proposal/102)
    
-   [Simulation - Mento Reserve Returning cUSD and CELO](https://docs.google.com/spreadsheets/d/1C7AynpmqsY8zL-M8jZw6mbIMkj5JC21Zr-WWGwhI5wI/edit?usp=sharing)
    
-   [Celo Reserve Website](https://celoreserve.org/)
