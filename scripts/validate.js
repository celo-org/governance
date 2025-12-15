import fs from "fs";
import path from "path";
import { micromark } from "micromark";
import { gfmTable, gfmTableHtml } from "micromark-extension-gfm-table";
import {
  ProposalMetadataStatus,
  ProposalMetadataSchema,
  separateYamlFrontMatter,
  validateDate,
} from "./cgp-utils.js";

const CGP_FOLDER = "./CGPs";
const CGP_FOLDER_REGEX = /^cgp-(\d+)$/;
const CGP_FILENAME_REGEX = /^cgp-(\d+)\.md$/;
const CGP_TEMPLATE_FILENAME = "cgp-template.md";

const proposalIds = new Set();

function validateCGPs() {
  console.log("Validating CGPs");

  const directoryContents = fs.readdirSync(CGP_FOLDER);

  for (const fileOrDir of directoryContents) {
    console.log(`Validating ${fileOrDir}`);
    const stat = fs.statSync(path.join(CGP_FOLDER, fileOrDir));
    if (stat.isDirectory()) {
      validateCgpFolder(fileOrDir);
    } else if (stat.isFile()) {
      validateCgpFile(fileOrDir);
    } else {
      throw new Error(`Unknown CGP file type: ${file}`);
    }
  }

  console.log("Done validating CGPs");
}

function validateCgpFolder(pathName) {
  // For now, simply validating the folder name
  // May add more validation here in the future, such as JSON parsing
  if (!CGP_FOLDER_REGEX.test(pathName)) {
    throw new Error(`Invalid CGP folder: ${pathName}`);
  }
}

function validateCgpFile(fileName) {
  if (fileName === CGP_TEMPLATE_FILENAME) return;

  if (!CGP_FILENAME_REGEX.test(fileName)) {
    throw new Error(`Invalid CGP filename: ${fileName}`);
  }

  const fileContent = fs.readFileSync(path.join(CGP_FOLDER, fileName), "utf8");
  if (!fileContent?.trim()) {
    throw new Error(`CGP content is empty: ${fileName}`);
  }

  const fileParts = separateYamlFrontMatter(fileContent);
  const { frontMatter, body } = fileParts;
  validateFrontMatter(frontMatter, fileName);
  markdownToHtml(body, fileName);
}


function validateFrontMatter(data, filename) {
  try {
    const parsed = ProposalMetadataSchema.parse(data);
    const {
      status,
      "governance-proposal-id": proposalId,
      "date-created": dateCreated,
      "date-executed": dateExecuted,
    } = parsed;
    if (
      ![
        ProposalMetadataStatus.DRAFT,
        ProposalMetadataStatus.WITHDRAWN,
      ].includes(status) &&
      !proposalId
    ) {
      throw new Error(`Proposal ID required for non-draft CGPs`);
    }

    if (proposalIds.has(proposalId)) {
      throw new Error(`Proposal ID already in use in another CGP`);
    } else if (proposalId){
      proposalIds.add(proposalId);
    }

    if (dateCreated) validateDate(dateCreated);
    if (dateExecuted) validateDate(dateExecuted);
  } catch (error) {
    console.error("Error validating front matter", error);
    throw new Error(`Error validating front matter: ${filename}`);
  }
}


function markdownToHtml(body, filename) {
  try {
    // Attempt conversion from markdown to html
    return micromark(body, {
      extensions: [gfmTable()],
      htmlExtensions: [gfmTableHtml()],
    });
  } catch (error) {
    console.error("Error converting markdown", error);
    throw new Error(`Error converting markdown: ${filename}`);
  }
}

validateCGPs();
