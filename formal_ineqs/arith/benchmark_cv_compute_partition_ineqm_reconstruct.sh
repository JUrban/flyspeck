#!/usr/bin/env bash
set -euo pipefail

candle_root=${CANDLE_ROOT:-/project/worktrees/candle-cv-taylor-bound-v1}
flyspeck_root=$(cd "$(dirname "$0")/../.." && pwd)
binary=${CANDLE_BINARY:-/project/flyspeck-candle-runs/nonpromotable-dev-link-cc36ecadd-1109fdf-attempt-001/cake}
runtime_cwd=${CANDLE_RUNTIME_CWD:-/project/flyspeck-candle-runs/nonpromotable-dev-link-cc36ecadd-1109fdf-attempt-001}
if [[ -n ${LOG_FILE:-} ]]; then
  log_file=$LOG_FILE
else
  log_file=$(mktemp)
  trap 'rm -f "$log_file"' EXIT
fi

(
  cd "$runtime_cwd"
  timeout 1200 "$binary" --candle >"$log_file" 2>&1 <<EOF
Cakeml.loadPath := ["$candle_root"; "/project/worktrees/candle-action165-invf-v61"; Filename.currentDir];;
#use "hol.ml";;
load_path := ["$flyspeck_root/formal_ineqs"; "$flyspeck_root"; "$candle_root"; "/project/worktrees/candle-action165-invf-v61"] @ !load_path;;
#use "$flyspeck_root/formal_ineqs/arith/benchmark_cv_compute_partition_ineqm_reconstruct.hl";;
EOF
)

if ! rg -Fq 'CANDLE_CV_PARTITION_SYNTHETIC_OK' "$log_file"; then
  tail -400 "$log_file" >&2
  exit 1
fi
if rg -q 'ERROR:|EXCEPTION:|Parsing failed' "$log_file"; then
  tail -300 "$log_file" >&2
  exit 1
fi

rg -o 'CANDLE_CV_PARTITION_SYNTHETIC_[A-Z_]+=[0-9]+' "$log_file"
printf '%s\n' 'CANDLE_CV_PARTITION_SYNTHETIC_OK'
