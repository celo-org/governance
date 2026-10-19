#!/usr/bin/env bash
# Fork test for CGP-0254 (approver multisig correction: Kobi Gurkan -> Eran Tromer).
#
#   0. Fork Celo mainnet via anvil. Pre-state: approver == multisig, 14 owners,
#      required 3, internalRequired 5, Kobi Gurkan (0xFD74…) is an owner, Eran
#      Tromer (0xC856…) is not.
#   1. Governance lifecycle on the EMPTY proposal (temperature check):
#      propose -> dequeue -> approve -> lock + vote YES -> execute.
#   2. Multisig correction: owner A submits replaceOwner(Kobi -> Eran) on the
#      multisig itself; B and C confirm; at 3 confirmations it is NOT executed
#      (internal threshold is 5); D and E confirm; the 5th executes it.
#   3. Post-state: Eran in, Kobi out, still 14 owners, thresholds unchanged,
#      other 13 owners unchanged.
#
# Usage:  ./test-cgp-0254.sh
# Env:    RPC_URL (default https://forno.celo.org), ANVIL_PORT (default 8562)

set -uo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
RPC_URL="${RPC_URL:-https://forno.celo.org}"
ANVIL_PORT="${ANVIL_PORT:-8562}"
RPC="http://127.0.0.1:${ANVIL_PORT}"

GOV=0xD533Ca259b330c7A88f74E000a3FaEa2d63B7972
MS=0x41822d8A191fcfB1cfcA5F7048818aCd8eE933d3
LOCKED_GOLD=0x6cC083Aed9e3ebe302A6336dBC7c921C9f03349E
PROPOSER=0x8eF439ee8F6905bfd2343668039d39eB2B77706e
KOBI=0xFD74A4b05F12B9aB6020CB202aDE1BBa4Bc99aba
ERAN=0xC85639289D4Bbb5F90e380A0f4db6B77a2F777bF
# five current owners who are not Kobi (so confirmation counts are unaffected by his removal)
SIGNERS=(0xBE0c3B35Ec3f759D9A67c4B7c539b0D5b52A4642 0x936e62E72727E47297D218c2F829ef4C36427D9A 0x5C73151A9eDcaccBD20EBB346bd4e419CdC94da3 0xC631Eb5dE231000f96F4973ca8516d487108b2BF 0x0a1c327FB17870488F12555e56A3a517e493cc46)
EXPECTED_CALLDATA=0xe20056e6000000000000000000000000fd74a4b05f12b9ab6020cb202ade1bba4bc99aba000000000000000000000000c85639289d4bbb5f90e380a0f4db6b77a2f777bf

