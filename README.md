# mesa-git 🧱🎮

Custom **Mesa Git** build for **Arch Linux**, built with **Meson + Ninja** and packaged
as installable **pacman packages**.

This repository is intended for **testing, development and early validation** of
Mesa features, including:
- specific branches (e.g. `main`, `26.2`)
- specific commits or tags
- GitLab Merge Requests (MRs)
- switching compilers (`""` system default, `gcc`, `clang`)
- passing extra Meson options per architecture (`64-bit` and `32-bit`)

Configured by default for **AMD Radeon** (`radeonsi`, `zink`, `amd`), with support
for **Intel Arc / Iris** (`iris`, `zink`, `intel`) and a placeholder/untested
configuration for **NVIDIA** (`nouveau`).

---

## 📦 **Packages Provided**

This PKGBUILD produces **pacman packages** from a single source tree:

### 1. **mesa-git**
- 64-bit Mesa libraries
- OpenGL, Vulkan, DRI, GLX
- Installed to `/usr/lib`

### 2. **lib32-mesa-git** (optional via `BUILD_LIB32="1"`)
- 32-bit Mesa libraries (multilib)
- Required for:
  - Steam
  - Wine / Proton
  - 32-bit OpenGL/Vulkan applications
- Installed to `/usr/lib32`

---

## ✨ **Features**

- Builds Mesa directly from the **official Mesa Git repository**
- Uses **Meson + Ninja**
- Single `PKGBUILD` for **64-bit and 32-bit** (`BUILD_LIB32="1"` or `"0"`)
- Keeps headers, ABI, and version aligned across architectures
- **Dynamic dependency selection** based on driver selection, `BUILD_LIB32`, and `MESA_COMPILER`
- **Compiler switching** via `MESA_COMPILER` (`""`, `"gcc"`, `"clang"`)
- **Extra Meson flags** per architecture via `MESA_EXTRA_MESON_64` and `MESA_EXTRA_MESON_32`
- Automatic `PATH` lookup for `mesa_clc` and `vtn_bindgen2` built in `build64` when building `build32`
- Clean installation & removal via `pacman`

---

## 🔧 **Build Configuration**

At the **top of the `PKGBUILD`**, under `USER CONFIGURATION`, you can adjust:

```bash
# Branch (default: main; for 26.2.x use "26.2")
MESA_BRANCH="26.2"

# Commit or tag (empty = latest commit of MESA_BRANCH;
# set to release commit or tag e.g. "mesa-26.2.7" if desired)
MESA_COMMIT="c8bb568978cc2bcafc958ee771d43822d6ff3116"

# Merge Requests (empty = none)
# Format: ("!12345" "!67890")
MESA_MRS=()

# Compiler selection: "" (system default), "gcc", or "clang"
MESA_COMPILER=""

# GPU DRIVER SELECTION (choose one or multiple)
# Default: AMD Radeon (RX 9070)
GALLIUM_DRIVERS=("radeonsi" "zink")
VULKAN_DRIVERS=("amd")

# Extra Meson options (optional, space-separated)
# Example for Intel 64+32-bit when 32-bit lacks clangBasic:
# MESA_EXTRA_MESON_64="-Dinstall-mesa-clc=true"
# MESA_EXTRA_MESON_32="-Dmesa-clc=system"
MESA_EXTRA_MESON_64=""
MESA_EXTRA_MESON_32=""

# Build 32-bit (lib32-mesa-git) as well? ("1" = yes, "0" = no)
BUILD_LIB32="1"
```

---

## 🛠️ **Usage**

### 1. Clone the repository
```bash
git clone https://github.com/PadTrick/mesa-git.git
cd mesa-git
```

### 2. Install helper dependencies & optional Git clone workaround (`install_deps.sh`)
Review `install_deps.sh` before running it:
```bash
./install_deps.sh
```
The script installs common build/multilib/Rust/LLVM/Python packages via `pacman` and contains commented-out Git configuration lines for large GitLab clones (`http.version HTTP/1.1` and `http.postBuffer 524288000`) if you encounter `curl 56` / `RPC failed` disconnects.

### 3. Configure `PKGBUILD`
Edit the `USER CONFIGURATION` section in `PKGBUILD` (branch, commit, merge requests, compiler, GPU drivers, extra Meson options, and `BUILD_LIB32`).

### 4. Build packages
```bash
makepkg -s
```
*(Or `makepkg -sf` when rebuilding after dependency or flag changes.)*

### 5. Install packages
```bash
sudo pacman -U mesa-git-*.pkg.tar.zst
sudo pacman -U lib32-mesa-git-*.pkg.tar.zst
```
*(If `BUILD_LIB32="0"`, only `mesa-git-*.pkg.tar.zst` is built.)*

---

## 🎯 **GPU Support Matrix**

| GPU Target | Gallium Drivers | Vulkan Drivers | Status & Notes |
|------------|----------------|----------------|----------------|
| **AMD Radeon (Default)** | `radeonsi`, `zink` | `amd` | Tested and working (64-bit & 32-bit) |
| **Intel Arc / Iris** | `iris`, `zink` | `intel` | Tested and working; for 64-bit + 32-bit builds, see `MESA_EXTRA_MESON_64` / `MESA_EXTRA_MESON_32` |
| **NVIDIA (`nouveau`)** | `nouveau`, `zink` | `nouveau` | **Dummy / untested** — kept as a placeholder only; not tested on hardware |
| **All Drivers** | `radeonsi`, `iris`, `nouveau`, `zink` | `amd`, `intel`, `nouveau` | Largest build time; NVIDIA part remains a dummy/untested |

