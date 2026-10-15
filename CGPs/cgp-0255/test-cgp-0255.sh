#!/usr/bin/env bash
# Fork test for CGP-0255 (set Governance hotfixExecutionTimeWindow to 24h).
#
#   0. Fork Celo mainnet via anvil. Assert window == 0 and that prepareHotfix
#      reverts with "Hotfix execution time window not set" EVEN AFTER both the
#      approver multisig and the Security Council have approved the hash
#      (i.e. the hotfix path is closed today, not merely tight).
#   1. Full Governance lifecycle on the single mainnet.json tx:
#      propose -> dequeue -> approve -> lock + vote YES -> execute.
#   2. Assert window == 86400 and HotfixExecutionTimeWindowSet(86400) emitted.
#   3. Replay the hotfix flow on the fork:
#      - random address cannot approve; prepare needs both approvals
#      - approver + Security Council approve; prepare sets limit = now + 86400
#      - executeHotfix passes at exactly limit (>=), reverts at limit + 1
#      - resetHotFixRecord clears a lapsed record
#
# Usage:  ./test-cgp-0255.sh
# Env:    RPC_URL (default https://forno.celo.org), ANVIL_PORT (default 8560)

set -uo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CGP_JSON="$SCRIPT_DIR/mainnet.json"

RPC_URL="${RPC_URL:-https://forno.celo.org}"
ANVIL_PORT="${ANVIL_PORT:-8560}"
RPC="http://127.0.0.1:${ANVIL_PORT}"

GOV=0xD533Ca259b330c7A88f74E000a3FaEa2d63B7972
APPROVER=0x41822d8A191fcfB1cfcA5F7048818aCd8eE933d3
SECURITY_COUNCIL=0x51a3a77baF58fef0309452CeaCB09221e556f223
LOCKED_GOLD=0x6cC083Aed9e3ebe302A6336dBC7c921C9f03349E
PROPOSER=0x8eF439ee8F6905bfd2343668039d39eB2B77706e
RANDO=0x000000000000000000000000000000000000C0fe

EXPECTED_CALLDATA=0x745407c80000000000000000000000000000000000000000000000000000000000015180
TOPIC_WINDOW_SET=$(cast keccak "HotfixExecutionTimeWindowSet(uint256)")
TOPIC_HOTFIX_EXECUTED=$(cast keccak "HotfixExecuted(bytes32)")

