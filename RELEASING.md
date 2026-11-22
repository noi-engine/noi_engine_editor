# Releasing Noi Engine

A release is made of **two deliverables**:

| Deliverable | What it is | Built by |
| --- | --- | --- |
| **The editor** | The desktop app (Linux AppImage, macOS dmg, Windows zip) | this repo, `.github/workflows/release.yml` |
| **A game** | A relocatable archive of a game made with the editor (`<name>-<version>-<os>-<arch>.tar.gz`) | the game project itself (`.github/workflows/release.yml`, copied from `template-basic-2d`), or the editor's **Build Release** button |

The editor itself downloads the other pieces at runtime, from their GitHub releases:

| Piece | Repo | Release asset | Used for |
| --- | --- | --- | --- |
| Engine | `noi_engine` | `noi_engine-<os>-<arch>-release.zip` | copied into each project (`.noi_engine/`) |
| Resources compiler | `resources_compiler` | `resources_compiler.zip` | copied into each project (`.resources_compiler/`), compiles resources for release builds |
| Editor bridge | `noi_engine_editor_bridge` | `noi_engine_editor_bridge-<os>-<arch>.zip` | editor only: runs the scene live in the viewport |
| Template | `template-basic-2d` | the `v<version>` tag archive | starting point of a new project |

## Testing locally before an editor release

The editor is only tagged once it has been tried by hand. Build and run it from the source tree (`cmake --preset debug && cmake --build --preset debug`), try a full round (new project, edit, Save, Play, Build release), and only then push the `v<x.y.z>` tag. The other repositories are released as soon as they change, in the order below.

## Order

Each step needs the previous one to be published, because they download each other.

1. **`noi_engine`**: bump the version, push the tag `v<x.y.z>`. The workflow builds `noi_engine-*-release.zip`.
2. **`resources_compiler`**: if it changed (new component, new field...), push a new tag `v<x.y.z>`. The workflow builds `resources_compiler.zip`.
   Keep in mind: a project always compiles its scenes with the compiler version it declares, so a new engine feature needs a new compiler release *and* the template pointing at it.
3. **`noi_engine_editor_bridge`**: set `noi_engine.min` / `max` in `bridge.json` to the engine versions it was built for, set `version`, push `v<version>` (the tag must equal `bridge.json` `version`).
4. **`template-basic-2d`**: in `noi_engine.template.json` bump `version` and point `noi_engine_version`, `resources_compiler_version`, `editor_bridge_version` at the releases above. Push the tag `v<version>`: the editor downloads the template from that tag, so a version without its tag can't be installed.
5. **`noi_engine_editor`**: bump `project(... VERSION x.y.z)` in `CMakeLists.txt`, push the tag `v<x.y.z>` (it must match).

> Check before tagging: create a project from the template in the editor, press **Compile**, **Play**, then **Build Release**. If the template refers to a version that isn't published, the editor tells you when downloading it.

## What a game release contains

`cmake --build --preset release --target package` (what **Build Release** runs) writes `build/release/packages/<name>-<version>-<os>-<arch>.tar.gz` (`.zip` on Windows):

```
<name>-<version>-linux-x86_64/
  noi_engine_game        the game (run this)
  libs/                  libnoi_engine + the game's scripts
  resources/             compiled resources
```

Unpack it anywhere and run the executable: it finds `resources/` next to itself, whatever the current directory is.

To publish a game on GitHub, push a tag `v<version>` (it must match `version` in `noi_engine.proj.json`): the workflow packages Linux and macOS builds and attaches them to a release.

### Building a release needs

- `cmake`, `ninja`, a C++20 compiler (`clang++`) and `python3` on the machine that builds,
- **`flatc`** (FlatBuffers compiler) in the `PATH` (`apt install flatbuffers-compiler`, `brew install flatbuffers`): the resources compiler runs it.

## Platform status

| Platform | Editor | Game |
| --- | --- | --- |
| Linux x64 | workflow written | built and packaged locally |
| macOS arm64 | workflow written, never run | workflow written, never run |
| Windows x64 | disabled (first run failed, commented out in the workflow) | blocked: `noi_engine` publishes no Windows build yet (its release workflow has the entry commented out), then the game's workflow has a commented entry to enable |

## Known gaps

- Linux packages are archives, not `.deb`/AppImage installers, for the games.
- No code signing / notarization (macOS will warn on first launch).
- The editor's own workflows have not been run on GitHub yet: expect to fix small things on the first tag (use the `workflow_dispatch` trigger to try one).
