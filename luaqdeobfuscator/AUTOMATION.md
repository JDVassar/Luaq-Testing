# Executor/Studio workflow

**An executor-free option is now available:** see [STANDALONE.md](STANDALONE.md). The instructions below retain the older executor/Studio handoff as an alternative.

This automates randomized-layout discovery, build-adapter generation, authenticated bootstrap recovery, capture-runner generation and offline validation. Once a runtime capture exists, it also automates data import, operand lifting, source specialization and compilation. It does **not** yet automatically reconstruct polished clean source. The generated `decoded.luau` is explicitly marked as an intermediate.

## Prepare from a new input

From this tool's directory:

```sh
python3 luaq.py process /path/to/protected.lua --out /path/to/job
```

There is no manual selection or naming of a known build. The tool parses the observed loader structure and derives function roles, bank names, affine opcode maps, field layout, constant tags, capture hooks, runtime adapters and decoder call signatures from the input. This discovery was checked against three distinct randomized builds with four, six and seven banks. The older first sample uses a different loader structure; its existing pinned profile remains available, while automatic discovery fails explicitly for it.

Preparation authenticates and decrypts the bootstrap in Python. It exercises the generated capture traversal on the bootstrap under the local Luau runtime, checking recovered constants and packet operands. It does not execute the protected application or contact its service. The structural family currently requires the observed 107-statement loader and ASCII protected wrapper; changed structures fail with a diagnostic rather than guessing a mapping.

The job contains:

- `capture_runner.luau`: executor runner.
- `CaptureStudio.rbxlx` / `CaptureRunner.rbxmx`: Studio alternatives.
- `profile/`: automatically generated build adapter.
- `prepare_report.json`: validation and the unique capture filename.
- `process_report.json`: stage result, including `clean_source_available: false`.

The capture filename includes the first eight characters of the build ID, so successive inputs do not all use the same filename. Renaming captures is fine; the header identifies the build.

## Run once in the intended environment

Execute `capture_runner.luau` where the protected application normally works. The runtime must supply application bytes and regions that are absent from the input file. This can now be done in Lune through the standalone command, without Roblox or an executor. Preparation can be automatic, but a successful service/runtime response cannot be replaced with an invented local result.

## Automatically consume the saved capture

Start this before or after executing the runner:

```sh
python3 luaq.py resume /path/to/job \
  --capture "/path/to/executor/workspace/luaq-BUILDID-capture.jsonl" \
  --out /path/to/recovery \
  --wait
```

`resume` uses the generated profile and waits for a stable, parseable capture containing an application root. It then recovers available data and emits/compiles intermediate decoded source automatically. It waits up to 600 seconds by default; use `--timeout` to change that. It rejects a different build. It does not execute the decoded application. No file upload or fresh manual build analysis is needed.

For a capture already supplied, the complete preparation/recovery command is:

```sh
python3 luaq.py process /path/to/protected.lua \
  --capture /path/to/capture.jsonl \
  --out /path/to/new-job
```

All output directories must be new or empty. A long-running application may produce later snapshots with more data; recover the later capture into another output directory as needed.

## Remaining work

The source structurer that replaces register variables, cell captures and instruction dispatch with ordinary source constructs remains to be automated. The prior `clean.lua` reconstruction was manual and is not the output of this workflow. Reports and output filenames preserve that distinction. This is the remaining engine work before a website can truthfully promise “upload obfuscated Lua, download clean Lua.”

## Tests

Run `python3 -m unittest discover -s tests -v`. The suite covers the existing builds, automatic discovery of three randomized layouts, recovery/output comparisons without selecting a pinned profile, capture-file continuation and failure cases.