---

## ⚠️ **Important Notes by GPU & Build Setup**

### **AMD Radeon (Default)**
- Uses `GALLIUM_DRIVERS=("radeonsi" "zink")` and `VULKAN_DRIVERS=("amd")`.
- Automatically adds AMD 64-bit and (when `BUILD_LIB32="1"`) 32-bit dependencies including `libelf`, `libclc`, `spirv-llvm-translator`, `rust`, `rust-bindgen`, `cbindgen`, `libxml2`, `libva`, and their `lib32-*` counterparts (`lib32-rust-libs`, etc.).

### **Intel Arc / Iris (including 64-bit + 32-bit builds)**
- Uses `GALLIUM_DRIVERS=("iris" "zink")` and `VULKAN_DRIVERS=("intel")`.
- When building both 64-bit and 32-bit packages on systems where 32-bit `clangBasic` / `clang-cpp` libraries are not available for `mesa_clc`, set:
  ```bash
  MESA_EXTRA_MESON_64="-Dinstall-mesa-clc=true"
  MESA_EXTRA_MESON_32="-Dmesa-clc=system"
  ```
- During `build()`, if `mesa_clc` or `vtn_bindgen2` were built in `build64`, their directories are automatically prepended to `PATH` before running `meson setup` for `build32`.

### **NVIDIA (`nouveau`) — Dummy & Untested**
- **Current status:** The NVIDIA configuration in this repository is currently only a **dummy / placeholder and untested**.
- Do not rely on it as a supported or validated setup; if you use NVIDIA hardware, test carefully or stick to your intended driver setup.

### **Compiler Selection (`MESA_COMPILER`)**
- `""`: Uses the default compiler environment (`CC`/`CXX` unset for 64-bit, `gcc -m32` / `g++ -m32` for 32-bit).
- `"gcc"`: Uses `gcc` / `g++` (and `-m32` for 32-bit), adding `gcc` to `makedepends`.
- `"clang"`: Uses `clang` / `clang++` (and `-m32` for 32-bit), adding `clang` and `lld` to `makedepends`.

---

## 🧪 **Build Examples**

### Build default configuration (AMD on branch `26.2` / pinned commit)
```bash
makepkg -s
```

### Build with GCC or Clang
Set `MESA_COMPILER="gcc"` or `MESA_COMPILER="clang"` in `PKGBUILD`, or override inline:
```bash
MESA_COMPILER="gcc" makepkg -sf
```

### Build Intel Arc with both 64-bit and 32-bit packages
Set `GALLIUM_DRIVERS=("iris" "zink")`, `VULKAN_DRIVERS=("intel")`, `MESA_EXTRA_MESON_64="-Dinstall-mesa-clc=true"`, and `MESA_EXTRA_MESON_32="-Dmesa-clc=system"` in `PKGBUILD`, then run:
```bash
makepkg -sf
```

### Test a Merge Request
```bash
MESA_MRS=("!27358") makepkg -s
```

---

## 📦 **System Requirements**

- Arch Linux (`x86_64`)
- `multilib` repository enabled in `/etc/pacman.conf` (required for `lib32-*` packages and `BUILD_LIB32="1"`)
- `base-devel` installed
- Dynamic `makedepends` in `PKGBUILD` based on:
  - `BUILD_LIB32` (`_base_lib32_makedepends`)
  - `MESA_COMPILER` (`clang`/`lld` or `gcc`)
  - Active drivers in `GALLIUM_DRIVERS` and `VULKAN_DRIVERS` (`intel`, `amd`, `nouveau`)

---

## 🧠 **How It Works**

* Mesa is cloned **once** into `mesa` (`git+https://gitlab.freedesktop.org/mesa/mesa.git`).
* `pkgver()` derives the version dynamically from `VERSION` plus commit count and short hash (`<version>.r<count>.g<short_sha>`).
* `prepare()` checks out `MESA_BRANCH`, optionally checks out `MESA_COMMIT`, optionally fetches and merges `MESA_MRS`, and cleans `build64` and `build32`.
* `build()` configures and builds `build64` (and `build32` when `BUILD_LIB32="1"`) with Meson and Ninja, applying `MESA_COMPILER` and `MESA_EXTRA_MESON_64` / `MESA_EXTRA_MESON_32`.

---

## 🧪 **Verification**

Check installed package versions:
```bash
pacman -Qi mesa-git lib32-mesa-git | grep -E "Name|Version"
```

Verify DRI drivers are installed:
```bash
# AMD
ls /usr/lib/dri/radeonsi_dri.so

# Intel
ls /usr/lib/dri/iris_dri.so

# NVIDIA (dummy/untested)
ls /usr/lib/dri/nouveau_dri.so
```

Check runtime driver output:
```bash
vulkaninfo --summary
glxinfo -B
```

---

## ⚠️ **Important Warnings**

* `mesa-git` and `lib32-mesa-git` conflict with and replace official `mesa` and `lib32-mesa` (as well as related driver provides/conflicts).
* **NVIDIA support is currently a dummy and untested.**
* Create backups or system snapshots before installing custom graphics drivers.
* Intended for testing, development, and early feature validation.

---

## 🔄 **Reverting to Official Packages**

To switch back to Arch Linux's official Mesa packages:
```bash
sudo pacman -S mesa lib32-mesa
```

---

## 📜 **License**

Mesa is licensed under the **MIT license**. This `PKGBUILD` and repository are provided as-is, without warranty.

**Disclaimer:** Custom Mesa builds may cause system instability or rendering issues. Use at your own risk.
