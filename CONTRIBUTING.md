# Local development

This is an independent repository. Do not import sibling projects or depend on private workspace paths. Keep work local; there is no configured remote or publication step.

Run `./verify.ps1 -MoonPath /absolute/path/to/moon` before committing. It formats, generates the public API, checks warnings, tests Wasm-GC and JS, rebuilds the shipped engine and runs CLI/session/reference-replay/robustness checks. Review generated API changes. Format and info must be idempotent.

Add public behavior regressions for substantive changes, especially input/compiler/state/error boundaries. Avoid tests which merely restate low-impact implementation details. Use external reference outputs where they are actually comparable; preserve intentional differences and reference failures explicitly.

`tools/generate-input-golden.py` reads only the reference fields of evidence/input-comparison.json, never local actual fields. Run it followed by moon fmt when refreshing that capture. `tools/replay-input.mjs` rechecks the current engine against the saved official outcomes; `tools/compare-input.mjs` invokes a real external Gforth.

See TESTING.md for commands and limits. Time a meaningful fixed workload before making performance claims. Never infer feature parity from unit count, coverage or a successful build. A saved browser engine is not browser UI acceptance.
