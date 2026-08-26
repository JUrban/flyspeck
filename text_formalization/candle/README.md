# Candle leaf exporters

These files are narrow integration harnesses for producing representative
Flyspeck proof leaves with the direct HOL Light PFT producer.  They do not
replace `build/strictbuild.hl` and must not be used as evidence that the full
Flyspeck build has loaded.

`basics_length3_leaf.hl` is a checked extraction of the original `LENGTH1`,
`LENGTH2`, and `LENGTH3` proof block from `leg/basics.hl`.  It verifies the
source file's OCaml `Digest` before proving the extracted leaf and supplies
only the small subset of Flyspeck tactic helpers used by those proofs.  This
keeps the list/refinement route-selection test independent of the much larger
multivariate foundation.

`vukhacky_real_leaf.hl` similarly pins and extracts the real-arithmetic
refinement proof `REDUCE_WITH_DIV_Euler_lemma` from
`general/vukhacky_tactics.hl`.  `export_refinement_leaves.hl` emits both the
list and real-arithmetic targets in one small trace.

Run an exporter from a clean, patched HOL Light checkout with
`HOLLIGHT_DIR`, `FLYSPECK_DIR`, and `CANDLE_PFT_OUTPUT` set.  For example:

```ocaml
needs "/path/to/flyspeck/text_formalization/candle/export_basics_length3.hl";;
```

The output remains hostile input to the compiled Candle checker.  Exporter
success alone is not acceptance evidence.