PASS=0; FAIL=0
RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'; RESET=$'\033[0m'
ok()  { echo "  ${GREEN}PASS${RESET} $1"; PASS=$((PASS+1)); }
no()  { echo "  ${RED}FAIL${RESET} $1"; FAIL=$((FAIL+1)); }
lower() { tr '[:upper:]' '[:lower:]' <<<"$1"; }
asseq() { [[ "$(lower "$2")" == "$(lower "$3")" ]] && ok "$1" || no "$1 got=$2 want=$3"; }
ccall() { cast call --rpc-url "$RPC" "$@"; }
cval()  { ccall "$@" | awk '{print $1}'; }
csend() { cast send --rpc-url "$RPC" --unlocked --legacy --gas-price 0 "$@"; }
fund()  { cast rpc --rpc-url "$RPC" anvil_setBalance "$1" "$2" >/dev/null; }
warp()  { cast rpc --rpc-url "$RPC" anvil_increaseTime "$1" >/dev/null; cast rpc --rpc-url "$RPC" anvil_mine 1 >/dev/null; }
owners_sorted() { ccall "$MS" 'getOwners()(address[])' | tr -d '[] ' | tr ',' '\n' | tr '[:upper:]' '[:lower:]' | sort; }
is_owner() { ccall "$MS" 'isOwner(address)(bool)' "$1"; }

cleanup() { [[ -n "${ANVIL_PID:-}" ]] && kill "$ANVIL_PID" 2>/dev/null && wait "$ANVIL_PID" 2>/dev/null || true; }
trap cleanup EXIT

echo "${YELLOW}==>${RESET} anvil fork of $RPC_URL on :$ANVIL_PORT"
anvil --fork-url "$RPC_URL" --port "$ANVIL_PORT" --auto-impersonate --block-base-fee-per-gas 0 \
      >"$SCRIPT_DIR/anvil.log" 2>&1 &
ANVIL_PID=$!
for _ in $(seq 1 60); do cast block-number --rpc-url "$RPC" >/dev/null 2>&1 && break; sleep 1; done
cast block-number --rpc-url "$RPC" >/dev/null || { echo "anvil failed to start"; exit 1; }
echo "    block $(cast block-number --rpc-url "$RPC")"
fund "$PROPOSER" 0x295BE96E64066972000000
for s in "${SIGNERS[@]}"; do fund "$s" 0xDE0B6B3A7640000; done
asseq "mainnet.json is an empty array" "$(python3 -c "import json; print(json.load(open('$SCRIPT_DIR/mainnet.json')))")" "[]"
asseq "calldata == replaceOwner(Kobi, Eran)" "$(cast calldata 'replaceOwner(address,address)' $KOBI $ERAN)" "$EXPECTED_CALLDATA"

# ============================================================
echo "${YELLOW}==>${RESET} Phase 0 — pre-state"
# ============================================================
asseq "Governance.approver() == multisig" "$(ccall "$GOV" 'approver()(address)')" "$MS"
asseq "14 owners"             "$(owners_sorted | wc -l | tr -d ' ')" "14"
asseq "required == 3"         "$(cval "$MS" 'required()(uint256)')" "3"
asseq "internalRequired == 5" "$(cval "$MS" 'internalRequired()(uint256)')" "5"
asseq "Kobi Gurkan (0xFD74…) is an owner"   "$(is_owner $KOBI)" "true"
asseq "Eran Tromer (0xC856…) is NOT an owner" "$(is_owner $ERAN)" "false"
for s in "${SIGNERS[@]}"; do [[ "$(is_owner $s)" == "true" ]] || no "signer $s is not an owner"; done
OWNERS_BEFORE=$(owners_sorted)
TXCOUNT_BEFORE=$(cval "$MS" 'transactionCount()(uint256)')

# ============================================================
echo "${YELLOW}==>${RESET} Phase 1 — Governance lifecycle on the empty proposal"
# ============================================================
csend --from "$PROPOSER" --value 10000ether "$GOV" "propose(uint256[],address[],bytes,uint256[],string)" \
  "[]" "[]" "0x" "[]" "https://github.com/celo-org/governance/blob/main/CGPs/cgp-0254.md" >/dev/null && ok "propose() with zero transactions" || no "propose()"
PID=$(cval "$GOV" "proposalCount()(uint256)"); echo "    proposalId = $PID"
warp 90000
csend --from "$PROPOSER" "$GOV" "dequeueProposalsIfReady()" >/dev/null
IDX=$(python3 -c "
s='''$(ccall "$GOV" "getDequeue()(uint256[])")'''.strip('[]')
ids=[x.strip() for x in s.split(',') if x.strip()]; print(ids.index('$PID') if '$PID' in ids else -1)")
asseq "dequeued" "$([[ "$IDX" != -1 ]] && echo y || echo n)" "y"
fund "$MS" 0xDE0B6B3A7640000
csend --from "$MS" "$GOV" "approve(uint256,uint256)" "$PID" "$IDX" >/dev/null
asseq "isApproved (approver multisig, 3-of-14 path)" "$(ccall "$GOV" "isApproved(uint256)(bool)" "$PID")" "true"
warp 86400
csend --from "$PROPOSER" --value 20000000ether "$LOCKED_GOLD" "lock()" >/dev/null
csend --from "$PROPOSER" "$GOV" "vote(uint256,uint256,uint8)" "$PID" "$IDX" 3 >/dev/null && ok "vote YES (20M locked)" || no "vote"
warp 604800
asseq "isProposalPassing" "$(ccall "$GOV" "isProposalPassing(uint256)(bool)" "$PID")" "true"
csend --from "$PROPOSER" "$GOV" "execute(uint256,uint256)" "$PID" "$IDX" >/dev/null && ok "Governance.execute() of empty proposal" || no "execute()"
asseq "multisig untouched by the vote" "$(owners_sorted)" "$OWNERS_BEFORE"

# ============================================================
echo "${YELLOW}==>${RESET} Phase 2 — multisig executes replaceOwner(Kobi -> Eran) on itself"
# ============================================================
csend --from "${SIGNERS[0]}" "$MS" "submitTransaction(address,uint256,bytes)" "$MS" 0 "$EXPECTED_CALLDATA" >/dev/null && ok "owner A submits (auto-confirms)" || no "submit"
TXID=$TXCOUNT_BEFORE
asseq "new multisig txId == $TXID" "$(cval "$MS" 'transactionCount()(uint256)')" "$((TXCOUNT_BEFORE + 1))"
asseq "tx destination == multisig (internal)" "$(ccall "$MS" 'transactions(uint256)(address,uint256,bytes,bool)' $TXID | sed -n 1p)" "$MS"
asseq "tx data == replaceOwner calldata"      "$(ccall "$MS" 'transactions(uint256)(address,uint256,bytes,bool)' $TXID | sed -n 3p)" "$EXPECTED_CALLDATA"
csend --from "${SIGNERS[1]}" "$MS" "confirmTransaction(uint256)" $TXID >/dev/null
csend --from "${SIGNERS[2]}" "$MS" "confirmTransaction(uint256)" $TXID >/dev/null
asseq "3 confirmations" "$(cval "$MS" 'getConfirmationCount(uint256)(uint256)' $TXID)" "3"
asseq "NOT executed at 3 (internal threshold is 5, not required=3)" "$(ccall "$MS" 'transactions(uint256)(address,uint256,bytes,bool)' $TXID | sed -n 4p)" "false"
asseq "Kobi still owner at 3 confirmations" "$(is_owner $KOBI)" "true"
csend --from "${SIGNERS[3]}" "$MS" "confirmTransaction(uint256)" $TXID >/dev/null
asseq "NOT executed at 4" "$(ccall "$MS" 'transactions(uint256)(address,uint256,bytes,bool)' $TXID | sed -n 4p)" "false"
csend --from "${SIGNERS[4]}" "$MS" "confirmTransaction(uint256)" $TXID >/dev/null && ok "5th confirmation" || no "5th confirm"
asseq "executed at 5 confirmations" "$(ccall "$MS" 'transactions(uint256)(address,uint256,bytes,bool)' $TXID | sed -n 4p)" "true"

# ============================================================
echo "${YELLOW}==>${RESET} Phase 3 — post-state"
# ============================================================
asseq "Eran Tromer (0xC856…) is an owner"     "$(is_owner $ERAN)" "true"
asseq "Kobi Gurkan (0xFD74…) is NOT an owner" "$(is_owner $KOBI)" "false"
asseq "still 14 owners"       "$(owners_sorted | wc -l | tr -d ' ')" "14"
asseq "required still 3"      "$(cval "$MS" 'required()(uint256)')" "3"
asseq "internalRequired still 5" "$(cval "$MS" 'internalRequired()(uint256)')" "5"
EXPECTED_AFTER=$(sed "s/$(lower $KOBI)/$(lower $ERAN)/" <<<"$OWNERS_BEFORE" | sort)
asseq "owner set == before with Kobi replaced by Eran" "$(owners_sorted)" "$EXPECTED_AFTER"
asseq "Governance.approver() unchanged" "$(ccall "$GOV" 'approver()(address)')" "$MS"

echo
echo "================================="
echo "Results: ${GREEN}$PASS passed${RESET}, ${RED}$FAIL failed${RESET}"
echo "================================="
[[ "$FAIL" == 0 ]] || exit 1
