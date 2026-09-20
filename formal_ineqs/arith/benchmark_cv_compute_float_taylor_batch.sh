#!/usr/bin/env bash
set -euo pipefail

candle_root=${CANDLE_ROOT:-/project/worktrees/candle-cv-taylor-bound-v1}
flyspeck_root=$(cd "$(dirname "$0")/../.." && pwd)
overlay_root=${FLYSPECK_OVERLAY_ROOT:-/project/flyspeck-candle-runs/cv-nonlinear-first-leaf-v17/overlay/flyspeck/formal_ineqs}
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
  timeout 3600 "$binary" --candle >"$log_file" 2>&1 <<EOF
Cakeml.loadPath := ["$candle_root"; "/project/worktrees/candle-action165-invf-v61"; Filename.currentDir];;
#use "hol.ml";;
load_path := ["$overlay_root"; "$flyspeck_root/formal_ineqs"; "$flyspeck_root/jHOLLight"; "$flyspeck_root"; "$candle_root"; "/project/worktrees/candle-action165-invf-v61"] @ !load_path;;
#use "$flyspeck_root/formal_ineqs/arith/test_cv_compute_arith_float_prelude.ml";;
#use "$flyspeck_root/formal_ineqs/arith/benchmark_cv_compute_float_taylor_batch.hl";;
EOF
)

for marker in \
  CANDLE_CV_FLOAT_TAYLOR_OK \
  CANDLE_CV_TAYLOR_BATCH_FINE_TICKS= \
  CANDLE_CV_TAYLOR_BATCH_SCALAR_TICKS= \
  CANDLE_CV_TAYLOR_BATCH_REFLECTED_TICKS= \
  CANDLE_CV_TAYLOR_BATCH_CELLS=32 \
  CANDLE_CV_TAYLOR_BATCH_LARGE_TICKS= \
  CANDLE_CV_TAYLOR_BATCH_LARGE_CELLS=128 \
  CANDLE_CV_TAYLOR_BATCH_BENCHMARK_OK
do
  if ! rg -Fq "$marker" "$log_file"; then
    tail -600 "$log_file" >&2
    exit 1
  fi
done
if rg -q 'ERROR:|EXCEPTION:|Parsing failed' "$log_file"; then
  tail -360 "$log_file" >&2
  exit 1
fi

rg -o 'CANDLE_CV_TAYLOR_BATCH_[A-Z_]+=[0-9]+' "$log_file"
printf '%s\n' 'CANDLE_CV_TAYLOR_BATCH_BENCHMARK_OK'
