# Engine SDK third-party notices

The Engine SDK release build/link closure uses the dependencies below. Runtime
source dependencies are linked into the artifacts; build-only integration is
identified separately. Complete license texts remain in the named vendored
directories and are copied into every public SDK package and the release
license bundle.

| Dependency | License | Vendored license file |
| --- | --- | --- |
| bgfx | BSD-2-Clause | `third_party/bgfx/LICENSE` |
| bx | BSD-2-Clause | `third_party/bx/LICENSE` |
| bimg | BSD-2-Clause | `third_party/bimg/LICENSE` |
| bgfx.cmake (build-only) | CC0-1.0 | `third_party/bgfx.cmake/LICENSE` |
| cgltf | MIT | `third_party/cgltf/LICENSE` |

No App Host, JavaScript engine, RmlUi, ImGui, MetaHuman/Avatar implementation,
sample model, or product asset is part of the Web, iOS, or Android SDK release
closure. Repository-only dependencies are not release dependencies and are not
listed in the artifact SBOMs.
