# Per-project dev environments: C and C++

Research date: 2026-10-31. The language-independent pattern (templates, the project flake, direnv,
CI rule, pinning) is in [dev-env.md](dev-env.md); this file is the C and C++ half, and it follows
the layout of [dev-env-python.md](dev-env-python.md). Method: claims were followed to the source
that owns them, at the commits in §14 (nixpkgs' cc-wrapper and stdenv, LLVM, CMake, clangd, the VS
Code extensions). The design was built in a throwaway copy of this repo and tested end to end on
helios in the scratchpad (§10) [local]. The result is `templates/cpp/` and `flake.templates.cpp`;
§9 reproduces its files. "Fact" statements carry a citation; **Assessment** marks my judgement.
Familiarity was not used as a reason for any pick.

---

## 1. TL;DR

- **The pattern bends here. Nix supplies the compiler, CMake, clangd and the libraries**, because
  C and C++ have no equivalent of uv that owns the language. `flake.lock` plays the part `uv.lock`
  plays in Python (§4.1).
- **Toolchain: clang from `llvmPackages_22` on both systems**, through
  `pkgs.mkShell.override { inherit (llvm) stdenv; }`. Not the nixpkgs default, LLVM 21: on helios
  (macOS 26.6.2) its ASan hangs before `main` and its TSan segfaults. LLVM 22.1.8 runs ASan, UBSan,
  TSan and LeakSanitizer correctly (§4.4, tested).
- **`hardeningDisable = [ "all" ]` is required, not optional.** With the defaults, cc-wrapper adds
  hidden flags that do not appear in `compile_commands.json`. A CMake Debug build silently compiles
  at `-O2`, and `-fsanitize=undefined` silently stops catching signed overflow (§5.2, both tested).
- **lldb needs one line.** The shell sets `DEVELOPER_DIR` to the Nix SDK, so lldb fails with
  "could not find 'debugserver'". This looks like what you hit in `advanced-networking`. Setting
  `LLDB_DEBUGSERVER_PATH` fixes lldb and lldb-dap; `codesign` is not involved (§6.4, tested).
- **Build system: CMake with Ninja and `CMakePresets.json`.** One command runs everything:
  `cmake --workflow --preset debug` (§4.7).
- **Libraries: nixpkgs `buildInputs` plus `find_package`.** FetchContent with `FIND_PACKAGE_ARGS`
  covers what nixpkgs lacks. Conan and vcpkg only for non-Nix teams (§4.8).
- **One template, `#cpp`, covers both languages:** a C library, a C++ executable and a C test.
  No `#c` alias; a C-only project is four small edits (§4.9, §9.4, tested).
- **CI cannot skip Nix.** The shell holds the compiler, so this is the "Nix in CI wins" branch of
  [dev-env.md §7](dev-env.md): `install-nix-action` plus `nix develop -c …` on `ubuntu-latest`.
  `ubuntu-latest` tops out at clang 18.1.3 against the shell's 22.1.8 (§7).
- **The one sharp edge left:** a build directory keeps old store paths after a toolchain or library
  change, with no warning. Run `cmake --fresh --preset debug` after `nix flake update` (§8).
- **Editor:** clangd has to run inside the shell's environment. A VS Code that has not loaded the
  shell falls back to `/usr/bin/clangd`, which reports false errors (§6.1, tested without VS Code).

---

## 2. How you work in C and C++ today (evidence)

All read-only on 2026-10-30 and 2026-10-31 [local].

- **One real CMake project with a Nix compiler, now gone from disk.** History shows
  `advanced-networking` built into `out/build/clang/` with
  `/nix/store/…-clang-wrapper-21.1.7/bin/clang`. The directory now holds only `assignments/` and
  `general/`, so its presets could not be read [local].
- **Debugging it was a fight.** History has repeated `lldb out/build/clang/advanced-networking`,
  then `xcrun lldb …`, `codesign -s - …`, `find` runs for `liblldb*`, `lldb-server*` and the
  `vadimcn.vscode-lldb` adapter, and `codelldb --port` by hand [local]. §6.4 reproduces a failure
  that fits. The original error message is not in history, so the match is not proven.
- **Small one-file C++ work otherwise.** `numerical-algorithms/general` holds single `.cpp` files
  and `vec2.h`; history has `g++ -std=c++17 process_dataset.cpp` against opencv4 [local].
- **C++ under ROS goes through pixi:** `simExtROS2` and `robomaster_sim` have `CMakeLists.txt` in
  `robotics-escape-room`, the pixi project from [dev-env.md §2](dev-env.md).
- **History counts:** `cmake` 5, `make` 2, `g++` 2, `lldb` 4; `clang`, `gcc`, `meson`, `ninja`,
  `conan`, `vcpkg`, `valgrind`, `gdb`, `clangd`, `clang-format` all 0 [local].
- **helios today:** `/usr/bin/{clang,clangd,cc,gcc}` are Apple's, Command Line Tools only (no
  Xcode), Apple clang 17.0.0 (`clang-1700.6.3.2`). `cmake` is not on `PATH`. `lldb` 21.1.8 comes
  from `home.packages` (`modules/users/ety.nix` L84). No clangd, CMake or debugger extension is in
  `~/.vscode/extensions`; `mkhl.direnv` 0.17.0 is [local].

---

## 3. Candidates and activity

| Candidate                 | Stars | Last push  | Latest                                   | Role                        |
| ------------------------- | ----- | ---------- | ---------------------------------------- | --------------------------- |
| llvm/llvm-project         | 41k   | 2026-10-31 | 23.1.4 (unstable 21.1.8, 22.1.8, 23.1.3) | compiler, clangd, lldb      |
| Kitware/CMake             | 8.1k  | 2026-10-31 | v4.4.5 (unstable 4.4.4, 26.05 4.1.6)     | build system                |
| ninja-build/ninja         | 13k   | 2026-10-18 | unstable 1.13.2                          | build backend               |
| mesonbuild/meson          | 6.7k  | 2026-10-31 | 1.12.1 (unstable 1.12.1)                 | alternative (tested)        |
| xmake-io/xmake            | 12k   | 2026-10-30 | unstable 3.1.2                           | alternative (metadata only) |
| microsoft/vcpkg           | 28k   | 2026-10-31 | 2026.10.16 (unstable 2026.06.24)         | alternative (docs only)     |
| conan-io/conan            | 9.6k  | 2026-10-30 | 2.34.0 (unstable 2.32.0)                 | alternative (docs only)     |
| cpm-cmake/CPM.cmake       | 4.2k  | 2026-09-24 | v0.43.2                                  | alternative (docs only)     |
| catchorg/Catch2           | 22k   | 2026-10-30 | unstable 3.16.0                          | C++ tests (optional)        |
| clangd/vscode-clangd      | 833   | 2026-10-30 | 0.6.0                                    | editor                      |
| llvm `lldb-dap` extension | n/a   | n/a        | 0.4.1 at `llvmorg-22.1.8`                | editor debugger             |

Sources: [gh-meta-cpp] [lock-cpp].

---

## 4. Toolchain, build system and libraries on merit

### 4.1 Does "Nix supplies the manager, the manager supplies the language" hold?

No. In Python, uv owns the interpreter, the dependencies and the lockfile, so Nix only has to
deliver uv. Nothing in C or C++ fills that role:

- **Fact:** vcpkg builds from source using "the same environment, build-tools, compiler flags,
  linker flags" as your project, so a compiler must already exist [vcpkg-bc#L13-16].
