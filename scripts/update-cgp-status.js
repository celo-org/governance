import fs from "fs";
import path from "path";
import { stringify as stringifyYaml } from "yaml";
import {
  ProposalMetadataStatus,
  separateYamlFrontMatter,
  validateCGPStatus,
} from "./cgp-utils.js";
import { validateCGPStatusUpdate } from "./onchain-validation.js";

const CGP_FOLDER = "./CGPs";

/**
 * Finds a CGP file by its CGP number
 * @param {number} cgpNumber - CGP number (e.g., 100 for cgp-0100.md)
 * @returns {Object} Object containing filePath, fileName, and content
 */
function findCGPByCGPNumber(cgpNumber) {
  const paddedNumber = String(cgpNumber).padStart(4, '0');
  const fileName = `cgp-${paddedNumber}.md`;
  const filePath = path.join(CGP_FOLDER, fileName);

  if (!fs.existsSync(filePath)) {
    throw new Error(`CGP file not found: ${fileName}`);
  }

  const content = fs.readFileSync(filePath, "utf8");

  // Verify the cgp number in front matter matches
  const { frontMatter } = separateYamlFrontMatter(content);
  if (frontMatter.cgp !== cgpNumber) {
    throw new Error(`CGP number mismatch: file ${fileName} has cgp: ${frontMatter.cgp} in front matter`);
  }

  return { filePath, fileName, content };
}

/**
 * Updates the front matter of a CGP file
 * @param {string} filePath - Path to the CGP file
 * @param {Object} updates - Object containing the fields to update
 * @returns {Object} The updated front matter
 */
function updateCGPFrontMatter(filePath, updates) {
  const content = fs.readFileSync(filePath, "utf8");
  const { frontMatter, body } = separateYamlFrontMatter(content);

  // Update the front matter
  const updatedFrontMatter = { ...frontMatter, ...updates };

  // Convert front matter back to YAML
  const updatedYaml = stringifyYaml(updatedFrontMatter, {
    lineWidth: 0, // Don't wrap lines
    defaultKeyType: 'PLAIN',
    defaultStringType: 'PLAIN',
  });

  // Reconstruct the file
  const updatedContent = `---\n${updatedYaml}---\n${body}`;

  // Write back to file
  fs.writeFileSync(filePath, updatedContent, "utf8");

  return updatedFrontMatter;
}

/**
 * Validates a date string in YYYY-MM-DD format
 * @param {string} dateString - The date string to validate
 * @throws {Error} If the date is invalid
 */
function validateDate(dateString) {
  if (!dateString) return true;
  const regex = /^\d{4}-\d{2}-\d{2}$/;
  if (!regex.test(dateString)) {
    throw new Error(`Invalid date format: ${dateString}. Expected YYYY-MM-DD`);
  }
  const date = new Date(dateString);
  if (isNaN(date.getTime())) {
    throw new Error(`Invalid date: ${dateString}`);
  }
  return true;
}

/**
 * Main function to update CGP status
 * @param {number} cgpNumber - CGP number (e.g., 100 for cgp-0100.md)
 * @param {string} status - CGPStatus (DRAFT, PROPOSED, EXECUTED, EXPIRED, WITHDRAWN, REJECTED)
 * @param {number|null} onchainId - On-chain proposal ID to set as governance-proposal-id (optional for WITHDRAWN)
 * @param {string|undefined} dateExecuted - Date in YYYY-MM-DD format (only used if status is EXECUTED)
 * @param {string} [rpcUrl] - Optional RPC URL for onchain validation
 * @param {boolean} [dryRun=false] - If true, perform validation but don't write changes
 */
