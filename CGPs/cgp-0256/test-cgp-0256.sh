#!/usr/bin/env bash
# Fork test for CGP-0256 (register USA₮ / XAU₮0 underlying tokens in FeeHandler,
# remove the adapters).
#
#   0. Fork Celo mainnet via anvil. Pre-state: adapters active, underlying tokens
#      not, FeeHandler holds USA₮, distribute(USA₮) reverts "Token needs to be
#      active", distribute(USA₮ adapter) reverts (no transfer).
#   1. Full Governance lifecycle on the 4 mainnet.json txs:
#      propose -> dequeue -> approve -> lock + vote YES -> execute.
#   2. Post-state: underlying tokens active with UniswapFeeHandlerSeller, adapters
#      removed (inactive, handler 0x0), FeeCurrencyDirectory untouched.
#   3. distribute(USA₮) pays the full balance to the beneficiaries (Transfer
#      events sum to the pre-balance, FeeHandler ends at 0). distribute(XAU₮0),
#      handleAll(), distributeAll() succeed. A second round of USA₮ sent to
#      FeeHandler distributes again.
#
# Usage:  ./test-cgp-0256.sh
# Env:    RPC_URL (default https://forno.celo.org), ANVIL_PORT (default 8561)

set -uo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CGP_JSON="$SCRIPT_DIR/mainnet.json"

RPC_URL="${RPC_URL:-https://forno.celo.org}"
ANVIL_PORT="${ANVIL_PORT:-8561}"
RPC="http://127.0.0.1:${ANVIL_PORT}"

GOV=0xD533Ca259b330c7A88f74E000a3FaEa2d63B7972
APPROVER=0x41822d8A191fcfB1cfcA5F7048818aCd8eE933d3
LOCKED_GOLD=0x6cC083Aed9e3ebe302A6336dBC7c921C9f03349E
PROPOSER=0x8eF439ee8F6905bfd2343668039d39eB2B77706e
FH=0xcD437749E43A154C07F3553504c68fBfD56B8778
FCD=0x15F344b9E6c3Cb6F0376A36A64928b13F62C6276
SELLER=0xD3aeE28548Dbb65DF03981f0dC0713BfCBd10a97
USAT=0xD2ab3C9A02DBBAB236BfEC45D1d755DF4267F771
XAUT=0xaf37E8B6C9ED7f6318979f56Fc287d76c30847ff
USAT_ADAPTER=0x0357EE22278c922e1D36cFe6b899269b161880C4
XAUT_ADAPTER=0x857BF24e29da0773687E804a743c2E421a394C16
RANDO=0x000000000000000000000000000000000000C0fe
TRANSFER_TOPIC=0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef

