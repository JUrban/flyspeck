# Lightweight nonlinear computation harness

Status: DEVELOPMENT / NON-RELEASE

`run_cv_nonlinear_harness_checkpoint.sh` runs one experiment from a fresh
copy-on-write restore of `cv-staged-base-checkpoint-v2`.  That checkpoint is
after HOL startup, the arithmetic-float prelude, the staged polynomial
checker, and the small Taylor fixtures, but before experiment-specific code.
It is intended for numerical-representation, whole polynomial/Taylor
calculation, and theorem-handoff experiments.  It is not evidence that the
complete nonlinear verifier or a Flyspeck action passes.

The runner requires a new output directory, an experiment driver, and a
unique success marker:

```sh
formal_ineqs/arith/run_cv_nonlinear_harness_checkpoint.sh \
  /project/flyspeck-candle-runs/my-fresh-run \
  /absolute/path/to/driver.hl \
  MY_EXPERIMENT_OK
```

Every invocation checks the frozen base checkpoint, makes a read-only reflink
copy, records the exact driver and checkpoint hashes, verifies that the driver
did not change during the run, rejects Candle error markers, and requires the
declared success marker.  A new output directory is mandatory, so an
experiment never resumes a failed or partially loaded state.

The current base checkpoint SHA-256 is
`69de9bbb91c71980306e45a663658253102e4a2ad114094856a0c69b149e5100`.
It is tied to the staged arithmetic/Taylor environment loaded in
`cv-staged-base-checkpoint-v2`; changes to those definitions require a new
authenticated base checkpoint rather than reuse of this one.

## Real endpoint validation

The first validation used
`test_cv_compute_real_nl_domain_endpoint_profile.hl`, whose input is the exact
upper endpoint `2.0 * 1.26 * 2.0 * 1.26` from the archived native theorem for
`prep-4680581274 delta issue-cayleyR,0`.

The fresh restore reproduced the assumption-free theorem

```text
|- #2.0 * #1.26 * #2.0 * #1.26 <= ##254016*200^-2
```

in 14.23 seconds wall time, 1.07 user plus 4.38 system seconds, and 2,252,544
KiB maximum RSS.  The profiled theorem-producing calculation itself took 0.58
CPU seconds: 0.01 seconds for source-number representation, 0.52 seconds for
proof preparation, less than the 0.01-second clock resolution in
`Kernel.compute`, 0.01 seconds for internal handoff, and 0.01 seconds for the
final source-expression handoff.

The previous run from the shallower program checkpoint took 155.46 seconds
wall time for the same calculation.  The post-Taylor checkpoint therefore
reduces fresh experiment latency by 10.9x while preserving the theorem and
numerical phase split.

Passing evidence is under
`/project/flyspeck-candle-runs/cv-real-nl-endpoint-staged-harness-v2`:

- driver SHA-256:
  `7d1456115fbc33d854888011d2b77f17db328c2eefba78a14611e07285bb0816`;
- log SHA-256:
  `cf38506d282e9e048196f255bac5f087eeff3bcc132c44e2bef3c81bfa9799f2`;
- timing SHA-256:
  `bc7d302eba62e68a1d3564379a671b8b4db0d32127d8440ccbccf6fda1b72f88`.

The next useful fixture is a complete first-derivative/Hessian pair captured
from a genuine leaf after native or full-verifier preparation.  Its purely
numerical plan and theorem handoff can then iterate here; certificate search,
Taylor theorem construction, subdivision, and root reconstruction remain in
the full integration state.