export async function updateCGPStatus(cgpNumber, status, onchainId, dateExecuted, rpcUrl, dryRun = false) {
  if (dryRun) {
    console.log(`\n🔍 DRY RUN MODE - No changes will be written\n`);
  }

  console.log(`\nUpdating CGP ${cgpNumber}`);
  console.log(`Status: ${status}`);
  console.log(`On-chain ID: ${onchainId || 'N/A'}`);
  console.log(`Date Executed: ${dateExecuted || 'N/A'}`);

  // Validate inputs
  if (typeof cgpNumber !== 'number' || cgpNumber < 1) {
    throw new Error(`Invalid cgpNumber: ${cgpNumber}. Must be a positive number`);
  }

  validateCGPStatus(status);

  // WITHDRAWN and DRAFT don't require onchainId
  if (status !== ProposalMetadataStatus.WITHDRAWN && status !== ProposalMetadataStatus.DRAFT) {
    if (typeof onchainId !== 'number' || onchainId < 1) {
      throw new Error(`Invalid onchainId: ${onchainId}. Must be a positive number for ${status} status`);
    }
  }

  if (dateExecuted) {
    validateDate(dateExecuted);
  }

  // Find the CGP file
  const cgpFile = findCGPByCGPNumber(cgpNumber);
  console.log(`Found CGP file: ${cgpFile.fileName}`);

  // Perform on-chain validation
  console.log(`\nPerforming on-chain validation...`);
  await validateCGPStatusUpdate(cgpNumber, status, onchainId, rpcUrl);
  console.log(`✓ On-chain validation passed\n`);

  // Prepare updates
  const updates = {
    status: status,
  };

  // Only add governance-proposal-id if provided (not for WITHDRAWN without ID)
  if (onchainId) {
    updates["governance-proposal-id"] = onchainId;
  }

  // Only add date-executed if status is EXECUTED and dateExecuted is provided
  if (status === ProposalMetadataStatus.EXECUTED && dateExecuted) {
    updates["date-executed"] = dateExecuted;
  }

  // Update the file (or just show what would be updated in dry-run mode)
  if (dryRun) {
    console.log(`\n📋 Changes that would be applied:`);
    console.log(`File: ${cgpFile.fileName}`);
    console.log(`Updates:`, updates);

    const content = fs.readFileSync(cgpFile.filePath, "utf8");
    const { frontMatter } = separateYamlFrontMatter(content);
    const wouldBeFrontMatter = { ...frontMatter, ...updates };

    console.log(`\n--- Current Front Matter ---`);
    console.log(stringifyYaml(frontMatter));
    console.log(`--- Would Become ---`);
    console.log(stringifyYaml(wouldBeFrontMatter));

    console.log(`\n✓ Dry run complete - no changes written`);

    return {
      file: cgpFile.fileName,
      updates,
      dryRun: true,
    };
  } else {
    const updatedFrontMatter = updateCGPFrontMatter(cgpFile.filePath, updates);

    console.log(`✓ Successfully updated ${cgpFile.fileName}`);
    console.log(`New front matter:`, updatedFrontMatter);

    return {
      file: cgpFile.fileName,
      updates,
    };
  }
}

// CLI usage
if (process.argv.length >= 4) {
  const args = process.argv.slice(2);

  // Check for --dry-run flag
  const dryRunIndex = args.indexOf('--dry-run');
  const dryRun = dryRunIndex !== -1;
  if (dryRun) {
    args.splice(dryRunIndex, 1); // Remove the flag from args
  }

  const cgpNumber = parseInt(args[0], 10);
  const status = args[1];
  const onchainId = args[2] ? parseInt(args[2], 10) : null;
  const dateExecuted = args[3];
  const rpcUrl = process.env.RPC_URL; // Optional: can be set via environment variable

  updateCGPStatus(cgpNumber, status, onchainId, dateExecuted, rpcUrl, dryRun)
    .then(() => {
      console.log(dryRun ? '\n✓ Dry run complete!' : '\n✓ Update complete!');
      process.exit(0);
    })
    .catch((error) => {
      console.error(`\n✗ Error: ${error.message}`);
      process.exit(1);
    });
} else {
  console.log(`Usage: node update-cgp-status.js <cgpNumber> <status> [onchainId] [dateExecuted] [--dry-run]`);
  console.log(`  cgpNumber: CGP number (e.g., 100 for cgp-0100.md)`);
  console.log(`  status: One of DRAFT, PROPOSED, EXECUTED, EXPIRED, WITHDRAWN, REJECTED`);
  console.log(`  onchainId: On-chain governance proposal ID (optional for WITHDRAWN)`);
  console.log(`  dateExecuted: YYYY-MM-DD (optional, only used if status is EXECUTED)`);
  console.log(`  --dry-run: Perform validation but don't write changes (optional)`);
  console.log(`\nExamples:`);
  console.log(`  node update-cgp-status.js 100 EXECUTED 136 2023-09-23`);
  console.log(`  node update-cgp-status.js 100 EXECUTED 136 2023-09-23 --dry-run`);
  console.log(`  node update-cgp-status.js 100 WITHDRAWN`);
  console.log(`\nEnvironment Variables:`);
  console.log(`  RPC_URL: Custom RPC endpoint (default: https://forno.celo.org)`);
  process.exit(1);
}