PASS=0; FAIL=0
RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'; RESET=$'\033[0m'
ok()  { echo "  ${GREEN}PASS${RESET} $1"; PASS=$((PASS+1)); }
no()  { echo "  ${RED}FAIL${RESET} $1"; FAIL=$((FAIL+1)); }
lower() { tr '[:upper:]' '[:lower:]' <<<"$1"; }
asseq() { [[ "$(lower "$2")" == "$(lower "$3")" ]] && ok "$1" || no "$1 got=$2 want=$3"; }
asslist() { # label actual-list expected-member yes|no
  local has=no; grep -qi "$3" <<<"$2" && has=yes
  [[ "$has" == "$4" ]] && ok "$1" || no "$1 (list=$2)"
}

ccall() { cast call --rpc-url "$RPC" "$@"; }
cval()  { ccall "$@" | awk '{print $1}'; }
csend() { cast send --rpc-url "$RPC" --unlocked --legacy --gas-price 0 "$@"; }
csend_hash() { csend --json "$@" | python3 -c "import json,sys; r=json.load(sys.stdin); assert r['status']=='0x1','tx reverted'; print(r['transactionHash'])"; }
fund()  { cast rpc --rpc-url "$RPC" anvil_setBalance "$1" "$2" >/dev/null; }
warp()  { cast rpc --rpc-url "$RPC" anvil_increaseTime "$1" >/dev/null; cast rpc --rpc-url "$RPC" anvil_mine 1 >/dev/null; }
expect_revert() { # label reason-substring cast-call-args...
  local label="$1" reason="$2"; shift 2
  local out; out=$(ccall "$@" 2>&1)
  if grep -q "$reason" <<<"$out"; then ok "$label"; else no "$label: expected '$reason', got: $out"; fi
}
# sum of Transfer(from=$FH) amounts of $token in tx; prints "<total> <n_logs> <recipients>"
transfers_out() { # txhash token
  cast receipt --rpc-url "$RPC" --json "$1" | python3 -c "
import json,sys
r=json.load(sys.stdin); tok=sys.argv[1].lower(); fh='$(lower "$FH")'
tot=0; n=0; rec=[]
for l in r['logs']:
    if l['address'].lower()==tok and l['topics'][0].lower()=='$TRANSFER_TOPIC' and ('0x'+l['topics'][1][-40:])==fh:
        tot+=int(l['data'],16); n+=1; rec.append('0x'+l['topics'][2][-40:])
print(tot, n, ','.join(rec))" "$2"
}

cleanup() { [[ -n "${ANVIL_PID:-}" ]] && kill "$ANVIL_PID" 2>/dev/null && wait "$ANVIL_PID" 2>/dev/null || true; }
trap cleanup EXIT

echo "${YELLOW}==>${RESET} anvil fork of $RPC_URL on :$ANVIL_PORT"
anvil --fork-url "$RPC_URL" --port "$ANVIL_PORT" --auto-impersonate --block-base-fee-per-gas 0 \
      >"$SCRIPT_DIR/anvil.log" 2>&1 &
ANVIL_PID=$!
for _ in $(seq 1 60); do cast block-number --rpc-url "$RPC" >/dev/null 2>&1 && break; sleep 1; done
cast block-number --rpc-url "$RPC" >/dev/null || { echo "anvil failed to start"; exit 1; }
echo "    block $(cast block-number --rpc-url "$RPC")"
for a in "$PROPOSER" "$APPROVER" "$RANDO"; do fund "$a" 0x295BE96E64066972000000; done  # 50M each

# ---- mainnet.json -> calldatas --------------------------------------------
TXS=$(python3 - "$CGP_JSON" <<'PY'
import json, sys
txs = json.load(open(sys.argv[1]))
assert len(txs) == 4, f"expected 4 txs, got {len(txs)}"
for t in txs:
    assert t["value"] == "0"
    print("\t".join([t["address"], t["function"]] + t["args"]))
PY
)
DESTS=(); DATAS=(); LENS=()
while IFS=$'\t' read -r to fn a1 a2; do
  case "$fn" in
    addToken)    cd=$(cast calldata "addToken(address,address)" "$a1" "$a2");;
    removeToken) cd=$(cast calldata "removeToken(address)" "$a1");;
    *) echo "unexpected function $fn"; exit 1;;
  esac
  DESTS+=("$to"); DATAS+=("$cd"); LENS+=("$(( (${#cd} - 2) / 2 ))")
done <<<"$TXS"
asseq "mainnet.json: 4 txs, all to FeeHandler" "${DESTS[0]},${DESTS[1]},${DESTS[2]},${DESTS[3]}" "$FH,$FH,$FH,$FH"
asseq "mainnet.json tx1 = addToken(USA₮, seller)"      "${DATAS[0]}" "$(cast calldata 'addToken(address,address)' $USAT $SELLER)"
asseq "mainnet.json tx2 = addToken(XAU₮0, seller)"     "${DATAS[1]}" "$(cast calldata 'addToken(address,address)' $XAUT $SELLER)"
asseq "mainnet.json tx3 = removeToken(USA₮ adapter)"   "${DATAS[2]}" "$(cast calldata 'removeToken(address)' $USAT_ADAPTER)"
asseq "mainnet.json tx4 = removeToken(XAU₮0 adapter)"  "${DATAS[3]}" "$(cast calldata 'removeToken(address)' $XAUT_ADAPTER)"
DATA="${DATAS[0]}${DATAS[1]#0x}${DATAS[2]#0x}${DATAS[3]#0x}"

