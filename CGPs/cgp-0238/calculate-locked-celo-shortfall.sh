#!/usr/bin/env bash
# Calculates the retroactive funding amount for the LockedCelo contract,
# matching the math in the "Retroactive funding LockedCelo contract" section
# of cgp-0235.md.
#
# Pending withdrawals must be looked up manually from the Dune query and
# entered when prompted (or passed as $1). Automating it would require a
# Dune API key, which we'd rather not require for a one-shot verification.
#
# Requirements: celocli, cast (foundry), jq, python3.
#
# Usage:
#   ./calculate-locked-celo-shortfall.sh [PENDING_WITHDRAWS_CELO]

set -euo pipefail

DUNE_QUERY_URL="https://dune.com/queries/7436638"

RPC_URL="${RPC_URL:-https://forno.celo.org}"
L2_LAUNCH_DATE="${L2_LAUNCH_DATE:-2025-03-26}"
DAYS_UNTIL_PASS="${DAYS_UNTIL_PASS:-8}"

if [[ $# -ge 1 ]]; then
  PENDING_WITHDRAWS_CELO="$1"
else
  echo "Pending withdrawals from LockedCelo are tracked in this Dune query:"
  echo "  $DUNE_QUERY_URL"
  echo
  echo "Pulling this number automatically would require a Dune API key, so"
  echo "please open the query in a browser and copy the latest value below."
  echo "(You can also pass it as the first argument to skip this prompt.)"
  echo
  read -r -p "Total pending withdraws (CELO): " PENDING_WITHDRAWS_CELO
fi

if ! [[ "$PENDING_WITHDRAWS_CELO" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "Invalid number for pending withdraws: '$PENDING_WITHDRAWS_CELO'" >&2
  exit 1
fi

echo
echo "Looking up LockedCelo proxy address..."
LOCKEDCELO_CONTRACT_ADDRESS=$(
  celocli network:contracts -n "$RPC_URL" --filter='Contract=LockedCelo' --output json 2>/dev/null \
    | jq -r '.[0].proxy'
)
echo "LOCKEDCELO_CONTRACT_ADDRESS=$LOCKEDCELO_CONTRACT_ADDRESS"

echo "Querying contract balance..."
BALANCE_WEI=$(cast balance "$LOCKEDCELO_CONTRACT_ADDRESS" --rpc-url "$RPC_URL")
echo "BALANCE_WEI=$BALANCE_WEI"

echo "Querying getTotalLockedGold()..."
# `cast call` decodes uint256 as `<value> [<scientific>]`; strip the suffix.
TOTAL_LOCKED_WEI=$(cast call "$LOCKEDCELO_CONTRACT_ADDRESS" "getTotalLockedGold()(uint256)" --rpc-url "$RPC_URL" | awk '{print $1}')
echo "TOTAL_LOCKED_WEI=$TOTAL_LOCKED_WEI"

TODAY=$(date -u +%Y-%m-%d)
DAYS_SINCE_LAUNCH=$(python3 -c "
from datetime import date
launch = date.fromisoformat('$L2_LAUNCH_DATE')
today = date.fromisoformat('$TODAY')
print((today - launch).days)
")

echo
echo "--- Inputs ---"
echo "Today:                    $TODAY"
echo "L2 launch date:           $L2_LAUNCH_DATE"
echo "Days since L2 launch:     $DAYS_SINCE_LAUNCH"
echo "Days until proposal pass: $DAYS_UNTIL_PASS"
echo "Pending withdraws (CELO): $PENDING_WITHDRAWS_CELO"

python3 - <<PY
from decimal import Decimal, getcontext

getcontext().prec = 60

WEI = Decimal(10) ** 18
balance_wei = Decimal("$BALANCE_WEI")
total_locked_wei = Decimal("$TOTAL_LOCKED_WEI")
pending_withdraws = Decimal("$PENDING_WITHDRAWS_CELO")
days_since_launch = Decimal("$DAYS_SINCE_LAUNCH")
days_until_pass = Decimal("$DAYS_UNTIL_PASS")

balance = balance_wei / WEI
total_locked = total_locked_wei / WEI

raw_diff = balance - pending_withdraws - total_locked
shortfall = -raw_diff if raw_diff < 0 else Decimal(0)

if days_since_launch > 0:
    projected = shortfall * (Decimal(1) + days_until_pass / days_since_launch)
else:
    projected = shortfall

def fmt(d):
    return f"{d:,.6f}"

print()
print("--- On-chain values (CELO) ---")
print(f"LOCKEDCELO_CONTRACT_BALANCE        = {fmt(balance)}")
print(f"LOCKEDCELO_TOTAL_LOCKED            = {fmt(total_locked)}")
print(f"LOCKEDCELO_TOTAL_PENDING_WITHDRAWS = {fmt(pending_withdraws)}")
print()
print("--- Shortfall ---")
print(f"raw (balance - pending - locked)   = {fmt(raw_diff)}")
print(f"shortfall (abs of negative raw)    = {fmt(shortfall)}")
print(f"projected at proposal-pass time    = {fmt(projected)}")
print()
print("Proposal funds: 1,800,000 CELO")
print(f"Buffer over projected shortfall:   {fmt(Decimal(1800000) - projected)}")
PY
