#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  printf 'usage: %s OUTPUT_DIR DRIVER EXPECTED_MARKER\n' "$0" >&2
  exit 2
fi

base_dir=/project/flyspeck-candle-runs/cv-staged-base-checkpoint-v2
output_dir=$1
driver=$2
expected_marker=$3

[[ -f "$base_dir/CHECKPOINT-READY" ]]
[[ ! -e "$base_dir/CHECKPOINT-FAILED" ]]
[[ -f "$driver" ]]
[[ ! -e "$output_dir" ]]
driver=$(readlink -f "$driver")
driver_dir=$(dirname "$driver")
driver_sha256_before=$(sha256sum "$driver" | awk '{print $1}')

mapfile -t source_checkpoints < <(
  find "$base_dir/checkpoint" -maxdepth 1 -type f \
    -name 'ckpt_*.dmtcp' -print
)
[[ ${#source_checkpoints[@]} -eq 1 ]]
sha256sum -c "$base_dir/checkpoint.sha256"

mkdir -p "$output_dir/checkpoint-copy" "$output_dir/dmtcp-tmp" \
  "$output_dir/restart-checkpoint"
checkpoint_copy="$output_dir/checkpoint-copy/$(basename "${source_checkpoints[0]}")"
cp --reflink=always --preserve=mode,timestamps \
  "${source_checkpoints[0]}" "$checkpoint_copy"
chmod a-w "$checkpoint_copy"

set +e
{
  printf 'load_path := ["%s"] @ !load_path;;\n' "$driver_dir"
  printf '#use "%s";;\n' "$driver"
} | /usr/bin/time -v -o "$output_dir/time.log" \
    timeout --signal=TERM --kill-after=30 1800 \
    /usr/bin/env -i PATH=/project/bin:/usr/local/bin:/usr/bin:/bin LC_ALL=C \
      DMTCP_TMPDIR="$output_dir/dmtcp-tmp" \
      /usr/local/bin/dmtcp_restart --new-coordinator --coord-port 0 \
        --port-file "$output_dir/restart.port" \
        --ckptdir "$output_dir/restart-checkpoint" "$checkpoint_copy" \
        >"$output_dir/candle.log" 2>&1
run_status=$?
set -e
printf '%s\n' "$run_status" >"$output_dir/exit.status"

driver_sha256_after=$(sha256sum "$driver" | awk '{print $1}')
[[ "$driver_sha256_after" == "$driver_sha256_before" ]]
{
  printf 'base_checkpoint_sha256=%s\n' \
    "$(sha256sum "${source_checkpoints[0]}" | awk '{print $1}')"
  printf 'driver=%s\n' "$driver"
  printf 'driver_sha256=%s\n' "$driver_sha256_before"
  printf 'expected_marker=%s\n' "$expected_marker"
} >"$output_dir/input-receipt.txt"
sha256sum "$output_dir/candle.log" "$output_dir/time.log" \
  "$output_dir/input-receipt.txt" >"$output_dir/evidence.sha256"

if (( run_status != 0 )); then
  tail -300 "$output_dir/candle.log" >&2
  exit "$run_status"
fi
if rg -q 'ERROR:|EXCEPTION:|Parsing failed|Program exited with nonzero' \
     "$output_dir/candle.log" ||
   ! rg -Fq "$expected_marker" "$output_dir/candle.log"; then
  tail -400 "$output_dir/candle.log" >&2
  exit 1
fi

printf '%s\n' 'CANDLE_CV_NONLINEAR_HARNESS_RESTART_OK'
