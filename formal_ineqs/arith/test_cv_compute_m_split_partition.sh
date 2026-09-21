#!/usr/bin/env bash
set -euo pipefail

flyspeck_root=$(cd "$(dirname "$0")/../.." && pwd)
candle_root=${CANDLE_ROOT:-/project/worktrees/candle-cv-nonlinear-analytic-v1}
binary=${CANDLE_BINARY:-/project/flyspeck-candle-runs/nonpromotable-dev-link-cc36ecadd-1109fdf-attempt-001/cake}
runtime_cwd=${CANDLE_RUNTIME_CWD:-/project/flyspeck-candle-runs/nonpromotable-dev-link-cc36ecadd-1109fdf-attempt-001}
log_file=${LOG_FILE:-$(mktemp)}
if [[ -z ${LOG_FILE:-} ]]; then trap 'rm -f "$log_file"' EXIT; fi

(
  cd "$runtime_cwd"
  timeout 14400 "$binary" --candle >"$log_file" 2>&1 <<EOF
Cakeml.loadPath := ["$candle_root"; "/project/worktrees/candle-action165-invf-v61"; Filename.currentDir];;
#use "hol.ml";;
load_path := ["$flyspeck_root/formal_ineqs"; "$flyspeck_root"; "$candle_root"; "/project/worktrees/candle-action165-invf-v61"] @ !load_path;;
#use "$flyspeck_root/formal_ineqs/arith/test_cv_compute_m_split_partition_prelude.ml";;
#use "$flyspeck_root/formal_ineqs/arith/test_cv_compute_m_split_partition.hl";;
EOF
)

if ! rg -Fq 'CANDLE_CV_M_SPLIT_PARTITION_OK' "$log_file"; then
  tail -300 "$log_file" >&2
  exit 1
fi
if rg -q 'ERROR:|EXCEPTION:|Parsing failed' "$log_file"; then
  tail -300 "$log_file" >&2
  exit 1
fi

printf '%s\n' 'CANDLE_CV_M_SPLIT_PARTITION_OK'
