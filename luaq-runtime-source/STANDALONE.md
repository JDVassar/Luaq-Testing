# Recovery without Roblox or an executor

```sh
python3 luaq.py standalone /path/to/protected.lua --out /path/to/new-result
```

This command discovers the randomized VM layout, validates the bootstrap, runs the loader in standalone Lune, captures application data, imports it, lifts packet operands, and emits/compiles intermediate decoded Lua. It does not use Macsploit, inject into Roblox, require an open Roblox client, or execute the protected application. A capture-only stop marker is required before the command accepts the result.

**It still uses the loader's normal HTTPS service.** This removes the executor dependency, not the service/network dependency. The command fails with diagnostic logs if the service response or compatibility checks fail. It does not fall back to launching an executor.

## What was tested

Live standalone runs succeeded on three separately randomized builds:

| Sample | Application functions | Constants | Packet records | Unresolved regions |
| --- | ---: | ---: | ---: | ---: |
| Second | 1 | 24/24 | 58/58 | 0 |
| Third: round-trip fixture | 13 | 95/95 | 362/362 | 0 |
| Fourth: lighting script | 3 | 49/49 | 156/156 | 0 |

The round-trip fixture's complete stdout and checksum match the original. The second sample passes its nine bounded behavior fixtures. The fourth sample's manually reconstructed `clean.lua` matches the independently captured local code and the executor reference in five bounded lighting/tween fixtures.

Captures retain raw padding/unverified packets separately; recovering every serialized packet does not mean every packet is executable code. Clean source generation is still a separate manual step. The CLI's `recovery/decoded.luau` remains an intermediate with registers and dispatch, and `clean_source_available` remains false.

## Local runtime

Lune 0.11.0 is bundled for macOS ARM64. Other platforms need the official Lune build and `--lune /path/to/lune`. This is a standalone Lua runtime, not an executor. The included executable is unmodified; its release digest, MPL-2.0 license and source URL are in `bin/LUNE_RELEASE.json`, `bin/LUNE_LICENSE.txt`, and `bin/LUNE_SOURCE_NOTICE.txt`.

The compatibility module supplies a local DataModel and the subset of Roblox datatypes/methods used by the bootstrap probes, including Path2D control points/curves and HttpService JSON. It is **not a complete Roblox game simulator**. It does not read Roblox account cookies. HTTPS requests are limited to service origins found in the authenticated bootstrap. Runtime module access is limited to the loader's net/serde/task modules, and capture writes go to the chosen job directory.

References: [Lune](https://lune-org.github.io/docs/), [Lune Roblox module](https://lune-org.github.io/docs/api-reference/roblox/), [Roblox Path2DControlPoint](https://create.roblox.com/docs/reference/engine/datatypes/Path2DControlPoint), [Roblox Path2D](https://create.roblox.com/docs/reference/engine/classes/Path2D).

## Output

- `standalone_report.json`: executor/client usage flags, service origin and capture location.
- `standalone/capture.jsonl`: local capture with application-execution-skipped marker.
- `standalone/run.log` and `standalone/errors.log`: runtime diagnostics.
- `recovery/`: decoded source, constants, packet inventory and coverage report.
- `profile/`: automatically discovered and validated build adapter.

All output directories must be new or empty. Automatic discovery currently supports the observed 107-statement loader family; the older first sample remains available through its pinned profile, but has not been tested with this standalone command.

## Tests

Default tests use the captured local-run fixtures and make no service requests. They also exercise the compatibility module without networking. To repeat a live check, explicitly run the `standalone` command against a protected input. A service outage or structural change may prevent future live captures even when fixture regressions pass.
