import { createPublicClient, http } from 'viem';
import { celo } from 'viem/chains';
import { ProposalMetadataStatus, ProposalStage } from './cgp-utils.js';

// Celo Governance contract address (mainnet)
const Addresses = {
  Governance: '0xD533Ca259b330c7A88f74E000a3FaEa2d63B7972', // Celo Governance Proxy
};

// Minimal Governance ABI with just the functions we need
const governanceABI = [
  {
    inputs: [{ name: 'proposalId', type: 'uint256' }],
    name: 'getProposalStage',
    outputs: [{ name: '', type: 'uint8' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [{ name: 'proposalId', type: 'uint256' }],
    name: 'getProposal',
    outputs: [
      { name: 'proposer', type: 'address' },
      { name: 'deposit', type: 'uint256' },
      { name: 'timestamp', type: 'uint256' },
      { name: 'transactionCount', type: 'uint256' },
      { name: 'descriptionUrl', type: 'string' },
      { name: 'networkWeight', type: 'uint256' },
      { name: 'approved', type: 'bool' },
    ],
    stateMutability: 'view',
    type: 'function',
  },
  {
    anonymous: false,
    inputs: [{ indexed: true, name: 'proposalId', type: 'uint256' }],
    name: 'ProposalExecuted',
    type: 'event',
  },
];

/**
 * Creates a viem public client for Celo
 */
function createCeloClient(rpcUrl = 'https://forno.celo.org') {
  return createPublicClient({
    chain: celo,
    transport: http(rpcUrl),
  });
}

/**
 * Extracts CGP number from description URL
 * @param {string} descriptionUrl - The description URL from on-chain proposal
 * @returns {number|null} The CGP number or null if not found
 */
function extractCGPNumberFromUrl(descriptionUrl) {
  // Common patterns:
  // - https://github.com/celo-org/governance/blob/main/CGPs/cgp-0100.md
  // - https://github.com/celo-org/governance/CGPs/cgp-0100.md
  // - cgp-0100.md
  const match = descriptionUrl.match(/cgp-0*(\d+)\.md/i);
  return match ? parseInt(match[1], 10) : null;
}

/**
 * Validates that the onchain proposal matches the CGP number
 * @param {object} client - Viem public client
 * @param {number} cgpNumber - CGP number
 * @param {number} onchainId - On-chain proposal ID
 * @param {bigint} [blockNumber] - Optional block number for historical queries
 * @returns {Promise<object>} Validation result with proposal data
 */
export async function validateProposalMatchesCGP(client, cgpNumber, onchainId, blockNumber) {
  const result = blockNumber
    ? await client.readContract({
        abi: governanceABI,
        address: Addresses.Governance,
        functionName: 'getProposal',
        args: [BigInt(onchainId)],
        blockNumber,
      })
    : await client.readContract({
        abi: governanceABI,
        address: Addresses.Governance,
        functionName: 'getProposal',
        args: [BigInt(onchainId)],
      });

  const [proposer, deposit, timestamp, transactionCount, descriptionUrl, networkWeight, approved] =
    result;

  const urlCGPNumber = extractCGPNumberFromUrl(descriptionUrl);

  if (urlCGPNumber !== cgpNumber) {
    throw new Error(
      `CGP number mismatch: On-chain proposal ${onchainId} has descriptionUrl "${descriptionUrl}" ` +
        `which references CGP ${urlCGPNumber || 'unknown'}, but you are trying to update CGP ${cgpNumber}`
    );
  }

  return {
    proposer,
    deposit,
    timestamp,
    transactionCount,
    descriptionUrl,
    networkWeight,
    approved,
  };
}

/**
 * Validates PROPOSED status
 * @param {object} client - Viem public client
 * @param {number} onchainId - On-chain proposal ID
 * @returns {Promise<number>} The on-chain stage
 */
export async function validateProposedStatus(client, onchainId) {
  const onChainStage = await client.readContract({
    abi: governanceABI,
    address: Addresses.Governance,
    functionName: 'getProposalStage',
    args: [BigInt(onchainId)],
  });

  const validStages = [ProposalStage.Queued, ProposalStage.Referendum, ProposalStage.Execution];

  if (!validStages.includes(onChainStage)) {
    const stageName = Object.keys(ProposalStage).find((key) => ProposalStage[key] === onChainStage);
    throw new Error(
      `Invalid stage for PROPOSED status: proposal ${onchainId} is in stage ${stageName || onChainStage}. ` +
        `Expected one of: Queued, Referendum, or Execution`
    );
  }

  return onChainStage;
}

/**
 * Validates EXECUTED status by checking for ProposalExecuted event
 * @param {object} client - Viem public client
 * @param {number} onchainId - On-chain proposal ID
 * @returns {Promise<object>} Event data including block number and transaction hash
 */
export async function validateExecutedStatus(client, onchainId) {
  // Search for ProposalExecuted events in chunks of 50,000 blocks
  // Try up to 4 times, going backwards from the current block
  const currentBlock = await client.getBlockNumber();
  const CHUNK_SIZE = BigInt(50000);
  const MAX_ATTEMPTS = 4;

  for (let attempt = 0; attempt < MAX_ATTEMPTS; attempt++) {
    const toBlock = currentBlock - (BigInt(attempt) * CHUNK_SIZE);
    const fromBlock = toBlock - CHUNK_SIZE + BigInt(1);

    console.log(`Searching for ProposalExecuted event in blocks ${fromBlock} to ${toBlock} (attempt ${attempt + 1}/${MAX_ATTEMPTS})`);

    const events = await client.getLogs({
      address: Addresses.Governance,
      event: {
        type: 'event',
        name: 'ProposalExecuted',
        inputs: [{ indexed: true, name: 'proposalId', type: 'uint256' }],
      },
      args: {
        proposalId: BigInt(onchainId),
      },
      fromBlock,
      toBlock,
    });

    if (events.length > 0) {
      // Return the first (should be only) event
      const event = events[0];
      return {
        blockNumber: event.blockNumber,
        transactionHash: event.transactionHash,
        blockHash: event.blockHash,
      };
    }
  }

  // If we've searched 4 chunks (200,000 blocks) and found nothing, give up
  throw new Error(
    `No ProposalExecuted event found for proposal ${onchainId} in the last ${MAX_ATTEMPTS * 50000} blocks. ` +
      `The proposal may not be executed yet.`
  );
}

/**
 * Validates that an EXECUTED proposal is not being overwritten
 * @param {object} client - Viem public client
 * @param {number} onchainId - On-chain proposal ID
 * @param {string} newStatus - The new status being set
 * @returns {Promise<void>}
 */
export async function validateNotOverwritingExecuted(client, onchainId, newStatus) {
  const onChainStage = await client.readContract({
    abi: governanceABI,
    address: Addresses.Governance,
    functionName: 'getProposalStage',
    args: [BigInt(onchainId)],
  });

  if (onChainStage === ProposalStage.Executed && newStatus !== ProposalMetadataStatus.EXECUTED) {
    throw new Error(
      `Cannot overwrite EXECUTED status: proposal ${onchainId} is already executed on-chain. ` +
        `You cannot change its status to ${newStatus}.`
    );
  }
}

/**
 * Main validation function
 * @param {number} cgpNumber - CGP number
 * @param {string} status - New status (DRAFT, PROPOSED, EXECUTED, etc.)
 * @param {number|null} onchainId - On-chain proposal ID (can be null for WITHDRAWN/DRAFT)
 * @param {string} [rpcUrl] - Optional RPC URL
 * @returns {Promise<object>} Validation results
 */
export async function validateCGPStatusUpdate(cgpNumber, status, onchainId, rpcUrl) {
  const client = createCeloClient(rpcUrl);

  // WITHDRAWN and DRAFT don't require onchain validation
  if (status === ProposalMetadataStatus.WITHDRAWN || status === ProposalMetadataStatus.DRAFT) {
    console.log(`No on-chain validation required for ${status} status`);
    return { validated: true };
  }

  // All other statuses except WITHDRAWN and DRAFT require onchainId
  if (!onchainId) {
    throw new Error(`onchainId is required for ${status} status`);
  }

  // For EXECUTED status, we need to find the event first, then query proposal data from before execution
  if (status === ProposalMetadataStatus.EXECUTED) {
    // First, find the ProposalExecuted event
    const eventData = await validateExecutedStatus(client, onchainId);
    console.log(`✓ Found ProposalExecuted event at block ${eventData.blockNumber}`);

    // Query the proposal data 50 blocks before execution (when it was still on-chain)
    const queryBlock = eventData.blockNumber - BigInt(50);
    console.log(`Querying proposal data at block ${queryBlock} (50 blocks before execution)`);
    const proposalData = await validateProposalMatchesCGP(client, cgpNumber, onchainId, queryBlock);
    console.log(`✓ Proposal ${onchainId} matches CGP ${cgpNumber}: ${proposalData.descriptionUrl}`);

    return { validated: true, executionEvent: eventData };
  }

  // For EXPIRED status, proposal might not be on-chain anymore
  if (status === ProposalMetadataStatus.EXPIRED) {
    try {
      const proposalData = await validateProposalMatchesCGP(client, cgpNumber, onchainId);
      console.log(`✓ Proposal ${onchainId} matches CGP ${cgpNumber}: ${proposalData.descriptionUrl}`);

      // Check we're not overwriting an executed proposal
      await validateNotOverwritingExecuted(client, onchainId, status);
      console.log(`✓ Not overwriting executed proposal`);
    } catch (error) {
      // If proposal is not found or has empty descriptionUrl, it might have expired and been removed
      console.log(`⚠ Could not validate proposal on-chain (may have expired): ${error.message}`);
      console.log(`✓ Proceeding with EXPIRED status (proposal data not available on-chain)`);
    }
    return { validated: true };
  }

  // For non-EXECUTED/EXPIRED statuses, validate proposal matches CGP at current block
  const proposalData = await validateProposalMatchesCGP(client, cgpNumber, onchainId);
  console.log(`✓ Proposal ${onchainId} matches CGP ${cgpNumber}: ${proposalData.descriptionUrl}`);

  // Validate not overwriting executed - NO status can overwrite EXECUTED
  await validateNotOverwritingExecuted(client, onchainId, status);
  console.log(`✓ Not overwriting executed proposal`);

  // Status-specific validation
  if (status === ProposalMetadataStatus.PROPOSED) {
    const stage = await validateProposedStatus(client, onchainId);
    const stageName = Object.keys(ProposalStage).find((key) => ProposalStage[key] === stage);
    console.log(`✓ Proposal is in valid stage for PROPOSED: ${stageName}`);
    return { validated: true, stage };
  }

  // REJECTED has no additional validation beyond matching CGP and not overwriting EXECUTED
  console.log(`✓ Validation complete for ${status} status`);
  return { validated: true };
}
