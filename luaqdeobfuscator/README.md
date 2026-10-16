# Luaq Deobfuscator 0.3

The [standalone command](STANDALONE.md) now captures application data without a Roblox client or executor:

```sh
python3 luaq.py standalone protected.lua --out result
```

It automates layout discovery, authenticated bootstrap recovery, local loader capture and semantic decoding. Live runs succeeded for the last three randomized builds, with all application constants and packet records recovered and no unresolved regions. The loader's normal HTTPS service remains required. The protected application is disabled during capture.

The earlier [executor/Studio workflow](AUTOMATION.md) is still available as an alternative.

Automatic clean-source reconstruction is **not implemented yet**. This is still capture-assisted devirtualization, not a universal “upload code and receive polished Lua” engine. Existing pinned profiles remain available for the earlier samples, including the older first layout that automatic discovery does not support.

`decoded.luau` contains explicit register operations and instruction dispatch. Automatic conversion of arbitrary applications into concise source-style locals, loops, and named functions remains future work. The two manually refined reconstructions delivered earlier are more readable than this general emission stage. Original variable names and comments are unavailable.

The linked [Luraph devirtualizer](https://github.com/PhoenixZeng/LuraphDeobfuscator/blob/master/src/LuraphDevirtualizer.java) is a reference for the kind of tool requested. This project uses the Luaq recovery work from this session; it does not contain that project's code and does not support Luraph.

## Run

Requires Python 3.10+ and Node.js 22 (tested). The included Luau 0.742 executables are for macOS ARM64; on other systems install Luau and provide executable paths with `--luau` and `--luau-compile`. No package installation is needed. `luaparse` is vendored with its license.

Run commands from this directory:

```sh
python3 luaq.py profiles
python3 luaq.py inspect /path/to/protected.lua
python3 luaq.py capture /path/to/protected.lua --out /path/to/new-capture-kit
```

`inspect` reads the input and hashes it. `capture` exports the matching instrumented runner and Studio place. It does not run them. The exported runner executes the protected application when you run it in its intended environment, capturing plaintext prototype images, regions, and constants. Run executor-dependent applications in the client/executor environment they expect. A server Studio Script has no LocalPlayer; an application can error there even after its data has been captured.

After obtaining the JSONL file, or saving the capture Folder as `.rbxm`/`.rbxmx`:

```sh
python3 luaq.py recover /path/to/capture.jsonl --out /path/to/new-recovery
```

You can also import only, without Luau or Node:

```sh
python3 luaq.py import /path/to/capture.rbxm --out /path/to/new-data
```

Multiple captures from the same build can be passed together. Contradictory plaintext for the same phase, seed, label, kind and index is rejected. Different runtime sessions can produce different layouts even for the same application; this tool does not silently overlay those layouts. An optional `--input /path/to/protected.lua` checks the capture against its supported input profile. Output directories must be new or empty.

Exit codes: 0 success, 2 failure or unsupported capture, 3 unknown input from `inspect`. Success means the requested stage completed; inspect the report to assess coverage.

## Outputs and interpretation

- `decoded.luau`: compiled, generated semantic handlers and a direct dispatch runtime. No encrypted image, packet decoder, or protection-service loader remains. Application-authored HTTP calls, if any, are preserved.
- `report.json`: profile, errors, compilation result, inventory, and coverage flags.
- `source_records.json`: specialized handler bodies per prototype and instruction.
- `undecoded_packets.json`: raw or unverified packet records without generated semantics. Some are padding, but the tool does not assume they are all unreachable. Execution raises an explicit error if it reaches an undecoded instruction.
- `lifted_operands.json`: decoded operand assignments, including register remapping and vectors.
- Per-prototype constants and packets, plaintext images, merged capture, string inventory, and diagnostic logs.

There is no network activity during `inspect`, `import`, `recover`, or the tests. Recovery runs only pinned, bundled operand-bank code against data. It does not execute the recovered application. A capture may still be incomplete when the loader requires an unavailable service response or an uncaptured function region. An execution error does not automatically imply that recovery failed.

## Validation

```sh
python3 -m unittest discover -s tests -v
```

Twenty-three automated tests pass. They regenerate source from both application captures and compile it; compare the first application's 76,443 main-instruction addresses against the previously validated trace hash; compare the second application's behavior in nine bounded fixtures; verify unknown-input and conflicting/mixed-capture rejection; check the fresh round-trip example's exact output; and import/lift all 3,516 verified packets in the third build's bootstrap. These tests use inert local APIs and an approximate Roblox math fixture. They do not establish native Roblox compatibility or complete equivalence on every branch.

The first capture fixture recovers 24 prototypes, 412 constants and 3,169 specialized handlers. It still reports two unavailable raw regions and three missing packet records. The second recovers one prototype, 24 constants and 11 specialized handlers from all 58 packet records, with no unresolved regions. Raw padding/unverified records are reported separately in both cases.

## Fresh round-trip test

Obfuscate **`examples/roundtrip_test.luau`** and return the protected output. It covers captured upvalues, multiple return values, varargs with nil holes, numeric/while/repeat loops, break, tables, colon calls, metamethods, recursion, short-circuiting, pcall/error, strings and arithmetic.

The original emits a deterministic trace ending with **`CHECKSUM=139587`**. `examples/roundtrip_expected.txt` contains the complete expected output. The checksum is only a convenient signal; compare the full trace and source behavior. Producing a new protected build will test profile discovery as well as semantic recovery. This release does not claim to automatically support that new build yet.

## Layout

- `luaq/cli.py`: inspection, capture export, build selection, merging, recovery and reporting.
- `luaq/lift.py`: offline operand lifting through trusted build-specific banks.
- `luaq/emit.cjs`: scope-aware operand/constant substitution and source generation.
- `luaq/profiles/`: build profiles, recovery parsers, semantic maps, bank methods, runtime adapters and capture runners.
- `tests/fixtures/`: application-only captures and inert validation fixtures.
- `vendor/luaparse/`, `bin/`: parser and macOS ARM64 Luau tools with upstream licenses.

A new profile requires extracting the randomized field layout and semantic/operand maps, validating authentication and permutation decoding, producing compatible runtime adapters and capture hooks, then checking recovered behavior against known source. Matching a banner or borrowing another build's opcode numbers is insufficient.

## Third-build test result

The returned obfuscation of the round-trip test has build `33308a56-0fcb-4618-9ac7-ea30a8b5af46`. The renamed executor capture imports correctly: the filename does not determine the profile. Recovery generates 13 application prototypes, 95 constants and 132 specialized semantic handlers. The decoded application's full stdout and both returned values match the original, including checksum **139587**. This is covered by a regression test that regenerates the decoded source from the application capture.

The capture contains 359/362 packet records and leaves one raw region unresolved. All constants were recovered. The observed deterministic run completes without missing handlers; remaining raw/missing records are still reported rather than assumed unreachable. The output retains register storage and dispatch, and new randomized layouts still need separate profiles.

## Fourth input

A fourth profile, build `6dab2007-4ad4-4cdf-8669-3fbbca79bc58`, is now available for capture export and data import. Its bootstrap and capture traversal pass offline checks (43 prototypes, 578 constants, 3,329 verified operand lifts). Its application and clean-source reconstruction still await a runtime capture.

See **AUTOMATION.md** for `process`, `resume --wait`, the generated filenames and the precise remaining clean-source limitation.
