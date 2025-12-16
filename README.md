```markdown
# mesa-git 🧱🎮

Custom **Mesa Git** build for **Arch Linux**, built with **Meson + Ninja** and packaged
as installable **pacman packages**.

This repository is intended for **testing, development and early validation** of
Mesa features, including:
- specific branches (e.g. `main`, `25.3`)
- specific commits
- GitLab Merge Requests (MRs)

Optimized for **Intel GPUs (including Intel Arc)** with support for **AMD** and **NVIDIA (nouveau)**.

---

## 📦 **Packages Provided**

This PKGBUILD produces **two packages from a single source tree**:

### 1. **mesa-git**
- 64-bit Mesa libraries
- OpenGL, Vulkan, DRI, GLX
- Installed to `/usr/lib`

### 2. **lib32-mesa-git**
- 32-bit Mesa libraries (multilib)
- Required for:
  - Steam
  - Wine / Proton
  - 32-bit OpenGL/Vulkan applications
- Installed to `/usr/lib32`

---

## ✨ **Features**

- Builds Mesa directly from the **official Mesa Git repository**
- Uses **Meson** (upstream-recommended build system)
- Single PKGBUILD for **64-bit and 32-bit**
- Prevents version/ABI mismatch between architectures
- **Automatic dependency selection** based on GPU configuration
- Fully configurable:
  - Branch selection
  - Commit pinning
  - Merge Request testing
  - GPU driver selection (Intel, AMD, NVIDIA)
- Clean installation & removal via `pacman`

---

## 🔧 **Build Configuration**

At the **top of the PKGBUILD**, you can configure what should be built.

### Basic Configuration
```bash
# Branch to use (default: main)
MESA_BRANCH="main"

# Commit to use (empty = latest commit of the branch)
MESA_COMMIT=""

# Merge Requests to apply (empty = none)
# Example: MESA_MRS=("!27358")
MESA_MRS=()
```

### GPU Driver Selection
Uncomment **ONLY ONE** configuration block in the PKGBUILD:

```bash
# For Intel Arc (default)
GALLIUM_DRIVERS=("iris" "zink")
VULKAN_DRIVERS=("intel")

# For AMD Radeon
#GALLIUM_DRIVERS=("radeonsi" "zink")
#VULKAN_DRIVERS=("amd")

# For NVIDIA (nouveau)
#GALLIUM_DRIVERS=("nouveau" "zink")
#VULKAN_DRIVERS=("nvidia")

# For ALL drivers (largest build)
#GALLIUM_DRIVERS=("iris" "radeonsi" "nouveau" "zink") 
#VULKAN_DRIVERS=("intel" "amd" "nvidia")
```

**Important:** Dependencies are automatically selected based on your GPU choice!

---

## 🛠️ **Usage**

### 1. Clone the repository

```bash
git clone https://github.com/PadTrick/mesa-git.git
cd mesa-git
```

### 2. Configure GPU drivers
Edit the PKGBUILD and uncomment your desired GPU configuration.

### 3. Build packages

```bash
makepkg -s
```

### 4. Install packages

```bash
sudo pacman -U mesa-git-*.pkg.tar.zst
sudo pacman -U lib32-mesa-git-*.pkg.tar.zst
```

---

## 🎯 **GPU Support Matrix**

| GPU Vendor | Gallium Drivers | Vulkan Drivers | Notes |
|------------|----------------|----------------|-------|
| **Intel Arc** | `iris`, `zink` | `intel` | Supports all Intel GPUs (Gen4 to Arc) |
| **Intel HD/Iris** | `iris` | `intel` | Older Intel iGPUs |
| **AMD Radeon** | `radeonsi`, `zink` | `amd` | Automatic dependency selection |
| **NVIDIA (nouveau)** | `nouveau`, `zink` | `nvidia` | **Vulkan support is experimental/limited** |

---

## ⚠️ **Important Notes by GPU Vendor**

### **Intel Arc**
- Uses standard `-Dvulkan-drivers=intel` option
- `iris` driver supports all Intel GPUs from Gen4+ including Arc
- Zink driver included for Vulkan-on-OpenGL testing
- Requires Linux kernel ≥ 6.2 for full Intel Arc functionality
- **Dependencies automatically added:** libva, libvdpau, libclc, spirv-llvm-translator

### **AMD Radeon - Automatic Dependency Handling**
When building for AMD, these dependencies are **automatically selected**:

```bash
# 64-bit dependencies (automatically added):
libelf libclc spirv-llvm-translator rust rust-bindgen cbindgen libxml2

