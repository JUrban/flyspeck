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
  timeout 900 "$binary" --candle >"$log_file" 2>&1 <<EOF
Cakeml.loadPath := ["$candle_root"; "/project/worktrees/candle-action165-invf-v61"; Filename.currentDir];;
#use "hol.ml";;
load_path := ["$flyspeck_root/formal_ineqs"; "$flyspeck_root"; "$candle_root"; "/project/worktrees/candle-action165-invf-v61"] @ !load_path;;
#use "$flyspeck_root/text_formalization/nonlinear/break_case_type.hl";;
#use "$flyspeck_root/text_formalization/nonlinear/break_case_log.hl";;
#use "$flyspeck_root/formal_ineqs/arith/profile_cv_compute_partition_iargs.hl";;
EOF
)

for marker in \
  CANDLE_CV_PARTITION_IARGS_TICKS= \
  CANDLE_CV_PARTITION_IARGS_TREES=463 \
  CANDLE_CV_PARTITION_IARGS_CASES=22941 \
  CANDLE_CV_PARTITION_IARGS_NODES=29957 \
  CANDLE_CV_PARTITION_IARGS_OK
do
  if ! rg -Fq "$marker" "$log_file"; then
    tail -400 "$log_file" >&2
    exit 1
  fi
done
if rg -q 'ERROR:|EXCEPTION:|Parsing failed' "$log_file"; then
  tail -300 "$log_file" >&2
  exit 1
fi

rg -o 'CANDLE_CV_PARTITION_IARGS_[A-Z0-9_]+=[0-9]+' "$log_file"
printf '%s\n' 'CANDLE_CV_PARTITION_IARGS_OK'
