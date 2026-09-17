# Validation contract · 0.19.0

All evidence is local. Remote CI is configured but has not run. Older evidence files retain their original dates and scope.

## Reproduce the local suite

~~~powershell
./verify.ps1 -MoonPath /absolute/path/to/moon.exe
~~~

This runs fmt/info/check, explicit Wasm-GC and JS tests, the example, a real JS build, shipped-engine refresh, legacy demo/CLI checks, official input replay, persistent Worker/CLI tests, bounded malformed inputs and the local example benchmark.

On this machine: Moon 0.1.20260904, moonc 0.10.12, Node 24.11.0, Windows, i7-14700HX. Both backends passed 92 test groups. The generated oracle group contains 128 programs; these are not 128 additional test groups. Full output is evidence/verify-input.log.

## Independent reference

`node tools/compare-input.mjs` launches unmodified Gforth 0.7.3 for each project-authored input. Default command is `gforth`; `GFORTH_COMMAND_JSON` can specify an executable/argument array. For Windows paths passed through WSL, set `GFORTH_WSL=1`.

~~~powershell
$env:GFORTH_COMMAND_JSON='["wsl","--exec","bash","/path/to/your/run-gforth.sh"]'
$env:GFORTH_WSL='1'
node tools/compare-input.mjs
~~~

The wrapper should select your extracted executable, library path and Gforth data search path. No external reference binary is bundled or installed by this repository. Each reference process has a 15-second timeout.

The harness reads the entire authored file and calls EVALUATE to match this library's string-source semantics. For successful programs, it compares every stack integer and exact output byte; for uncaught failures, only error codes are comparable. Partial stack/output after failure, raw addresses and 32/64-bit cell boundaries are excluded. A CATCH/ABORT" case discards a stack cell whose overwritten contents are unspecified. All 128 cases passed, with complete reference/local output in evidence/input-comparison.json. That capture records the engine at capture time; subsequent final engine parity is established by offline replay and generated dual-backend vectors.

The four reference archives were rehashed and all 243 regular extracted files matched their archive members, with no mismatch: evidence/reference-integrity.json. These are local integrity checks; original acquisition source/fingerprints are in evidence/gforth-reference-packages.json. WSL emits a localhost proxy warning; captured stderr is preserved without treating it as a test failure.

~~~sh
python tools/generate-input-golden.py
moon fmt
node tools/replay-input.mjs
~~~

The generator reads only official `reference` fields, not the local `actual` fields. The replay checks current engine results and case-file SHA256 against that capture. The historical 26-program comparison remains evidence/gforth-comparison.json and is not added to the 128 as new cases. Full upstream suites have not run.

## Host and browser

`node tools/test-session.mjs` passed 9 groups: persistent state/compiler/recovery, exact output bytes, budget/concurrency/timeout, AbortSignal cancellation, strict bridge/handle limits, actual multi-file CLI, line/JSONL protocol, malformed UTF-8/size/arguments and 1000 real Worker exchanges. Details and timing are in evidence/session-validation.json. The 512 MiB Worker setting is an old-generation limit, not a measured RSS ceiling.

Actual browser interactions verified retained words, pending/completed multi-buffer compilation, error recovery, fuel exhaustion, stop/restart, raw-byte download and 390px layout. Console warning/error capture was empty. evidence/browser-session.json records observations; evidence/browser-downloads/forth-output.bin is the downloaded file and was checked byte-for-byte.

307 seeded malformed inputs passed through the existing bounded runner; this is robustness evidence for its corpus, not exhaustive validation of the new protocol. Existing coverage snapshots were not refreshed and must not be presented as current coverage.

## Performance and final integrity

The documented 54-byte JS example uses 5 warmups and 30 measured runs. A separate 1000-request Worker measurement includes serialization and validation. These are local sanity measurements, not equivalent Gforth workloads, peak memory measurements, or throughput parity.

Final source/evidence hashes are recorded in evidence/input-upgrade.json and checked against committed Git blobs by `python tools/check-proof.py`. The final manifest itself is excluded to avoid a circular hash. Generated files are checked for idempotence and the shipped engine against the final build. No old ZIP/bundle is silently replaced.