# 32-bit dependencies (automatically added):
lib32-libelf lib32-spirv-llvm-translator lib32-libxml2 lib32-rust-libs
```

**Note:** Rust (`rust`, `rust-bindgen`, `cbindgen`) is **required** for AMD RADV Vulkan driver compilation.

### **NVIDIA (nouveau) - Limitations**
- **OpenGL:** Full support via `nouveau` driver
- **Vulkan:** **Experimental and incomplete** via `nvidia` Vulkan driver
- **Performance:** Generally slower than proprietary NVIDIA drivers
- **Hardware:** Best support for older NVIDIA cards (Kepler, Maxwell)
- **Dependencies automatically added:** libelf, libclc, spirv-llvm-translator

---

## 🧪 **Build Examples**

### Build latest Mesa `main` for Intel Arc (default)
```bash
makepkg -s
```

### Build Mesa branch `25.3` for AMD
```bash
MESA_BRANCH="25.3" makepkg -s
```

### Build for NVIDIA with a specific commit
```bash
MESA_COMMIT="deadbeef1234" makepkg -s
```

### Test a Merge Request for Intel
```bash
MESA_MRS=("!27358") makepkg -s
```

---

## 📦 **System Requirements**

### Basic Requirements
- Arch Linux (x86_64)
- Multilib enabled in `/etc/pacman.conf`
- Base development tools: `base-devel`

### Automatic Dependency Selection
The PKGBUILD automatically selects the correct dependencies based on your GPU configuration:

- **Base dependencies**: Always included (compiler tools, X11/Wayland, etc.)
- **Intel dependencies**: Added when `intel` is in `VULKAN_DRIVERS`
- **AMD dependencies**: Added when `amd` is in `VULKAN_DRIVERS`
- **NVIDIA dependencies**: Added when `nvidia` is in `VULKAN_DRIVERS`

**No manual dependency editing required!**

---

## 🧠 **How It Works**

* Mesa is cloned **once**
* The same source tree is used for:
  * 64-bit build
  * 32-bit build
* This guarantees:
  * identical headers
  * identical ABI
  * identical Mesa version for both architectures
* **Automatic dependency selection** based on GPU configuration

The `prepare()` step:
* checks out the selected branch
* optionally pins a commit
* optionally fetches & merges Merge Requests

---

## 🧪 **Verification**

Check package versions:
```bash
pacman -Qi mesa-git lib32-mesa-git | grep Version
```

Verify drivers are installed:
```bash
# For Intel
ls /usr/lib/dri/iris_dri.so

# For AMD
ls /usr/lib/dri/radeonsi_dri.so

# For NVIDIA
ls /usr/lib/dri/nouveau_dri.so
```

Check active dependencies during build:
```bash
# See which dependencies are being installed
makepkg -si --noconfirm --noprogressbar | grep "installing"
```

---

## ⚠️ **Important Warnings**

* This package **conflicts with**:
  * `mesa` (official package)
  * `lib32-mesa` (official package)

* **Backup your system** before installation

* Intended for:
  * testing
  * development
  * early feature validation

* **Not recommended** for production systems without experience

* **AMD users**: Rust toolchain will be automatically installed

* **NVIDIA users**: Vulkan support is limited/experimental

---

## 🔄 **Reverting to Official Packages**

To return to official Mesa packages:
```bash
sudo pacman -S mesa lib32-mesa
```

---

## 🎯 **Target Audience**

* **Arch Linux users** wanting latest Mesa features
* **Mesa developers & testers**
* **Intel Arc users** seeking optimal performance
* **AMD users** wanting bleeding-edge RadeonSI drivers
* **NVIDIA open-source enthusiasts** (with caveats)
* **Gamers** using Steam / Proton / Wine
* Users who want **full control** over Mesa builds

---

## 🤝 **Contributing**

Contributions are welcome!
Please ensure:
* changes are tested with your GPU
* configuration options are documented
* commits are clearly described
* AMD/NVIDIA specific changes are noted

---

## 📜 **License**

Mesa is licensed under the **MIT license**.
This PKGBUILD is provided as-is, without warranty.

**Disclaimer:** Custom Mesa builds may cause system instability. Use at your own risk.