- **Fact:** Conan's `conan profile detect` describes the compiler it finds; it does not install one
  [conan-tut#L127-144].
- **So the shell carries the compiler, and Nix is the package manager too.** What stays from the
  pattern: the plain per-project flake on `nixpkgs-unstable`, the two systems, nix-direnv, `.env`
  for secrets, and one `templates.nix`.
- **What changes:**
  - `mkShell`, not `mkShellNoCC` ([dev-env.md §5](dev-env.md)).
  - `flake.lock` is the real lockfile, so `nix flake update` is no longer low risk: it moves the
    compiler and every library.
  - CI needs Nix (§7).
  - Nix's compiler wrapper now sits in the build path, which is the source of most findings below.

### 4.2 clang or gcc

Clang on both systems. **Assessment:** this is not close on helios, and the same compiler everywhere
is worth more than matching each platform's default.

- **Fact:** darwin's stdenv uses clang [plat-notes#L12]; Linux's uses gcc 16.2.0 [lock-cpp].
- **gcc on aarch64-darwin works for a plain build but has no ASan.** Tested in a `gccStdenv` shell:
  a C++23 program built and ran, linked against a Nix store `libstdc++.6.dylib`, and
  `-fsanitize=address` failed with "ld: library not found for -lasan" [local].
- **clangd, clang-tidy and clang-format are LLVM tools.** With clang as the compiler, the flags in
  `compile_commands.json` are ones they parse natively.
- **Fact:** with `pkgs.clangStdenv`, nixpkgs picks the default stdenv on darwin, where clang already
  is, and `llvmPackages.stdenv` on Linux [all-pkgs#L3025]. Evaluated: `clangStdenv == stdenv` on
  darwin, not on Linux [local].

### 4.3 How to get it into the shell

- **Fact:** `mkShellNoCC` is `mkShell.override { stdenv = stdenvNoCC; }` [all-pkgs#L751-752]. The same
  override with an LLVM stdenv is the supported way to change the compiler.
- **Fact:** `llvmPackages_N.stdenv` is the current stdenv with `clang` swapped in
  [llvm-common#L458].
- **A compiler in `packages` does not replace stdenv's.** Tested as the mirror image on darwin: with
  `pkgs.gcc` in `packages` of a plain (clang) `mkShell`, `CC` stayed `clang` while `cc` became gcc
  [local]. On Linux the deleted `c` shell would be the same thing the other way round: clang on
  `PATH`, gcc in `CC`, so CMake picks gcc. That Linux case was not run.
- **Fact:** the wrapper sets `CC=clang` and `CXX=clang++` as bare names [cc-setup#L119-120] [local].
  CMake resolves `CC` once, on first configure, and stores the absolute store path in its cache
  [cmake-cc#L6-11]. This is why §8 exists.

### 4.4 Which LLVM: the sanitizer result

| On helios (macOS 26.6.2)    | LLVM 21.1.8 (default)     | LLVM 22.1.8 | LLVM 23.1.3  | Apple clang 17 (CLT)    |
| --------------------------- | ------------------------- | ----------- | ------------ | ----------------------- |
| UBSan                       | reports                   | reports     | reports      | not run                 |
| ASan (use-after-free)       | **hangs before `main`**   | reports     | reports      | **hangs before `main`** |
| TSan (data race)            | **segfaults (exit 139)**  | reports     | reports      | not run                 |
| LeakSanitizer               | **hangs** (ASan start-up) | reports     | reports      | not run                 |
| lldb in cache.nixos.org     | yes                       | yes         | **no (404)** | n/a                     |
| x86_64-linux tools in cache | yes                       | yes         | yes          | n/a                     |

All runs were in `hardeningDisable = [ "all" ]` shells with a timeout; the 21.1.8 hang was also seen
with default hardening [local].

- **Cause of the hang.** `sample` on the stuck process shows `__asan::InitializeShadowMemory` →
  `get_dyld_hdr` → `dyld_shared_cache_iterate_text` → `_Block_copy` → malloc → `__sanitizer_mz_malloc`
  at 94% CPU [local]. It matches LLVM issue #200447 ("deadlocks during process initialization,
  before `main()`", macOS 26) [llvm-200447].
- **Fix.** LLVM PR #182943 adopts `_dyld_get_dyld_header`, merged 2026-02-24 [llvm-182943] and
  backported to 22.x by #188913 on 2026-03-31 [llvm-188913]. The code is in 22.1.8
  [procmaps#L244-264]. The nixpkgs default stays on 21 [all-pkgs#L3745], and so does the darwin
  stdenv (`llvmVersion = "21"`) [darwin-stdenv#L28].
- **The TSan segfault was not traced.** It disappears in the same LLVM versions; I did not confirm
  it has the same cause.
- **Pick: `llvmPackages_22`.**
  - 23.1.3 passes too, but its lldb is not in the cache for aarch64-darwin at this nixpkgs rev, so
    the first load would compile lldb locally [local].
  - **Assessment:** take the newest version that is fully cached on both systems, and let every tool
    (compiler, clangd, clang-tidy, lldb) share it.
- **When to change the pin.** Drop to `pkgs.llvmPackages` once `llvmVersion` in the darwin stdenv
  reaches 22, or move to 23 when its lldb is cached. If nixpkgs ever removes `llvmPackages_22`,
  evaluation fails loudly with a missing attribute.
- **Cost of the pin on darwin.** The shell closure is 2.3 GiB, because the rest of stdenv still pulls
  LLVM 21 alongside 22 (`llvm-22.1.8-lib` 399 MiB, `llvm-21.1.8-lib` 379 MiB, `apple-sdk-14.4`
  328 MiB) [local].

### 4.5 libc++ or libstdc++, and what differs by system

- **Fact on darwin:** the default is the system libc++, to avoid mixing two implementations
  [plat-notes#L15]. `llvmPackages_N.clang` uses `systemLibcxxClang` there [llvm-common#L212-218]
  [llvm-common#L236-240]. Tested: under clang 22 the headers are still
  `libcxx-21.1.6+apple-sdk-26.5`, and the binary links `/usr/lib/libc++.1.dylib` and
  `/usr/lib/libSystem.B.dylib`, nothing from the store [local]. **A helios binary with no Nix
  libraries runs on any Mac at or above the deployment target.**
- **Fact on Linux:** where stdenv's compiler is GNU, clang is `libstdcxxClang`, using gcc's
  libstdc++ [llvm-common#L212-218]. Evaluated: the Linux shell's clang has no libcxx [local].
- **Do not reach for `libcxxStdenv` on Linux to match macOS.** nixpkgs' C++ libraries on Linux are
  built by gcc against libstdc++, and the two standard libraries' types are different types.
  **Assessment:** the difference is useful: CI builds your code against a second standard library.

### 4.6 The Apple SDK

- **Fact:** the old `darwin.apple_sdk.frameworks` is gone. The default SDK is in stdenv; a different
  one is added to `buildInputs`, and the highest version wins [plat-notes#L68-80]
  [plat-notes#L269-274]. Frameworks need no input of their own.
- **Fact:** defaults are SDK 14.4 and deployment target 14.0 [plat-notes#L134]. Evaluated and
  confirmed with `vtool -show-build`: `minos 14.0`, `sdk 14.4` [local].
- **Fact:** `DEVELOPER_DIR` and `SDKROOT` point at the Nix SDK, and stdenv carries its own `xcrun`
  [plat-notes#L22-28]. So in the shell `xcode-select -p` prints a store path, and `/usr/bin/clang
--version` prints clang 22.1.8, not Apple's [local]. Apple's shims follow `DEVELOPER_DIR`, so an
  absolute path does not get you out of the Nix toolchain from inside the shell.
- **Newer APIs:** `buildInputs = [ pkgs.apple-sdk_26 (pkgs.darwinMinVersionHook "15.0") ];`.
  Tested: `minos 15.0`, `sdk 26.5` [local]. The doc's rule is to change neither unless a build
  fails on an API [plat-notes#L96-102].
- **Fact:** the wrapper adds `-Werror=unguarded-availability` [local]. Calling an API newer than the
  deployment target is a compile error, not a runtime crash.

### 4.7 Build system

- **Pick: CMake with Ninja, driven by `CMakePresets.json`.** Reasons on merit:
  - **Presets replace a wrapper script.** A workflow preset is one command for configure, build and
    test [cmake-presets#L147-150], and the same command runs in the terminal and in CI.
  - **Editor support:** CMake Tools reads presets by default (`cmake.useCMakePresets: auto`)
    [cmt-pkg#L4106-4113].
  - **Library support:** the Nix libraries tested ship CMake config files, found without any path
    setup (`fmt_DIR`, `Catch2_DIR`) [local], through nixpkgs' `NIXPKGS_CMAKE_PREFIX_PATH`
    [cmake-hook#L2-4] [cmake-hook#L129].
  - **vcpkg and Conan both integrate with it**, which keeps the exit open [vcpkg-cmake#L21-25]
    [conan-tut#L127].
- **Meson is the real alternative, and works in the same shell.** Tested with `pkgs.meson` added:
  `meson setup`, `meson compile` and `meson test` passed with clang 22.1.8, and
  `compile_commands.json` was written without being asked [local]. Its language is cleaner than
  CMake's. **Assessment:** it loses on the shared-presets file (it has native and cross files, not
  named workflows [meson-machine]) and on the number of tools that assume CMake. A project with a
  taste for Meson can swap it without touching the flake's toolchain.
- **Make:** no `compile_commands.json` without `bear` (4.2.3 in nixpkgs), and header dependencies
  are yours to write. **Assessment:** fine for one file, a poor default.
- **xmake:** build system and package manager in one, in Lua. **Assessment:** not evaluated past
  its metadata; nothing here needs a second package manager.
- **Ninja over CMake's default Makefiles:** the preset names it, so nothing depends on what `cmake`
  picks. **Assessment** only; no benchmark was run.
- **Module scanning is off.** **Fact:** from C++20, CMake scans sources for `import`
  [cmake-cmp0155#L6-14], which starts `clang-scan-deps` per file [local].
  `CMAKE_CXX_SCAN_FOR_MODULES OFF` removes the step. Delete the line if you use C++ modules.

### 4.8 Libraries

| Option                             | Pinned by                         | Binaries                  | CI without Nix? | Verdict                 |
| ---------------------------------- | --------------------------------- | ------------------------- | --------------- | ----------------------- |
| nixpkgs `buildInputs`              | `flake.lock`                      | cache.nixos.org           | no              | **pick**                |
| FetchContent + `FIND_PACKAGE_ARGS` | tag or hash in `CMakeLists.txt`   | built per build directory | yes, for libs   | **for gaps in nixpkgs** |
| CPM.cmake                          | tag or hash in `CMakeLists.txt`   | built per build directory | yes, for libs   | no                      |
| vcpkg                              | `vcpkg.json` baseline [vcpkg-ver] | from source; own cache    | yes             | non-Nix teams           |
| Conan                              | `conan.lock`                      | ConanCenter, narrow       | yes             | non-Nix teams           |

- **nixpkgs:** one lock for compiler and libraries, prebuilt, and the same `find_package` call any
  other way of installing the library would use. Tested with fmt, zlib and Catch2 [local].
  - **Fact:** both `packages` and `buildInputs` worked in this non-strict shell: `-isystem` for the
    library appeared in `NIX_CFLAGS_COMPILE` either way [local] [cc-setup#L66-74]. Use `buildInputs`:
    the manual documents `packages` as "executable packages" [mkshell-doc#L34].
  - zlib resolved to the Nix store, not the SDK's [local].
  - **Trade-off:** the binary links `/nix/store/…-fmt-12.2.0/lib/libfmt.12.dylib` [local]. It runs
    on your machine while that path exists. Rebuild after a GC, and do not hand the binary to
    anyone; §11 has the route for shipping.
- **FetchContent:** source dependency pinned in the repo.
  - **Fact:** with `FIND_PACKAGE_ARGS`, `FetchContent_MakeAvailable` tries `find_package` first
    [fetchcontent#L176-186]. The same `CMakeLists.txt` then uses the Nix library when it is in
    `buildInputs` and fetches source when it is not. Tested for the first half: with
    `FETCHCONTENT_FULLY_DISCONNECTED=ON` and a bogus URL, it resolved to Nix's fmt and built
    [local]. The fetch half was not run (§13).
- **CPM.cmake:** "a thin wrapper around CMake's FetchContent" [cpm#L11] with "no pre-built binaries"
  [cpm#L166]. **Assessment:** it adds a bootstrap file for a source cache that nix-direnv's rooted
  shell makes less valuable.
- **vcpkg:** "builds from source" by default, with a binary cache you run yourself [vcpkg-bc#L13-19],
  entered through `CMAKE_TOOLCHAIN_FILE` [vcpkg-cmake#L21-25].
- **Conan:** ConanCenter's macOS binaries are built for `apple-clang` [cci-platforms#L70-76]. A Nix
  clang is a different compiler, so **Assessment:** expect "Missing prebuilt package" [conan-faq#L13]
  and `--build=missing` on helios. Both need a second lock and update flow next to `flake.lock`.

### 4.9 One template or two

- **One `templates/cpp/`, one name, `#cpp`.** The toolchain, presets, `.envrc`, clangd setup and CI
  are identical for both languages. Only `LANGUAGES`, the `CMAKE_CXX_` lines and the source file
  differ, so a second directory would be a copy to keep in sync.
- **The sample uses both languages on purpose:** `src/add.c` (a C library), `src/main.cpp` (a C++
  executable), `tests/test_add.c` (a C test). It proves C++ calling C through `extern "C"`, and
  each half is easy to delete.
- **No `#c` alias.** **Fact:** an alias would write the same files, because `nix flake init` copies
  verbatim ([dev-env.md §4.1](dev-env.md)). **Assessment:** a `#c` that hands you a `main.cpp` is
  worse than one name. §9.4 is the conversion.
- **Standards: C23 and C++23, extensions off.** Tested: `-std=c23` and `-std=c++23` under clang 22,
  and C++23 `<print>` on the 14.0 deployment target [local]. Extensions off gives `-std=c23`, not
  `-std=gnu23`, so glibc-only names need an explicit feature macro. Set `CMAKE_C_EXTENSIONS ON` if
  the project is POSIX C and you would rather not write one.

### 4.10 typhon (short)

- Same flake, same LLVM; `nix flake check --all-systems --no-build` evaluates the Linux shell, with
  `NIX_HARDENING_ENABLE` empty and clang-wrapper-22.1.8 as its compiler [local].
- Nothing was run on Linux (§13).

---

## 5. direnv for C and C++: the `.envrc` and the stdenv shell

General nix-direnv behaviour (caching, GC roots, what invalidates the cache) is in
[dev-env.md §6](dev-env.md).

### 5.1 The `.envrc`

There is no language step, so it is `use flake` and `dotenv_if_exists`. No `watch_file` is needed:
nix-direnv already watches `flake.nix` and `flake.lock`. Tested: first load built the shell;
the next printed "Using cached dev shell" in 0.1 s [local].

### 5.2 What a stdenv shell puts in your environment

A `mkShell` is a `stdenv.mkDerivation`, so direnv loads what a build sees. The shell had 164
variables against 70 outside it [local]. The ones that matter:

| Variable                                         | Effect                                                              | What the template does                 |
| ------------------------------------------------ | ------------------------------------------------------------------- | -------------------------------------- |
| `NIX_HARDENING_ENABLE`                           | hidden compiler flags; see below                                    | `hardeningDisable = [ "all" ]`         |
| `DEVELOPER_DIR`, `SDKROOT`                       | Nix SDK; breaks lldb (§6.4)                                         | sets `LLDB_DEBUGSERVER_PATH`           |
| `NIX_CFLAGS_COMPILE`, `NIX_LDFLAGS`              | library paths, invisible to CMake's output (§6.1)                   | clangd must run in the shell           |
| `CC`, `CXX`, `AR`, `LD`, `NM`, `RANLIB`, `STRIP` | bare names found on `PATH`                                          | nothing needed                         |
| `MACOSX_DEPLOYMENT_TARGET`                       | 14.0; becomes `-mmacos-version-min=14.0`                            | nothing needed (§4.6)                  |
| `NIX_ENFORCE_NO_NATIVE=1`                        | strips `-march=native` and `-mcpu=native`, with a warning on stderr | see below                              |
| `SOURCE_DATE_EPOCH=315532800`                    | `__DATE__` expands to `"Jan  1 1980"`                               | nothing; matters for a "built on" line |
| `ZERO_AR_DATE=1`                                 | zero timestamps in archives                                         | nothing needed                         |

`TMPDIR` is not redirected under direnv: it stayed the normal `/var/folders/…` [local].

**Hardening is the serious one.** The default set applies to a shell exactly as to a package build
[make-drv#L358]. On darwin `NIX_DEBUG=1` shows these active: `pic`, `libcxxhardeningfast`, `format`,
`zerocallusedregs`, `strictflexarrays1`, `stackprotector`, `fortify`, `strictoverflow` [local].

- **`fortify` adds `-O2` before your flags** [add-hardening#L95] [stdenv-doc#L1585-1587].
  - Tested: `clang -g` defines `__OPTIMIZE__`, and `clang -O0 -g` does not [local].
  - **Fact:** CMake's Debug flags on clang are `-g` alone (`CMAKE_C_FLAGS_DEBUG:STRING=-g`) [local].
    **So a CMake Debug build in a default `mkShell` is an optimised build**, with variables
    optimised out under the debugger, and `compile_commands.json` shows no sign of it.
  - On darwin it also defines `_FORTIFY_SOURCE=2`. On glibc, compiling at `-O0` with that macro
    prints "`_FORTIFY_SOURCE requires compiling with optimization (-O)`" [glibc-features#L451],
    which `-Werror` turns into a failure. `hardeningDisable` removes both. Not run on Linux.
  - clang gets `fortify`, not `fortify3`, because nixpkgs lists `fortify3` as unsupported for
    clang [clang-nix#L247-249].
- **`strictoverflow` adds `-fwrapv`** [add-hardening#L158-170], which defines signed overflow as
  wrapping.
  - **Fact:** clang then removes `signed-integer-overflow` from the sanitizers that the `undefined`
    group enables [san-args#L586-591]. Named explicitly, the check stays [ubsan-doc#L195-199].
  - Tested on the same program: `-fsanitize=undefined` printed `-2147483648` and no error under
    default hardening, and reported the overflow with hardening off. An explicit
    `-fsanitize=signed-integer-overflow` reports it in both [local].
- **`hardeningDisable = [ "all" ]` over a list of flags.** **Fact:** it empties
  `NIX_HARDENING_ENABLE` [make-drv#L763-781], tested [local]. **Assessment:** the point is that the
  flags in `CMakeLists.txt` and `compile_commands.json` are the flags the compiler gets, so the
  editor and the build agree. Non-hardening wrapper flags stay: `-mmacos-version-min`, `-target`,
  `-fno-omit-frame-pointer`, which sanitizers and profilers want anyway [cc-wrapper#L903-925].
- **For a build you ship,** write hardening flags in `CMakeLists.txt`, where they are visible and
  reviewed, rather than inheriting a wrapper's defaults.

**`-march=native`:** the wrapper drops it and warns "Skipping impure flag" [cc-wrapper-sh#L128-134]
[darwin-stdenv#L55]. If you want it, add `env.NIX_ENFORCE_NO_NATIVE = "0";` to the shell. Not tested
as a flake attribute.

---

## 6. clangd, formatter, linters, debugger, VS Code

### 6.1 clangd and `compile_commands.json`

- **Fact:** `clang-tools` copies each tool to `<name>-unwrapped` and installs a wrapper
  [clang-tools#L37-50]. The wrapper turns `NIX_CFLAGS_COMPILE` and the compiler's `libc-cflags` and
  `libcxx-cxxflags` into `C_INCLUDE_PATH` and `CPLUS_INCLUDE_PATH`, unless you pass `--query-driver`
  [clang-wrapper#L41-56].
- **Fact:** CMake leaves out include directories the compiler searches implicitly
  [cmake-implicit#L6-11]. Nix library paths arrive through the wrapper, so CMake detects them as
  implicit. Tested with `fmt` in `buildInputs`: `CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES` contains its
  include directory, and `compile_commands.json` never mentions fmt [local].
  **So `compile_commands.json` alone does not describe a Nix build. clangd also needs the shell's
  environment.**
- **Fact:** clangd looks for the database in parent directories and in `build/` beneath them
  [clangd-install#L384-388]. Presets write to `build/debug/`, which it does not search, so `.clangd`
  names it [clangd-config#L148-154].

`clangd --check=src/main.cpp`, against the `debug` preset's database [local]:

| clangd                                                  | Environment | No libraries       | With fmt and zlib |
| ------------------------------------------------------- | ----------- | ------------------ | ----------------- |
| clang-tools 22.1.8 (wrapped)                            | dev shell   | **0 errors**       | **0 errors**      |
| clang-tools 22.1.8 + `--query-driver`                   | dev shell   | not run            | 0 errors          |
| clang-tools 22.1.8 (wrapped)                            | plain       | 0 errors           | 3 errors          |
| Apple `/usr/bin/clangd` 17                              | plain       | 2 errors           | not run           |
| Apple clangd + `--query-driver=/nix/store/*/bin/clang*` | plain       | 0 errors           | 3 errors          |
| clang-tools 22.1.8, no `.clangd`                        | dev shell   | 3 errors, fallback | not run           |

- **Assessment:** make the editor load the shell (§6.5) instead of working around it. No
  `--query-driver` in the template: it only rescues the no-library case.
- **clangd's index** goes in `.cache/clangd/index/` next to the database's project
  [clangd-indexing#L66], hence `.cache/` in `.gitignore`.
- **The first clangd start needs a build directory.** Run `cmake --preset debug` once. Tested: with
  no `build/debug` clangd reported 2 errors, and 0 after the workflow ran [local].

### 6.2 clang-format

`.clang-format` holds `BasedOnStyle: LLVM`, which is also clang-format's fallback [cf-rst#L65-69].
**Fact:** clang-format uses the file in the closest parent directory [cf-style#L33-37]. **Assessment:**
the one-line file is worth keeping: it stops that search at the project, and it gives you the obvious
place to change style. The version comes from the same LLVM pin, so
editor, terminal and CI format identically. Tested: `clang-format --dry-run --Werror` passed on the
template and failed on bad code [local]. `.vscode/settings.json` formats on save through clangd.

### 6.3 clang-tidy

- `.clang-tidy` enables `bugprone-*`, `clang-analyzer-*`, `misc-*`, `performance-*`,
  `portability-*` and `readability-*`, minus three noisy checks, with warnings as errors.
- `run-clang-tidy -p build/ci -quiet` ships in `clang-tools`. Tested: exit 0 on the template, exit
  1 on a null dereference [local].
- **A flaw found and fixed while testing.** With `cert-*` on and C++23 `std::println` in `main`,
  tidy failed: "an exception may be thrown in function 'main'" [local], because `println` can throw.
  That is a real but useless finding for a sample, so the template uses `<iostream>` and leaves out
  the `cert-*` aliases.
- **Not in the build.** `CMAKE_CXX_CLANG_TIDY` would run tidy on every compile. **Assessment:** keep
  builds fast. clangd embeds clang-tidy and respects `.clang-tidy` while you type
  [clangd-features#L35-41], and CI runs it once.

### 6.4 Debugger

**lldb, and it needs one line on darwin.**

- **Fact:** nixpkgs builds lldb with `LLDB_USE_SYSTEM_DEBUGSERVER` on darwin [lldb-nix#L143-144], so
  it must find Apple's signed `debugserver`.
- **Fact:** on darwin lldb derives that location from `DEVELOPER_DIR` when it is set and exists
  [lldb-host#L320-331]. In the shell that is the Nix SDK, which has no debugserver. The environment
  variable `LLDB_DEBUGSERVER_PATH` overrides the search [lldb-gdbremote#L3663].

Run on the same `-g -O0` binary, breakpoint in `add` [local]:

| Debugger                              | Environment                               | Outcome                                  |
| ------------------------------------- | ----------------------------------------- | ---------------------------------------- |
| lldb 21.1.8 (home), 22.1.8, Apple     | outside the shell                         | stops, `a=2`, `b=3`                      |
| lldb 22.1.8, or Apple `/usr/bin/lldb` | in the shell                              | "could not find 'debugserver'"           |
| lldb 22.1.8 or 21.1.8                 | in the shell, `LLDB_DEBUGSERVER_PATH` set | stops, `a=2`, `b=3`                      |
| lldb 22.1.8                           | in the shell, `DEVELOPER_DIR` unset       | stops, `a=2`, `b=3`                      |
| `lldb-dap` (DAP client script)        | direnv env with the template's shellHook  | stops at `add.c:3`, stack trace returned |
| `lldb-dap`                            | same, variable unset                      | `launch` request fails                   |

- **Why not `unset DEVELOPER_DIR`:** it works and the compiler survives, through the wrapper's
  fallback to the default SDK [sdk-setup#L9-15] (tested) [local]. But that fallback would quietly
  ignore an `apple-sdk_26` you added to `buildInputs`. Setting one variable has no side effect.
- **`codesign` is a dead end here.** Clang's output is already ad-hoc signed by the linker
  (`flags=0x20002(adhoc,linker-signed)`), and the working runs needed no signing, no Developer Mode
  (`DevToolsSecurity`: disabled) and no `sudo` [local].
- **The path is hard-coded to Command Line Tools,** which helios has. On an Xcode-only Mac,
  debugserver lives under Xcode instead and lldb will print the same error; change that one line.
- **gdb does not work on helios.** nixpkgs offers gdb 17.2 for aarch64-darwin, and it is cached, but
  `gdb -batch -ex run` prints "Don't know how to run. Try "help target"." [local]. Use gdb only on
  Linux.
- **Keep lldb in the shell** even though `home.packages` has one: the shell's matches the compiler,
  and typhon and collaborators get it too.

### 6.5 Sanitizers and memory checking

- **Presets `asan` (`address,undefined`) and `tsan` (`thread`)** set a `SANITIZE` cache variable that
  `CMakeLists.txt` applies to compile and link, so a C-only project has nothing to change. Tested:
  a real overflow aborted `build/asan/app` under UBSan; a leaking test failed the `ci` workflow
  [local].
- **`-fno-sanitize-recover=all` makes UBSan abort** instead of printing and carrying on, so a test
  fails.
- **LeakSanitizer is off by default on macOS.** Tested: the leak test ran silently with exit 0 until
  `ASAN_OPTIONS=detect_leaks=1` was set [local]. The `asan` test preset sets it, and `ci` inherits it.
- **Valgrind is not available on helios.** **Fact:** `meta.broken` is true on darwin
  [valgrind-nix#L133], and `nix build` refuses it [local]. ASan and LSan replace it. `meta.available`
  is true on x86_64-linux [local].
- **`leaks --atExit` is not a substitute.** Run on the same leak, it reported "0 leaks" where
  LeakSanitizer found it [local].

### 6.6 VS Code

- **Extensions:** `llvm-vs-code-extensions.vscode-clangd`, `llvm-vs-code-extensions.lldb-dap`,
  `ms-vscode.cmake-tools`, `mkhl.direnv`. Each is worth having only if the shell reaches it:
  - **Fact:** `clangd.path` defaults to `clangd` [vsc-clangd#L95-98] and `cmake.cmakePath` to `cmake`
    [cmt-pkg#L2383-2386], looked up on the extension host's `PATH`.
  - **Fact:** `mkhl.direnv` writes the environment into the extension host's `process.env`
    [direnv-ext#L196-230], then offers "Restart extensions" [direnv-ext#L363-378]. Click it, or set
    `direnv.restart.automatic` [direnv-pkg#L74-78]. Without this, clangd resolves to
    `/usr/bin/clangd` (§6.1) and CMake Tools finds no `cmake` at all.
  - **Fact:** launching with `code .` from a direnv terminal also works for a new window: the CLI
    passes its environment as `userEnv` [vsc-windows#L1569] and skips resolving a login shell
    [vsc-shellenv#L49-50]. An already open window keeps its environment.
- **lldb-dap over CodeLLDB.** lldb-dap is part of `llvm.lldb`, so the debugger in the editor is the
  pinned one and is covered by the DAP test in §6.4. **Fact:** on darwin its extension tries
  `xcrun -find lldb-dap` and then `PATH` [dap-factory#L22-64]. Command Line Tools also ships a
  `lldb-dap` [local], so outside the shell you would get Apple's. Not exercised in VS Code.
- **Do not add `ms-vscode.cpptools`.** **Fact:** vscode-clangd warns about conflicting extensions by
  default [vsc-clangd#L168]. CMake Tools declares an extension pack, `ms-vscode.cpp-devtools`
  [cmt-pkg#L72-74]; what that installs was not checked. If IntelliSense appears next to clangd,
  disable it for the workspace.

---

## 7. CI

The general rule and runner costs are in [dev-env.md §7](dev-env.md).

- **Pick: `cachix/install-nix-action` on `ubuntu-latest`, everything through `nix develop -c`.** This
  is the branch that note calls "the shell supplies tools the tests run"; here that is the compiler.
- **Can CI skip Nix? Not without losing what the flake pins.**
  - **Fact:** `ubuntu-latest` is Ubuntu 24.04 [runner-readme#L25]. Its newest clang, clang-format
    and clang-tidy are 18.1.3, and its CMake is 3.31.6 [runner-2404#L18-20] [runner-2404#L72].
  - **So** CI without Nix would format, lint and compile with tools four majors older than yours,
    and could not build anything listed in `buildInputs`.
  - **Cost, unmeasured on GitHub:** the Linux inputs are 66 store paths, 531 MiB to download and
    2.2 GiB unpacked, all present in cache.nixos.org [local]. On helios the only local build was the
    trivial `nix-shell-env` derivation [local]. **Assessment:** so a build cache like magic-nix-cache
    adds nothing ([dev-env.md §7](dev-env.md)).
  - **Fact:** install-nix-action turns on `nix-command flakes` unless you override it
    [inix-sh#L60-61].
- **The `ci` preset is `asan` plus `CMAKE_COMPILE_WARNING_AS_ERROR`** [cmake-werror#L4-9], so CI
  runs tests under ASan and UBSan with warnings fatal, while your local `debug` stays forgiving.
- **macOS stays out of CI** ([dev-env.md §7](dev-env.md)). helios is your macOS test. That split now
  has content: CI is Linux and libstdc++, helios is darwin and libc++.

---

## 8. What is pinned where

The `flake.lock` and CI-action rows are in [dev-env.md §8](dev-env.md); here `flake.lock` carries
much more.

| What                                          | Pinned by                                       | Update with                               |
| --------------------------------------------- | ----------------------------------------------- | ----------------------------------------- |
| clang, clangd, clang-format, clang-tidy, lldb | `llvmPackages_22` in `flake.nix` + `flake.lock` | edit the attribute; `nix flake update`    |
| CMake, Ninja                                  | `flake.lock`                                    | `nix flake update`                        |
| Libraries in `buildInputs`                    | `flake.lock`                                    | `nix flake update`                        |
| Apple SDK, deployment target                  | stdenv defaults, or `buildInputs`               | add `apple-sdk_N`, `darwinMinVersionHook` |
| Language standards, warnings                  | `CMakeLists.txt`                                | edit                                      |
| Build configurations                          | `CMakePresets.json`                             | edit                                      |
| Format, lint rules                            | `.clang-format`, `.clang-tidy`                  | edit                                      |
| FetchContent sources, if any                  | tag or hash in `CMakeLists.txt`                 | edit                                      |

**After `nix flake update`, run `cmake --fresh --preset debug` for each preset you use, or
`rm -rf build`.** This is the one place the design is worse than Python, where `uv sync` rebuilds a
stale venv by itself.

- **Tested:** after moving the shell from LLVM 22 to 23, `cmake --preset debug` and a build
  succeeded and `CMAKE_C_COMPILER` still named `clang-wrapper-22.1.8`. No warning. `--fresh` moved
  it to 23.1.3 [local]. **Fact:** `CC` is read on first configuration only [cmake-cc#L6-11];
  `--fresh` removes the cache [cmake-man#L207-212].
- **Tested for libraries:** the same with `fmt_DIR`, which kept the old store path until `--fresh`
  [local]. Going the other way, a cache pointing at a different fmt than the shell's headers gave a
  linker error, not a silent mix [local].
- **Failure mode if you forget:** the old compiler keeps working until the store path is
  garbage-collected, then the build stops with "No such file or directory" and the missing path
  (simulated by editing `rules.ninja`) [local]. It fails loudly; it never miscompiles.
- **Why not automate it.** A compiler path in the preset (`$env{NIX_CC}/bin/clang`) would only cover
  the compiler, and a stamp check in `.envrc` would delete build directories behind CMake Tools'
  back. **Assessment:** a documented command beats both. The template's `welcomeText` carries it.

---

## 9. The worked template

Every file below ran as written, from a fresh `nix flake init` (§10). The sample is deliberately
tiny: it is there to be replaced.

### 9.1 Files

Addition to `modules/flake/templates.nix`, next to `python`:

````nix
  flake.templates.cpp = {
    path = ../../templates/cpp;
    description = "C and C++ project: Nix supplies the compiler, CMake, clangd and the libraries";
    welcomeText = ''
      # C and C++ project

      Next steps:

      ```sh
      direnv allow                     # loads clang, CMake, Ninja, clangd from flake.nix
      cmake --workflow --preset debug  # configure, build, test
      ./build/debug/app
      ```

      Rename `app` in `CMakeLists.txt`. After `nix flake update`, run
      `cmake --fresh --preset debug`: build dirs cache the old store paths.
    '';
  };
````

`templates/cpp/flake.nix`:

```nix
{
  description = "C/C++ dev shell: Nix supplies the compiler, CMake, clangd and the libraries";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;
      forAllSystems =
        f: lib.genAttrs [ "aarch64-darwin" "x86_64-linux" ] (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (
        pkgs:
        let
          # Pinned above the nixpkgs default (LLVM 21): that version's ASan
          # hangs and its TSan crashes on macOS 26. All tools share this version.
          llvm = pkgs.llvmPackages_22;
        in
        {
          default = pkgs.mkShell.override { inherit (llvm) stdenv; } {
            packages = [
              llvm.clang-tools # clangd, clang-format, clang-tidy
              llvm.lldb
              pkgs.cmake
              pkgs.ninja
            ];

            # Libraries the project links; CMake finds them with find_package.
            buildInputs = [ ];

            # cc-wrapper's default flags are invisible in compile_commands.json
            # and change the build: -O2 on Debug builds, and -fwrapv, which
            # drops signed overflow from -fsanitize=undefined.
            hardeningDisable = [ "all" ];

            # DEVELOPER_DIR points at the Nix SDK, so lldb cannot find Apple's
            # debugserver on its own.
            shellHook = lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
              export LLDB_DEBUGSERVER_PATH=/Library/Developer/CommandLineTools/Library/PrivateFrameworks/LLDB.framework/Versions/A/Resources/debugserver
            '';
          };
        }
      );

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);
    };
}
```

`templates/cpp/.envrc`:

```bash
use flake

# Secrets go in .env (gitignored), never in this file.
dotenv_if_exists
```

`templates/cpp/.gitignore` (there is no global ignore, so this is the whole list):

```gitignore
.DS_Store
.direnv/
.env
.cache/
build/
result
```

`templates/cpp/CMakeLists.txt`:

```cmake
cmake_minimum_required(VERSION 3.31...4.4)

# `nix flake init` cannot substitute a name: rename `app` here.
# C only: drop CXX here, and the CMAKE_CXX_ lines below.
project(app VERSION 0.1.0 LANGUAGES C CXX)

set(CMAKE_C_STANDARD 23)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_SCAN_FOR_MODULES OFF) # on by default for C++20 and later

add_compile_options(-Wall -Wextra -Wpedantic)

# Set by the asan and tsan presets. Applies to every target below.
set(SANITIZE "" CACHE STRING "Value for -fsanitize=, e.g. address,undefined")
if(SANITIZE)
  add_compile_options(-fsanitize=${SANITIZE} -fno-sanitize-recover=all)
  add_link_options(-fsanitize=${SANITIZE})
endif()

add_library(core src/add.c)
target_include_directories(core PUBLIC include)

add_executable(app src/main.cpp)
target_link_libraries(app PRIVATE core)

include(CTest)
if(BUILD_TESTING)
  add_executable(test_add tests/test_add.c)
  target_link_libraries(test_add PRIVATE core)
  add_test(NAME test_add COMMAND test_add)
endif()
```

- `3.31...4.4`: the lower bound is what `ubuntu-latest` has, and what preset version 10 needs
  [cmake-presets#L460-463]; the upper bound asks for that version's policies.
- `add_compile_options` comes before the targets on purpose: it applies only to targets defined
  after it.
- `include(CTest)` provides `BUILD_TESTING`, so the tests can be switched off.

`templates/cpp/CMakePresets.json`:

```json
{
  "version": 10,
  "cmakeMinimumRequired": { "major": 3, "minor": 31, "patch": 0 },
  "configurePresets": [
    {
      "name": "base",
      "hidden": true,
      "generator": "Ninja",
      "binaryDir": "${sourceDir}/build/${presetName}",
      "cacheVariables": { "CMAKE_EXPORT_COMPILE_COMMANDS": "ON" }
    },
    {
      "name": "debug",
      "inherits": "base",
      "cacheVariables": { "CMAKE_BUILD_TYPE": "Debug" }
    },
    {
      "name": "release",
      "inherits": "base",
      "cacheVariables": { "CMAKE_BUILD_TYPE": "Release" }
    },
    {
      "name": "asan",
      "inherits": "debug",
      "cacheVariables": { "SANITIZE": "address,undefined" }
    },
    {
      "name": "tsan",
      "inherits": "debug",
      "cacheVariables": { "SANITIZE": "thread" }
    },
    {
      "name": "ci",
      "inherits": "asan",
      "cacheVariables": { "CMAKE_COMPILE_WARNING_AS_ERROR": "ON" }
    }
  ],
  "buildPresets": [
    { "name": "debug", "configurePreset": "debug" },
    { "name": "release", "configurePreset": "release" },
    { "name": "asan", "configurePreset": "asan" },
    { "name": "tsan", "configurePreset": "tsan" },
    { "name": "ci", "configurePreset": "ci" }
  ],
  "testPresets": [
    {
      "name": "base",
      "hidden": true,
      "output": { "outputOnFailure": true }
    },
    { "name": "debug", "inherits": "base", "configurePreset": "debug" },
    {
      "name": "asan",
      "inherits": "base",
      "configurePreset": "asan",
      "environment": { "ASAN_OPTIONS": "detect_leaks=1" }
    },
    { "name": "tsan", "inherits": "base", "configurePreset": "tsan" },
    { "name": "ci", "inherits": "asan", "configurePreset": "ci" }
  ],
  "workflowPresets": [
    {
      "name": "debug",
      "steps": [
        { "type": "configure", "name": "debug" },
        { "type": "build", "name": "debug" },
        { "type": "test", "name": "debug" }
      ]
    },
    {
      "name": "ci",
      "steps": [
        { "type": "configure", "name": "ci" },
        { "type": "build", "name": "ci" },
        { "type": "test", "name": "ci" }
      ]
    }
  ]
}
```

- `binaryDir` per preset lets `debug`, `asan` and `release` coexist without reconfiguring.
- `base` and hidden presets exist so each configuration states only its difference.
- `CMakeUserPresets.json` is the standard place for personal presets; add it to `.gitignore` if you
  create one.

`templates/cpp/.clangd`:

```yaml
CompileFlags:
  CompilationDatabase: build/debug
```

`templates/cpp/.clang-format`:

```yaml
BasedOnStyle: LLVM
```

`templates/cpp/.clang-tidy`:

```yaml
Checks: >
  bugprone-*,
  clang-analyzer-*,
  misc-*,
  performance-*,
  portability-*,
  readability-*,
  -bugprone-easily-swappable-parameters,
  -misc-include-cleaner,
  -readability-identifier-length
WarningsAsErrors: "*"
HeaderFilterRegex: "(include|src)/.*"
```

`templates/cpp/include/add.h`:

```c
#ifndef ADD_H
#define ADD_H

#ifdef __cplusplus
extern "C" {
#endif

int add(int a, int b);

#ifdef __cplusplus
}
#endif

#endif
```

`templates/cpp/src/add.c`:

```c
#include "add.h"

int add(int a, int b) { return a + b; }
```

`templates/cpp/src/main.cpp`:

```cpp
#include "add.h"

#include <iostream>

int main() { std::cout << "2 + 3 = " << add(2, 3) << '\n'; }
```

`templates/cpp/tests/test_add.c` (plain `assert` plus CTest, so the template has no test dependency;
`#undef NDEBUG` keeps asserts alive in Release):

```c
#undef NDEBUG // keep assert() in every build type
#include "add.h"

#include <assert.h>

int main(void) {
  assert(add(2, 3) == 5);
  return 0;
}
```

`templates/cpp/.vscode/settings.json`:

```json
{
  "[c]": {
    "editor.defaultFormatter": "llvm-vs-code-extensions.vscode-clangd",
    "editor.formatOnSave": true
  },
  "[cpp]": {
    "editor.defaultFormatter": "llvm-vs-code-extensions.vscode-clangd",
    "editor.formatOnSave": true
  }
}
```

`templates/cpp/.vscode/extensions.json`:

```json
{
  "recommendations": [
    "llvm-vs-code-extensions.vscode-clangd",
    "llvm-vs-code-extensions.lldb-dap",
    "ms-vscode.cmake-tools",
    "mkhl.direnv"
  ]
}
```

`templates/cpp/.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "app (debug preset)",
      "type": "lldb-dap",
      "request": "launch",
      "program": "${workspaceFolder}/build/debug/app",
      "cwd": "${workspaceFolder}"
    }
  ]
}
```

`templates/cpp/.github/workflows/ci.yml` (passes `actionlint` 1.7.12; not run on GitHub):

```yaml
name: ci

on:
  push:
    branches: [main]
  pull_request:
  workflow_dispatch:

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7.0.1
      - uses: cachix/install-nix-action@v31.11.3
      # The shell holds the compiler, so CI uses the same one as you do.
      - run: nix develop -c cmake --workflow --preset ci
      - run: nix develop -c sh -c "git ls-files '*.c' '*.cpp' '*.h' | xargs clang-format --dry-run --Werror"
      - run: nix develop -c run-clang-tidy -p build/ci -quiet
```

### 9.2 Adding it to nix-config

Done: the files above are `templates/cpp/`, and the block is in `modules/flake/templates.nix`. Check
it with:

```sh
cd ~/nix-config
nix flake check                           # prints "checking template 'templates.cpp'"
nix fmt
```

Verified in this repo on top of `578e432` [local]:

- `nix flake check` passed, including "checking template 'templates.cpp'".
- `nix fmt` changed nothing, and init wrote every file including `.envrc`, `.clangd` and the dotted
  directories.
- From a project created with `nix flake init -t ~/nix-config#cpp`, the `debug` and `ci` workflows,
  the `tsan` and `release` flows, `clang-format`, `run-clang-tidy` and `clangd --check` all passed.

### 9.3 Creating a project

```sh
mkdir ~/Documents/projects/foo && cd ~/Documents/projects/foo
git init                                    # first: see dev-env-python.md §9.3
nix flake init -t ~/nix-config#cpp          # or -t github:Ety0011/nix-config#cpp once pushed
direnv allow
cmake --workflow --preset debug             # configure, build, test
./build/debug/app
git add -A && git commit -m "chore: project skeleton"
```

Then rename `app` in `CMakeLists.txt` and `.vscode/launch.json`. Daily commands:

```sh
cmake --build --preset debug                # rebuild
cmake --workflow --preset ci                # what CI runs: ASan, UBSan, warnings as errors
cmake --preset tsan && cmake --build --preset tsan && ctest --preset tsan
lldb build/debug/app
git ls-files '*.c' '*.cpp' '*.h' | xargs clang-format -i
run-clang-tidy -p build/debug -quiet
```

Every line was run in the scratchpad, using `direnv exec . <cmd>` in place of the interactive hook
[local], except the `github:` form.

### 9.4 C only

Tested end to end, including the `ci` workflow and clangd [local]:

1. In `CMakeLists.txt`, change `LANGUAGES C CXX` to `LANGUAGES C`, and delete the four
   `CMAKE_CXX_` lines.
2. Replace `src/main.cpp` with `src/main.c`, and change `add_executable(app src/main.c)`.
3. In `include/add.h`, delete the two `#ifdef __cplusplus` blocks.
4. Keep `.vscode`'s `[cpp]` block or delete it; it does nothing either way.

The presets need no edit, because `SANITIZE` is one variable and not separate C and C++ flags.
There is no "manually-specified variables were not used" warning [local].

### 9.5 Adding a library

Tested with fmt, zlib and Catch2 [local].

```nix
buildInputs = [ pkgs.fmt pkgs.catch2_3 pkgs.zlib ];
```

```cmake
find_package(fmt REQUIRED)
find_package(ZLIB REQUIRED)
target_link_libraries(app PRIVATE core fmt::fmt ZLIB::ZLIB)

# C++ tests with Catch2, inside if(BUILD_TESTING):
find_package(Catch2 3 REQUIRED)
include(Catch)
add_executable(test_cpp tests/test_cpp.cpp)
target_link_libraries(test_cpp PRIVATE core Catch2::Catch2WithMain)
target_compile_options(test_cpp PRIVATE -Wno-c2y-extensions)
catch_discover_tests(test_cpp)
```

- **Fact:** the `-Wno-c2y-extensions` line is needed. Catch2's `TEST_CASE` expands to `__COUNTER__`
  in your own file, and clang 22 with `-Wpedantic` reports it, so the `ci` preset failed with
  `error: '__COUNTER__' is a C2y extension [-Werror,-Wc2y-extensions]`. With the line, it passed
  [local].

For a library nixpkgs lacks:

```cmake
include(FetchContent)
FetchContent_Declare(thing
  GIT_REPOSITORY https://github.com/owner/thing.git
  GIT_TAG <full commit hash>
  FIND_PACKAGE_ARGS)
FetchContent_MakeAvailable(thing)
```

Use a full commit hash rather than a tag: tags can move. The `find_package` half of this was tested;
the download half was not (§13).

### 9.6 Existing projects

**Assessment:** nothing on disk is worth migrating. `numerical-algorithms` and `edge-computing` are
finished coursework. Leave the ROS C++ under pixi (§11).

---

## 10. What was tested (helios, aarch64-darwin, macOS 26.6.2, Nix 2.34.9, direnv 2.37.1)

All runs were in the scratchpad, with direnv's allow list redirected there (`XDG_DATA_HOME`), so
nothing in `~/.local/share/direnv` or the repo changed [local]. nixpkgs-unstable was locked at
`885ba4d038f1`, 2026-10-30.

| Command                                                                       | Outcome                                                                                |
| ----------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| clone at `578e432`; add `templates/cpp`; `nix flake check --no-build`         | "checking template 'templates.cpp'… all checks passed"                                 |
| `nix fmt` on the clone                                                        | 0 files changed                                                                        |
| `git init`; `nix flake init -t <clone>#cpp`                                   | 22 "wrote" lines (files and directories), all staged, welcomeText rendered             |
| `direnv allow`; `cmake --workflow --preset debug`                             | builds; 1/1 tests; `./build/debug/app` prints `2 + 3 = 5`                              |
| `direnv exec . true` (second load)                                            | "Using cached dev shell", 0.1 s                                                        |
| `cmake --workflow --preset ci`                                                | 1/1 tests under ASan, UBSan, warnings as errors                                        |
| `asan`, `tsan`, `release` presets                                             | configure and build; tests pass in `asan`, `tsan`                                      |
| `clang`, `clang -g`, `clang -O0 -g`, `-g -O0`, default hardening              | `__OPTIMIZE__` set for the first two, not the others; `_FORTIFY_SOURCE=2` in all four  |
| same, `hardeningDisable = [ "fortify" ]`                                      | `__OPTIMIZE__` never set                                                               |
| `-fsanitize=undefined` on `INT_MAX + 1`, default hardening                    | prints `-2147483648`, no report                                                        |
| same, `hardeningDisable = [ "all" ]`                                          | "signed integer overflow" report                                                       |
| ASan, TSan, LSan under LLVM 21.1.8, 22.1.8, 23.1.3; ASan under Apple clang 17 | see §4.4                                                                               |
| `sample` on the hung ASan process                                             | stack in §4.4                                                                          |
| `clangd --check` across the six setups                                        | see §6.1                                                                               |
| `clang-format --dry-run --Werror`                                             | exit 0 on the template; "code should be clang-formatted" on bad code                   |
| `run-clang-tidy -p build/ci -quiet`                                           | exit 0 on the template; exit 1 on a null dereference                                   |
| lldb, Apple lldb, lldb-dap across environments                                | see §6.4                                                                               |
| introduced overflow, run `build/asan/app`                                     | UBSan abort with file and line                                                         |
| leaking test, `cmake --workflow --preset ci`                                  | "LeakSanitizer: detected memory leaks", 0% tests passed                                |
| fmt, zlib, Catch2 in `buildInputs`, `ci` workflow                             | pass, once `-Wno-c2y-extensions` is added; both CTest entries ran                      |
| same libraries in `packages`                                                  | builds; `NIX_CFLAGS_COMPILE` still has fmt                                             |
| `FetchContent_Declare … FIND_PACKAGE_ARGS`, bogus URL, fully disconnected     | resolves to Nix's `fmt_DIR`, builds                                                    |
| LLVM 22 → 23 in place, `cmake --preset debug`, build                          | succeeds, cache keeps clang 22; `--fresh` switches to 23.1.3                           |
| `fmt` → `fmt_11` in place                                                     | `fmt_DIR` stale until `--fresh`                                                        |
| compiler path missing from `rules.ninja`                                      | "No such file or directory", build stops                                               |
| C-only conversion (§9.4)                                                      | `ci` and `debug` workflows pass, no CMake warnings, clangd 0 errors, clang-tidy exit 0 |
| `pkgs.gcc` in `packages` of a plain (clang) `mkShell`                         | `CC=clang`, but `cc` is gcc 16.2.0                                                     |
| `apple-sdk_26` + `darwinMinVersionHook "15.0"`                                | `minos 15.0`, `sdk 26.5`                                                               |
| `gccStdenv` shell                                                             | C++23 builds and runs; `-fsanitize=address` fails, "library not found for -lasan"      |
| `gdb -batch -ex run`                                                          | "Don't know how to run."                                                               |
| Meson 1.12.1 in the same shell                                                | setup, compile, test pass; `compile_commands.json` written                             |
| `nix flake check` and `nix fmt` in the project                                | all checks passed, 0 files changed                                                     |
| `nix flake check --no-build --all-systems` in the project                     | both systems evaluate                                                                  |
| `actionlint ci.yml`                                                           | ok                                                                                     |
| fresh clone, near-empty `env -i`, `nix develop -c` for each CI step           | all three steps pass                                                                   |

Template-mechanics runs (init, the `git init` order): [dev-env.md §9](dev-env.md).

---

## 11. When the runner-ups win

- **pixi:** the ROS project and anything else on conda-forge or RoboStack, where the stack brings
  its own compilers and libraries. Your robotics C++ stays there
  ([dev-env-python.md §11](dev-env-python.md)).
- **Meson:** you prefer its language and the project needs no CMake-based tooling. Keep the flake,
  swap `pkgs.cmake` for `pkgs.meson`.
- **FetchContent as the main route:** collaborators without Nix. CI can then drop Nix too, at the
  cost of the version gap in §7.
- **vcpkg or Conan:** a team already on them, or a Windows target. Keep the Nix shell for tools only.
- **A Nix package (`packages.default = llvm.stdenv.mkDerivation …`, not tested):** you ship the
  program, or deploy it to typhon. Trigger: the first time someone else must run the binary.
- **gcc:** a project that targets gcc specifically, or a Linux-only ABI. Add a second `devShells`
  entry with `pkgs.gccStdenv`.

---

## 12. Side findings

Problems in the pattern note, left unchanged as instructed. They need your decision.

- **[dev-env.md §11](dev-env.md) would produce a broken shell.** Its `c` bullet says "`mkShell` …,
  clang-tools, cmake and ninja, as in the deleted shell". That shell has hidden `-O2` on Debug,
  UBSan missing signed overflow, ASan hanging on helios, broken lldb, and most likely gcc as `CC` on
  Linux (§4.3, §4.4, §5.2, §6.4). It also names the template `c` and `templates/c/`; this design is
  `cpp`, as you asked.
- **[dev-env.md §10](dev-env.md)'s features.md row** says "`c` waits for its trigger", same naming.
- **[dev-env.md §5](dev-env.md)'s "Update cadence"** ("low risk") is true of Python only. Here the
  lock moves the compiler (§4.1, §8).
- **helios' Command Line Tools are stale for sanitizers.** Apple clang `clang-1700.6.3.2` hangs on
  ASan. **Fact:** upstream reports say Xcode 26.4 and 26.5 fix it [llvm-200447]. A Command Line Tools
  update should fix `/usr/bin/clang`. Not tried.
- **`lldb` in `modules/users/ety.nix` L84** works outside a dev shell, and is shadowed inside one.
  It is still useful for one-off binaries.

---

## 13. Limitations (not verified)

- **Nothing ran on Linux,** because Colima was stopped and typhon is not installed. On Linux these
  rest on evaluation and docs only: every sanitizer result, clangd, lldb, the libstdc++ path, the
  glibc fortify warning.
- **The CI workflow was not run on GitHub.** It passes actionlint, and its three steps ran from a
  fresh clone with a near-empty environment on darwin. Timing and disk on a runner are unmeasured.
- **VS Code was not opened.** clangd was run with `--check`, lldb-dap through a small DAP client, and
  CMake Tools not at all. The extension behaviour in §6.6 comes from their source.
- **FetchContent's download, CPM, vcpkg and Conan were not run.** Building third-party source was
  outside what this session was allowed to do, so those verdicts rest on their docs and are marked
  as such in §3. The Conan "expect source builds on helios" line is an inference.
- **The TSan segfault under LLVM 21.1.8** was observed, not traced.
- **One unexplained lldb failure.** The first run with `DEVELOPER_DIR` unset gave "attach failed
  (attached to process, but could not pause execution)". It did not recur in the later runs in
  §6.4 or in three deliberate repeats.
- **`advanced-networking`'s original failure** is not in history, so §6.4 fits it but does not prove
  it. Part of the history could not be read in context during this research.
- **No build-speed numbers.** Ninja over Makefiles, and scanning off, are assessments.
- **Not tested:** `github:` template form; `NIX_ENFORCE_NO_NATIVE = "0"` as a flake attribute; an
  Xcode-only Mac; C++ modules; `CMAKE_C_EXTENSIONS OFF` against glibc-only names.
- **Sizes:** the 2.3 GiB shell is a darwin number. The Linux 2.2 GiB sums the toolchain's inputs from
  cache.nixos.org and is not the shell's own closure.

---

## 14. Sources

Metadata and local: [gh-meta] and [local] as in [dev-env.md §14](dev-env.md).

- [gh-meta-cpp] `gh api repos/<o>/<r>` and `…/releases/latest` on 2026-10-31.
- [lock-cpp] `nix eval` at nixpkgs `885ba4d038f10c3d17d7a92e8c3cc185b99c9158` (2026-10-30), both
  systems: clang-tools 21.1.8 (default), `llvmPackages_22` 22.1.8, `llvmPackages_23` 23.1.3,
  cmake 4.4.4, ninja 1.13.2, meson 1.12.1, xmake 3.1.2, conan 2.32.0, vcpkg 2026.06.24, gcc 16.2.0,
  gdb 17.2, valgrind 3.27.1, catch2 3.16.0, fmt 12.2.0, bear 4.2.3. `darwinSdkVersion` 14.4,
  `darwinMinVersion` 14.0, `apple-sdk_26` 26.5. nix-config's 26.05 input @ `d592aacecd35`:
  clang-tools 21.1.8, lldb 21.1.8, cmake 4.1.6. Cache presence by `curl` of `<hash>.narinfo`
  on cache.nixos.org; closure sizes by `nix path-info --store https://cache.nixos.org -r --json`.
- [local] helios, 2026-10-30 and 2026-10-31: `~/Documents` project layout; `~/.zsh_history` line
  counts; `~/.vscode/extensions`; this repo @ `578e432`; every test in §10.

nixpkgs @ `885ba4d038f10c3d17d7a92e8c3cc185b99c9158`, under
https://github.com/NixOS/nixpkgs/blob/885ba4d038f10c3d17d7a92e8c3cc185b99c9158/

- [mkshell-doc] doc/build-helpers/special/mkshell.section.md (L32-36, L41)
- [all-pkgs] pkgs/top-level/all-packages.nix (L751-752, L3022, L3025-3026, L3745)
- [plat-notes] doc/stdenv/platform-notes.chapter.md (L12, L15, L18-28, L68-80, L96-102, L120-125,
  L134, L269-274)
- [stdenv-doc] doc/stdenv/stdenv.chapter.md (L1585-1587)
- [make-drv] pkgs/stdenv/generic/make-derivation.nix (L358, L763-781)
- [darwin-stdenv] pkgs/stdenv/darwin/default.nix (L28, L55)
- [add-hardening] pkgs/build-support/cc-wrapper/add-hardening.sh (L95, L158-170)
- [cc-wrapper] pkgs/build-support/cc-wrapper/default.nix (L903-925)
- [cc-wrapper-sh] pkgs/build-support/cc-wrapper/cc-wrapper.sh (L128-134)
- [cc-setup] pkgs/build-support/cc-wrapper/setup-hook.sh (L66-74, L114-120)
- [sdk-setup] pkgs/build-support/wrapper-common/darwin-sdk-setup.bash (L7-15)
- [clang-nix] pkgs/development/compilers/llvm/common/clang/default.nix (L247-249)
- [clang-tools] pkgs/development/compilers/llvm/common/clang-tools/default.nix (L37-50)
- [clang-wrapper] pkgs/development/compilers/llvm/common/clang-tools/wrapper (L41-56)
- [llvm-common] pkgs/development/compilers/llvm/common/default.nix (L212-218, L236-240, L458)
- [lldb-nix] pkgs/development/compilers/llvm/common/lldb/default.nix (L143-144)
- [cmake-hook] pkgs/by-name/cm/cmake/setup-hook.sh (L2-4, L129)
- [valgrind-nix] pkgs/by-name/va/valgrind/package.nix (L133)

LLVM @ `llvmorg-22.1.8` (`ca7933e47d3a3451d81e72ac174dcb5aa28b59d1`), under
https://github.com/llvm/llvm-project/blob/ca7933e47d3a3451d81e72ac174dcb5aa28b59d1/

- [procmaps] compiler-rt/lib/sanitizer_common/sanitizer_procmaps_mac.cpp (L244-264)
- [san-args] clang/lib/Driver/SanitizerArgs.cpp (L586-591)
- [ubsan-doc] clang/docs/UndefinedBehaviorSanitizer.rst (L195-199)
- [cf-rst] clang/docs/ClangFormat.rst (L65-69)
- [cf-style] clang/docs/ClangFormatStyleOptions.rst (L33-37)
- [lldb-gdbremote] lldb/source/Plugins/Process/gdb-remote/ProcessGDBRemote.cpp (L3663, L3683, L3736)
- [lldb-host] lldb/source/Host/macosx/objcxx/HostInfoMacOSX.mm (L133, L320-331)
- [dap-factory] lldb/tools/lldb-dap/extension/src/debug-adapter-factory.ts (L22-64)
- [llvm-200447] https://github.com/llvm/llvm-project/issues/200447 (and comments)
- [llvm-182943] https://github.com/llvm/llvm-project/pull/182943
- [llvm-188913] https://github.com/llvm/llvm-project/pull/188913

clangd @ `ae5866d4552e30a173b8e9c3cec872a82e4c0120`, under
https://github.com/llvm/clangd-www/blob/ae5866d4552e30a173b8e9c3cec872a82e4c0120/

- [clangd-config] config.md (L148-154)
- [clangd-install] installation.md (L384-388)
- [clangd-features] features.md (L35-41)
- [clangd-indexing] design/indexing.md (L66)

CMake @ `v4.4.4` (`2e0b3aec14fe2e3e555faac4698e281749aae4b5`), under
https://github.com/Kitware/CMake/blob/2e0b3aec14fe2e3e555faac4698e281749aae4b5/

- [cmake-presets] Help/manual/cmake-presets.7.rst (L147-150, L426, L460-463)
- [cmake-man] Help/manual/cmake.1.rst (L207-212)
- [cmake-cc] Help/envvar/CC.rst (L6-11)
- [cmake-cmp0155] Help/policy/CMP0155.rst (L6-14)
- [cmake-werror] Help/variable/CMAKE_COMPILE_WARNING_AS_ERROR.rst (L4-9)
- [cmake-implicit] Help/variable/CMAKE_LANG_IMPLICIT_INCLUDE_DIRECTORIES.rst (L6-11)
- [fetchcontent] Modules/FetchContent.cmake (L176-186)

Libraries and build systems

- [vcpkg-bc] https://github.com/microsoft/vcpkg-docs/blob/eda2ef268351fb5e18ebc5defa16ecfbffaa651f/vcpkg/users/binarycaching.md (L13-19)
- [vcpkg-cmake] …/vcpkg/users/buildsystems/cmake-integration.md (L21-25)
- [vcpkg-ver] …/vcpkg/users/versioning.md
- [conan-tut] https://github.com/conan-io/docs/blob/25c21b625cb30d605444cb7c8b0724477217979d/tutorial/consuming_packages/build_simple_cmake_project.rst (L127-144)
- [conan-faq] …/knowledge/faq.rst (L13)
- [cci-platforms] https://github.com/conan-io/conan-center-index/blob/b9411174b9463d495ecdee1675f9ee4954643d41/docs/supported_platforms_and_configurations.md (L70-76)
- [cpm] https://github.com/cpm-cmake/CPM.cmake/blob/01678cfe175eab53143640429fdaa57c3c621cc6/README.md (L11, L166)
- [meson-machine] https://github.com/mesonbuild/meson/blob/27f69b22e5fe403d3ec5788216adaa85046d0e8f/docs/markdown/Machine-files.md (L1-7)
- [glibc-features] https://github.com/bminor/glibc/blob/04e750e75b73957cf1c791535a3f4319534a52fc/include/features.h (L451)

Editor

- [vsc-clangd] https://github.com/clangd/vscode-clangd/blob/587d34ee8d445bf7f9bff2f6add9952e62515548/package.json (L95-98, L168)
- [cmt-pkg] https://github.com/microsoft/vscode-cmake-tools/blob/e0969b894e56d8ea5e6641d48a82e5ba3babcc38/package.json (L72-74, L2383-2386, L4106-4113)
- [direnv-ext] https://github.com/direnv/direnv-vscode/blob/8fd4f14686b4736c67a6102a5263731a42cfc732/src/extension.ts (L196-230, L363-378)
- [direnv-pkg] …/package.json (L74-78)
- [vsc-windows] https://github.com/microsoft/vscode/blob/c198526d8e64ba6f9944e9f7bcc079ed1f6d7fcc/src/vs/platform/windows/electron-main/windowsMainService.ts (L1569)
- [vsc-shellenv] …/src/vs/platform/shell/node/shellEnv.ts (L49-50)

CI

- [inix-sh] https://github.com/cachix/install-nix-action/blob/75c75c31ebece974e48ebc36b4ad125bd97bd97b/install-nix.sh (L60-61)
- [runner-2404] https://github.com/actions/runner-images/blob/4da2307112a0fad2fd2ecaca8ba7d08683b8c581/images/ubuntu/Ubuntu2404-Readme.md (L18-20, L72)
- [runner-readme] …/README.md (L25)