PASS=0; FAIL=0
RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'; RESET=$'\033[0m'
ok()  { echo "  ${GREEN}PASS${RESET} $1"; PASS=$((PASS+1)); }
no()  { echo "  ${RED}FAIL${RESET} $1"; FAIL=$((FAIL+1)); }
lower() { tr '[:upper:]' '[:lower:]' <<<"$1"; }
asseq() { [[ "$(lower "$2")" == "$(lower "$3")" ]] && ok "$1" || no "$1 got=$2 want=$3"; }

ccall() { cast call --rpc-url "$RPC" "$@"; }
cval()  { ccall "$@" | awk '{print $1}'; }   # strip cast's "[8.64e4]" annotation
csend() { cast send --rpc-url "$RPC" --unlocked --legacy --gas-price 0 "$@"; }
fund()  { cast rpc --rpc-url "$RPC" anvil_setBalance "$1" "$2" >/dev/null; }
warp()  { cast rpc --rpc-url "$RPC" anvil_increaseTime "$1" >/dev/null; cast rpc --rpc-url "$RPC" anvil_mine 1 >/dev/null; }
set_next_ts() { cast rpc --rpc-url "$RPC" anvil_setNextBlockTimestamp "$1" >/dev/null; }

# expect_revert <label> <reason-substring> <cast call args...>
expect_revert() {
  local label="$1" reason="$2"; shift 2
  local out; out=$(ccall "$@" 2>&1)
  if grep -q "$reason" <<<"$out"; then ok "$label"; else no "$label: expected revert '$reason', got: $out"; fi
}
# expect_send_revert <label> <reason-substring> <cast send args...>
expect_send_revert() {
  local label="$1" reason="$2"; shift 2
  local out; out=$(csend "$@" 2>&1)
  if grep -q "$reason" <<<"$out"; then ok "$label"; else no "$label: expected revert '$reason', got: $out"; fi
}
# has_log <txhash> <topic0> [<data-uint>]
has_log() {
  cast receipt --rpc-url "$RPC" --json "$1" | python3 -c "
import json,sys
r=json.load(sys.stdin); t=sys.argv[1].lower(); want=sys.argv[2] if len(sys.argv)>2 and sys.argv[2] else None
for l in r['logs']:
    if l['address'].lower()=='$(lower "$GOV")' and l['topics'][0].lower()==t:
        if want is None: sys.exit(0)
        if int(l['data'],16)==int(want): sys.exit(0)
sys.exit(1)" "$2" "${3:-}"
}
# record <hash> -> approved councilApproved executed executionTimeLimit (space separated)
record() { ccall "$GOV" "getHotfixRecord(bytes32)(bool,bool,bool,uint256)" "$1" | awk '{print $1}' | tr '\n' ' '; }
now_ts() { cast block --rpc-url "$RPC" latest --json | python3 -c "import json,sys; print(int(json.load(sys.stdin)['timestamp'],16))"; }

cleanup() { [[ -n "${ANVIL_PID:-}" ]] && kill "$ANVIL_PID" 2>/dev/null && wait "$ANVIL_PID" 2>/dev/null || true; }
trap cleanup EXIT

echo "${YELLOW}==>${RESET} anvil fork of $RPC_URL on :$ANVIL_PORT"
anvil --fork-url "$RPC_URL" --port "$ANVIL_PORT" --auto-impersonate --block-base-fee-per-gas 0 \
      >"$SCRIPT_DIR/anvil.log" 2>&1 &
ANVIL_PID=$!
for _ in $(seq 1 60); do cast block-number --rpc-url "$RPC" >/dev/null 2>&1 && break; sleep 1; done
cast block-number --rpc-url "$RPC" >/dev/null || { echo "anvil failed to start"; exit 1; }
echo "    block $(cast block-number --rpc-url "$RPC")"
for a in "$PROPOSER" "$APPROVER" "$SECURITY_COUNCIL" "$RANDO"; do fund "$a" 0x295BE96E64066972000000; done  # 50M each

# ---- mainnet.json -> calldata ----------------------------------------------
read -r TX_TO TX_FN TX_ARG TX_VAL < <(python3 -c "
import json; t=json.load(open('$CGP_JSON')); assert len(t)==1, 'expected exactly 1 tx'
print(t[0]['address'], t[0]['function'], t[0]['args'][0], t[0]['value'])")
CALLDATA=$(cast calldata "$TX_FN(uint256)" "$TX_ARG")
asseq "mainnet.json target is Governance"        "$TX_TO" "$GOV"
asseq "mainnet.json value is 0"                   "$TX_VAL" "0"
asseq "mainnet.json calldata matches CGP text"    "$CALLDATA" "$EXPECTED_CALLDATA"
CD_LEN=$(( (${#CALLDATA} - 2) / 2 ))

# ---- hotfix payload used in phases 0 and 3: idempotent self-call ----------
# values=[0] destinations=[GOV] data=setHotfixExecutionTimeWindow(86400) lengths=[36]
hotfix_hash() { ccall "$GOV" "getHotfixHash(uint256[],address[],bytes,uint256[],bytes32)(bytes32)" "[0]" "[$GOV]" "$CALLDATA" "[$CD_LEN]" "$1"; }
exec_hotfix() { csend --from "$RANDO" "$GOV" "executeHotfix(uint256[],address[],bytes,uint256[],bytes32)" "[0]" "[$GOV]" "$CALLDATA" "[$CD_LEN]" "$1" "${@:2}"; }

# ============================================================
echo "${YELLOW}==>${RESET} Phase 0 — pre-state: hotfix path is closed"
# ============================================================
asseq "hotfixExecutionTimeWindow == 0"            "$(cval "$GOV" 'hotfixExecutionTimeWindow()(uint256)')" "0"
asseq "Governance.owner() == Governance"          "$(ccall "$GOV" 'owner()(address)')" "$GOV"
asseq "Governance.approver() == approver multisig" "$(ccall "$GOV" 'approver()(address)')" "$APPROVER"
asseq "Governance.securityCouncil() == L2 alias"  "$(ccall "$GOV" 'securityCouncil()(address)')" "$SECURITY_COUNCIL"

SALT0=$(cast keccak "cgp-0255-phase0")
H0=$(hotfix_hash "$SALT0")
expect_revert "prepareHotfix reverts for anyone (no approvals)" "Hotfix execution time window not set" \
  --from "$RANDO" "$GOV" "prepareHotfix(bytes32)" "$H0"
csend --from "$APPROVER"         "$GOV" "approveHotfix(bytes32)" "$H0" >/dev/null && ok "approver approves H0" || no "approver approve H0"
csend --from "$SECURITY_COUNCIL" "$GOV" "approveHotfix(bytes32)" "$H0" >/dev/null && ok "Security Council approves H0" || no "SC approve H0"
asseq "H0 record: approved, councilApproved, !executed, limit 0" "$(record "$H0")" "true true false 0 "
expect_revert "prepareHotfix STILL reverts with both approvals (path closed, not tight)" "Hotfix execution time window not set" \
  --from "$APPROVER" "$GOV" "prepareHotfix(bytes32)" "$H0"
expect_revert "executeHotfix reverts (never prepared)" "Execution time limit has already been reached" \
  --from "$RANDO" "$GOV" "executeHotfix(uint256[],address[],bytes,uint256[],bytes32)" "[0]" "[$GOV]" "$CALLDATA" "[$CD_LEN]" "$SALT0"

# ============================================================
echo "${YELLOW}==>${RESET} Phase 1 — Governance lifecycle: propose -> dequeue -> approve -> vote -> execute"
# ============================================================
csend --from "$PROPOSER" --value 10000ether "$GOV" "propose(uint256[],address[],bytes,uint256[],string)" \
  "[0]" "[$GOV]" "$CALLDATA" "[$CD_LEN]" \
  "https://github.com/celo-org/governance/blob/main/CGPs/cgp-0255.md" >/dev/null && ok "propose()" || no "propose()"
PID=$(ccall "$GOV" "proposalCount()(uint256)" | awk '{print $1}')
echo "    proposalId = $PID"
asseq "proposal queued" "$(ccall "$GOV" "isQueued(uint256)(bool)" "$PID")" "true"

warp 90000
csend --from "$PROPOSER" "$GOV" "dequeueProposalsIfReady()" >/dev/null
IDX=$(python3 -c "
s='''$(ccall "$GOV" "getDequeue()(uint256[])")'''.strip('[]')
ids=[x.strip() for x in s.split(',') if x.strip()]; print(ids.index('$PID') if '$PID' in ids else -1)")
asseq "dequeued" "$([[ "$IDX" != -1 ]] && echo y || echo n)" "y"
echo "    dequeue index = $IDX"

csend --from "$APPROVER" "$GOV" "approve(uint256,uint256)" "$PID" "$IDX" >/dev/null
asseq "isApproved" "$(ccall "$GOV" "isApproved(uint256)(bool)" "$PID")" "true"

warp 86400
csend --from "$PROPOSER" --value 20000000ether "$LOCKED_GOLD" "lock()" >/dev/null
csend --from "$PROPOSER" "$GOV" "vote(uint256,uint256,uint8)" "$PID" "$IDX" 3 >/dev/null && ok "vote YES (20M locked)" || no "vote"
echo "    vote totals: $(ccall "$GOV" "getVoteTotals(uint256)(uint256,uint256,uint256)" "$PID" | tr '\n' ' ')"

warp 604800
asseq "isProposalPassing" "$(ccall "$GOV" "isProposalPassing(uint256)(bool)" "$PID")" "true"
EXEC_TX=$(csend --from "$PROPOSER" --json "$GOV" "execute(uint256,uint256)" "$PID" "$IDX" \
  | python3 -c "import json,sys; r=json.load(sys.stdin); assert r['status']=='0x1','execute reverted'; print(r['transactionHash'])") \
  && ok "Governance.execute()" || no "Governance.execute()"

# ============================================================
echo "${YELLOW}==>${RESET} Phase 2 — post-state"
# ============================================================
asseq "hotfixExecutionTimeWindow == 86400" "$(cval "$GOV" 'hotfixExecutionTimeWindow()(uint256)')" "86400"
has_log "$EXEC_TX" "$TOPIC_WINDOW_SET" 86400 && ok "HotfixExecutionTimeWindowSet(86400) emitted" || no "HotfixExecutionTimeWindowSet event missing"
asseq "approver unchanged"         "$(ccall "$GOV" 'approver()(address)')" "$APPROVER"
asseq "securityCouncil unchanged"  "$(ccall "$GOV" 'securityCouncil()(address)')" "$SECURITY_COUNCIL"

# ============================================================
echo "${YELLOW}==>${RESET} Phase 3 — hotfix flow now works"
# ============================================================
# 3a. H0 (approved in phase 0, never prepared) can now be prepared + executed.
csend --from "$RANDO" "$GOV" "prepareHotfix(bytes32)" "$H0" >/dev/null && ok "prepareHotfix(H0) passes (approvals from before the CGP carry over)" || no "prepareHotfix(H0)"
LIMIT0=$(record "$H0" | awk '{print $4}')
asseq "H0 limit == now + 86400" "$LIMIT0" "$(( $(now_ts) + 86400 ))"
expect_revert "prepareHotfix(H0) twice reverts" "Hotfix already prepared" --from "$RANDO" "$GOV" "prepareHotfix(bytes32)" "$H0"
warp 3600
EX0=$(exec_hotfix "$SALT0" --json | python3 -c "import json,sys; r=json.load(sys.stdin); assert r['status']=='0x1'; print(r['transactionHash'])") \
  && ok "executeHotfix(H0) at +1h" || no "executeHotfix(H0) at +1h"
has_log "$EX0" "$TOPIC_HOTFIX_EXECUTED" && ok "HotfixExecuted emitted" || no "HotfixExecuted missing"
asseq "H0 executed" "$(record "$H0" | awk '{print $3}')" "true"
expect_revert "executeHotfix(H0) twice reverts" "hotfix already executed" \
  --from "$RANDO" "$GOV" "executeHotfix(uint256[],address[],bytes,uint256[],bytes32)" "[0]" "[$GOV]" "$CALLDATA" "[$CD_LEN]" "$SALT0"

# 3b. H1: approval gating, execute at exactly limit.
SALT1=$(cast keccak "cgp-0255-phase3-h1"); H1=$(hotfix_hash "$SALT1")
expect_revert "random address cannot approveHotfix" "msg.sender not approver or Security Council" --from "$RANDO" "$GOV" "approveHotfix(bytes32)" "$H1"
expect_revert "prepareHotfix(H1) needs approver" "Hotfix not approved by approvers" --from "$RANDO" "$GOV" "prepareHotfix(bytes32)" "$H1"
csend --from "$APPROVER" "$GOV" "approveHotfix(bytes32)" "$H1" >/dev/null
expect_revert "prepareHotfix(H1) needs Security Council" "Hotfix not approved by security council" --from "$RANDO" "$GOV" "prepareHotfix(bytes32)" "$H1"
csend --from "$SECURITY_COUNCIL" "$GOV" "approveHotfix(bytes32)" "$H1" >/dev/null
csend --from "$RANDO" "$GOV" "prepareHotfix(bytes32)" "$H1" >/dev/null && ok "prepareHotfix(H1) with both approvals" || no "prepareHotfix(H1)"
LIMIT1=$(record "$H1" | awk '{print $4}')
set_next_ts "$LIMIT1"
exec_hotfix "$SALT1" >/dev/null && ok "executeHotfix(H1) at exactly limit (block.timestamp == limit)" || no "executeHotfix(H1) at limit"
asseq "block.timestamp == limit" "$(now_ts)" "$LIMIT1"

# 3c. H2: lapses at limit + 1, then reset.
SALT2=$(cast keccak "cgp-0255-phase3-h2"); H2=$(hotfix_hash "$SALT2")
csend --from "$APPROVER"         "$GOV" "approveHotfix(bytes32)" "$H2" >/dev/null
csend --from "$SECURITY_COUNCIL" "$GOV" "approveHotfix(bytes32)" "$H2" >/dev/null
expect_revert "resetHotFixRecord(H2) before prepare reverts" "hotfix not prepared" --from "$RANDO" "$GOV" "resetHotFixRecord(bytes32)" "$H2"
csend --from "$RANDO" "$GOV" "prepareHotfix(bytes32)" "$H2" >/dev/null
LIMIT2=$(record "$H2" | awk '{print $4}')
expect_revert "resetHotFixRecord(H2) before limit reverts" "hotfix execution time limit not reached" --from "$RANDO" "$GOV" "resetHotFixRecord(bytes32)" "$H2"
set_next_ts "$(( LIMIT2 + 1 ))"
expect_send_revert "executeHotfix(H2) at limit + 1s reverts" "Execution time limit has already been reached" \
  --from "$RANDO" "$GOV" "executeHotfix(uint256[],address[],bytes,uint256[],bytes32)" "[0]" "[$GOV]" "$CALLDATA" "[$CD_LEN]" "$SALT2"
cast rpc --rpc-url "$RPC" anvil_mine 1 >/dev/null   # consume the pending timestamp if the revert did not mine
csend --from "$RANDO" "$GOV" "resetHotFixRecord(bytes32)" "$H2" >/dev/null && ok "resetHotFixRecord(H2) after lapse" || no "resetHotFixRecord(H2)"
asseq "H2 record cleared (both approvals + limit)" "$(record "$H2")" "false false false 0 "
expect_revert "prepareHotfix(H2) after reset needs fresh approvals" "Hotfix not approved by approvers" --from "$RANDO" "$GOV" "prepareHotfix(bytes32)" "$H2"

echo
echo "================================="
echo "Results: ${GREEN}$PASS passed${RESET}, ${RED}$FAIL failed${RESET}"
echo "================================="
[[ "$FAIL" == 0 ]] || exit 1
