#!/usr/bin/env bash
set -euo pipefail

candle_root=${CANDLE_ROOT:-/project/worktrees/candle-cv-nonlinear-analytic-v1}
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
#use "$flyspeck_root/formal_ineqs/arith/test_cv_compute_m_taylor_bounds.hl";;
EOF
)

if ! rg -Fq 'CANDLE_CV_M_TAYLOR_BOUNDS_OK' "$log_file"; then
  tail -600 "$log_file" >&2
  exit 1
fi
if rg -q 'ERROR:|EXCEPTION:|Parsing failed' "$log_file"; then
  tail -360 "$log_file" >&2
  exit 1
fi

printf '%s\n' 'CANDLE_CV_M_TAYLOR_BOUNDS_OK'