# ============================================================
echo "${YELLOW}==>${RESET} Phase 0 — pre-state: USA₮ stuck in FeeHandler"
# ============================================================
asseq "FeeHandler.owner() == Governance" "$(ccall "$FH" 'owner()(address)')" "$GOV"
ACTIVE=$(ccall "$FH" 'getActiveTokens()(address[])')
asslist "USA₮ adapter active"       "$ACTIVE" "$USAT_ADAPTER" yes
asslist "XAU₮0 adapter active"      "$ACTIVE" "$XAUT_ADAPTER" yes
asslist "USA₮ underlying NOT active"  "$ACTIVE" "$USAT" no
asslist "XAU₮0 underlying NOT active" "$ACTIVE" "$XAUT" no
USAT_BAL0=$(cval "$USAT" 'balanceOf(address)(uint256)' "$FH")
XAUT_BAL0=$(cval "$XAUT" 'balanceOf(address)(uint256)' "$FH")
echo "    FeeHandler USA₮ = $USAT_BAL0 (6 dec), XAU₮0 = $XAUT_BAL0"
[[ "$USAT_BAL0" -gt 0 ]] && ok "FeeHandler holds USA₮ (> 0)" || no "FeeHandler USA₮ balance is 0; nothing to prove"
expect_revert "distribute(USA₮) reverts: not active"         "Token needs to be active" "$FH" "distribute(address)" "$USAT"
expect_revert "distribute(USA₮ adapter) reverts (no transfer)" "execution reverted"       "$FH" "distribute(address)" "$USAT_ADAPTER"
asseq "burnFraction == 0 (no selling)" "$(cval "$FH" 'getBurnFraction()(uint256)')" "0"
BENEFICIARY=$(ccall "$FH" 'getOtherBeneficiariesAddresses()(address[])' | tr -d '[] ' )
CARBON=$(ccall "$FH" 'carbonFeeBeneficiary()(address)')
echo "    beneficiaries: other=$BENEFICIARY carbon=$CARBON carbonFraction=$(cval "$FH" 'getCarbonFraction()(uint256)')"
FCD_USAT_BEFORE=$(ccall "$FCD" 'currencies(address)(address,uint256)' "$USAT_ADAPTER" | tr '\n' ' ')
FCD_XAUT_BEFORE=$(ccall "$FCD" 'currencies(address)(address,uint256)' "$XAUT_ADAPTER" | tr '\n' ' ')

# ============================================================
echo "${YELLOW}==>${RESET} Phase 1 — Governance lifecycle: propose -> dequeue -> approve -> vote -> execute"
# ============================================================
csend --from "$PROPOSER" --value 10000ether "$GOV" "propose(uint256[],address[],bytes,uint256[],string)" \
  "[0,0,0,0]" "[${DESTS[0]},${DESTS[1]},${DESTS[2]},${DESTS[3]}]" "$DATA" "[${LENS[0]},${LENS[1]},${LENS[2]},${LENS[3]}]" \
  "https://github.com/celo-org/governance/blob/main/CGPs/cgp-0256.md" >/dev/null && ok "propose()" || no "propose()"
