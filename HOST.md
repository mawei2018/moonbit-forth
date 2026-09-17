# Host API and CLI contract

The generated `web/engine.mjs` exports legacy `run(source)`, one-shot `report(source)`, and persistent `session(jsonText)`.

`session` accepts exactly the fields below; unknown fields/operations are errors. Requests are JSON strings of at most 2,200,000 UTF-16 units. Up to eight machine handles exist per module instance.

| Operation | Fields | Result |
|---|---|---|
| open | op | ok, id |
| eval / feed | op, id, source, optional budget | ok, stack, output, bytes, compiling; code/error on Forth failure |
| state / reset | op, id | current or empty machine result |
| close | op, id | ok |

IDs and budgets must be integers. Budget is 1..10,000,000, default 1,000,000 in the bridge. Invalid protocol returns `ok:false, host_error:true, error`. Eval requires a complete definition; feed retains an unfinished compiler. The bridge clears output before each eval/feed. `state` reports the last operation's output without clearing it. The source is limited to 1,000,000 UTF-16 units by the core.

`ForthSession.open({timeoutMs,budget,signal})` provides a private Node Worker and handle. Timeout defaults to 5000 ms per operation, including startup; allowed values are 1..300000 ms. Only one outstanding operation is allowed. Timeout, abort and close terminate the Worker, reject any pending operation and discard state. Explicitly await close in finally. The Worker old-generation limit is 512 MiB; this is not a total RSS limit or a security isolation guarantee. Browser workers have a 10-second timeout and 10,000,000 execution budget.

The CLI caps individual files, batch stdin and each streaming line at 2 MiB. UTF-8 decoding is strict. JSON strings are additionally subject to the core/source limits. Multiple file/eval arguments share one machine and stop on the first Forth failure. Lines and JSONL continue after ordinary errors, retaining successful prior changes. EOF with unfinished compilation exits 2.

| Exit code | Meaning |
|---|---|
| 0 | Successful input |
| 1 | Host/protocol/UTF-8/argument/transport error |
| 2 | Forth error or unfinished definition |
| 130 | Received SIGINT/SIGTERM through the implemented handler |

Actual AbortSignal cancellation was tested; signal delivery on every platform has not been established. Output uses stdout backpressure and exact byte buffers; diagnostics/prompts use stderr except JSONL command errors, which are JSON responses. No file networking or user code execution outside the Forth virtual machine is exposed.

`--json` and JSONL return original output bytes plus a lossy UTF-8 display string. Do not reconstruct binary data from the display string. Use `Buffer.from(result.bytes)`. Legacy tools/cli.mjs uses the previous numeric-only demonstration contract and remains available for compatibility.
