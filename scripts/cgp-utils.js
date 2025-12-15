import { parse as parseYaml } from "yaml";
import { z } from "zod";

// The enum of possible statuses for a CGP (off-chain)
export const ProposalMetadataStatus = {
  DRAFT: "DRAFT",
  PROPOSED: "PROPOSED",
  EXECUTED: "EXECUTED",
  EXPIRED: "EXPIRED",
  REJECTED: "REJECTED",
  WITHDRAWN: "WITHDRAWN",
};

// ProposalStage enum from on-chain contract
export const ProposalStage = {
  None: 0,
  Queued: 1,
  // DEPRECATED: Approval stage exists in the on-chain Solidity enum but getProposalStage() never returns it.
  // The approval process happens during Referendum/Execution stages and is tracked via proposal.approved boolean.
  // We keep this enum value (2) to maintain alignment with the Solidity contract enum values.
  // If somehow displayed in UI, treat it like Execution stage (awaiting execution after approval).
  Approval: 2,
  Referendum: 3,
  Execution: 4,
  Expiration: 5,
  // NOTE: solidity enum ends here
  // Below are off-chain only stages (not in Solidity contract):
  Executed: 6,
  Withdrawn: 7,
  Rejected: 8,
};

/**
 * The schema as used in the CGP front matter
 */
export const DateString = z.string().regex(/^\d{4}-\d{2}-\d{2}$/);

export const ProposalMetadataSchema = z
  .object({
    cgp: z.number().min(1),
    title: z.string().min(1),
    author: z.string().min(1),
    status: z.nativeEnum(ProposalMetadataStatus),
    "date-created": DateString.optional().or(z.null()),
    "discussions-to": z.string().url().optional().or(z.null()),
    "governance-proposal-id": z.number().min(1).optional().or(z.null()),
    "date-executed": DateString.optional().or(z.null()),
  })
  .strict();

/**
 * Separates YAML front matter from markdown content
 * @param {string} content - The full file content
 * @returns {Object} Object containing frontMatter, body, frontMatterString, and fullMatch
 */
export function separateYamlFrontMatter(content) {
  const frontMatterRegex = /^---\s*\n([\s\S]*?)\n---\s*\n/;
  const match = content.match(frontMatterRegex);
  if (!match) throw new Error("No YAML front matter found");

  try {
    const frontMatterString = match[1];
    const frontMatter = parseYaml(frontMatterString);
    const body = content.slice(match[0].length);
    const fullMatch = match[0];
    return { frontMatter, body, frontMatterString, fullMatch };
  } catch (error) {
    console.error("Error parsing YAML front matter", error);
    throw new Error(`Error parsing front matter`);
  }
}

/**
 * Validates a date string in YYYY-MM-DD format
 * @param {string} value - The date string to validate
 * @throws {Error} If the date is invalid
 */
export function validateDate(value) {
  const date = new Date(value);
  if (date instanceof Date && !isNaN(date.getTime())) return;
  throw new Error(`Invalid date: ${value}`);
}

/**
 * Validates CGP status
 * @param {string} status - The status to validate
 * @throws {Error} If the status is invalid
 */
export function validateCGPStatus(status) {
  const validStatuses = Object.values(ProposalMetadataStatus);
  if (!validStatuses.includes(status)) {
    throw new Error(`Invalid status: ${status}. Must be one of: ${validStatuses.join(', ')}`);
  }
  return true;
}