PID=$(cval "$GOV" "proposalCount()(uint256)")
echo "    proposalId = $PID"
warp 90000
csend --from "$PROPOSER" "$GOV" "dequeueProposalsIfReady()" >/dev/null
IDX=$(python3 -c "
s='''$(ccall "$GOV" "getDequeue()(uint256[])")'''.strip('[]')
ids=[x.strip() for x in s.split(',') if x.strip()]; print(ids.index('$PID') if '$PID' in ids else -1)")
asseq "dequeued" "$([[ "$IDX" != -1 ]] && echo y || echo n)" "y"
csend --from "$APPROVER" "$GOV" "approve(uint256,uint256)" "$PID" "$IDX" >/dev/null
asseq "isApproved" "$(ccall "$GOV" "isApproved(uint256)(bool)" "$PID")" "true"
warp 86400
csend --from "$PROPOSER" --value 20000000ether "$LOCKED_GOLD" "lock()" >/dev/null
csend --from "$PROPOSER" "$GOV" "vote(uint256,uint256,uint8)" "$PID" "$IDX" 3 >/dev/null && ok "vote YES (20M locked)" || no "vote"
warp 604800
asseq "isProposalPassing" "$(ccall "$GOV" "isProposalPassing(uint256)(bool)" "$PID")" "true"
csend --from "$PROPOSER" "$GOV" "execute(uint256,uint256)" "$PID" "$IDX" >/dev/null && ok "Governance.execute()" || no "Governance.execute()"

# ============================================================
echo "${YELLOW}==>${RESET} Phase 2 — post-state"
# ============================================================
ACTIVE=$(ccall "$FH" 'getActiveTokens()(address[])')
asslist "USA₮ underlying active"     "$ACTIVE" "$USAT" yes
asslist "XAU₮0 underlying active"    "$ACTIVE" "$XAUT" yes
asslist "USA₮ adapter removed"       "$ACTIVE" "$USAT_ADAPTER" no
asslist "XAU₮0 adapter removed"      "$ACTIVE" "$XAUT_ADAPTER" no
asseq "handler(USA₮) == UniswapFeeHandlerSeller"  "$(ccall "$FH" 'getTokenHandler(address)(address)' "$USAT")" "$SELLER"
asseq "handler(XAU₮0) == UniswapFeeHandlerSeller" "$(ccall "$FH" 'getTokenHandler(address)(address)' "$XAUT")" "$SELLER"
asseq "handler(USA₮ adapter) == 0x0"  "$(ccall "$FH" 'getTokenHandler(address)(address)' "$USAT_ADAPTER")" "0x0000000000000000000000000000000000000000"
asseq "handler(XAU₮0 adapter) == 0x0" "$(ccall "$FH" 'getTokenHandler(address)(address)' "$XAUT_ADAPTER")" "0x0000000000000000000000000000000000000000"
asseq "FeeCurrencyDirectory(USA₮ adapter) unchanged"  "$(ccall "$FCD" 'currencies(address)(address,uint256)' "$USAT_ADAPTER" | tr '\n' ' ')" "$FCD_USAT_BEFORE"
asseq "FeeCurrencyDirectory(XAU₮0 adapter) unchanged" "$(ccall "$FCD" 'currencies(address)(address,uint256)' "$XAUT_ADAPTER" | tr '\n' ' ')" "$FCD_XAUT_BEFORE"
asseq "FeeHandler USA₮ balance untouched by the proposal" "$(cval "$USAT" 'balanceOf(address)(uint256)' "$FH")" "$USAT_BAL0"

# ============================================================
echo "${YELLOW}==>${RESET} Phase 3 — the stuck USA₮ is distributed"
# ============================================================
TX=$(csend_hash --from "$RANDO" "$FH" "distribute(address)" "$USAT") && ok "distribute(USA₮) succeeds (permissionless)" || no "distribute(USA₮)"
read -r OUT_TOTAL OUT_N OUT_REC <<<"$(transfers_out "$TX" "$USAT")"
echo "    Transfer(FeeHandler -> ...) count=$OUT_N total=$OUT_TOTAL recipients=$OUT_REC"
asseq "USA₮ paid out equals pre-balance ($USAT_BAL0)" "$OUT_TOTAL" "$USAT_BAL0"
asseq "recipient is the beneficiary ($BENEFICIARY)" "$OUT_REC" "$BENEFICIARY"
asseq "FeeHandler USA₮ balance == 0 after distribute" "$(cval "$USAT" 'balanceOf(address)(uint256)' "$FH")" "0"
csend --from "$RANDO" "$FH" "distribute(address)" "$XAUT" >/dev/null && ok "distribute(XAU₮0) succeeds (balance 0)" || no "distribute(XAU₮0)"
csend --from "$RANDO" "$FH" "handleAll()"      >/dev/null && ok "handleAll() succeeds with new token set"    || no "handleAll()"
csend --from "$RANDO" "$FH" "distributeAll()"  >/dev/null && ok "distributeAll() succeeds with new token set" || no "distributeAll()"
expect_revert "distribute(USA₮ adapter) now reverts: not active" "Token needs to be active" "$FH" "distribute(address)" "$USAT_ADAPTER"

# second round: beneficiary sends 10 USA₮ back to FeeHandler (stands in for new gas fees)
ROUND2=10000000
fund "$BENEFICIARY" 0xDE0B6B3A7640000
csend --from "$BENEFICIARY" "$USAT" "transfer(address,uint256)" "$FH" "$ROUND2" >/dev/null
asseq "FeeHandler holds second-round USA₮" "$(cval "$USAT" 'balanceOf(address)(uint256)' "$FH")" "$ROUND2"
TX2=$(csend_hash --from "$RANDO" "$FH" "distribute(address)" "$USAT") && ok "second distribute(USA₮) succeeds" || no "second distribute(USA₮)"
read -r OUT2 _ _ <<<"$(transfers_out "$TX2" "$USAT")"
asseq "second round paid out in full" "$OUT2" "$ROUND2"
asseq "FeeHandler USA₮ balance == 0 again" "$(cval "$USAT" 'balanceOf(address)(uint256)' "$FH")" "0"

echo
echo "================================="
echo "Results: ${GREEN}$PASS passed${RESET}, ${RED}$FAIL failed${RESET}"
echo "================================="
[[ "$FAIL" == 0 ]] || exit 1
