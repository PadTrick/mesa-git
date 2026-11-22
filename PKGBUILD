# Maintainer: Patrick Wolpert

# ======================
#   USER CONFIGURATION
# ======================

# Branch (default: main; for 26.2.x use "26.2")
MESA_BRANCH="main"

# Commit or tag (empty = latest commit of MESA_BRANCH;
# set to release commit or tag e.g. "mesa-26.2.7" if desired)
MESA_COMMIT=""

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

# Examples:
# Intel Arc:
# GALLIUM_DRIVERS=("iris" "zink")
# VULKAN_DRIVERS=("intel")
#
# NVIDIA (nouveau Gallium for older cards + zink; NVK vulkan supports Turing+):
# GALLIUM_DRIVERS=("nouveau" "zink")
# VULKAN_DRIVERS=("nouveau")
#
# All (AMD + Intel + NVIDIA):
# GALLIUM_DRIVERS=("radeonsi" "iris" "nouveau" "zink")
# VULKAN_DRIVERS=("amd" "intel" "nouveau")

# Build 32-bit (lib32-mesa-git-custom) as well? ("1" = yes, "0" = no)
BUILD_LIB32="1"

# =====================
#   PKGBUILD METADATA
# =====================

pkgbase=mesa-git-custom
pkgname=(mesa-git-custom)
if [[ "$BUILD_LIB32" == "1" ]]; then
  pkgname+=(lib32-mesa-git-custom)
fi
pkgver=26.2.7.r200.gc8bb568  # Dynamically overwritten by pkgver() from branch/commit
pkgrel=1
arch=(x86_64)
url="https://mesa3d.org/"
license=(MIT)

# ================================================
#   DEPENDENCIES (DYNAMIC FROM USER CONFIG)
# ================================================

_has_driver() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do
    [[ "$item" == "$needle" ]] && return 0
  done
  return 1
}

_base_makedepends=(
  git meson ninja bison flex python-mako python-packaging python-ply python-yaml
  llvm libdrm wayland wayland-protocols
  libx11 libxrandr libxshmfence libxcb libxxf86vm libxdamage
  vulkan-icd-loader libglvnd libunwind lm_sensors
  glslang libdisplay-info
)

_base_lib32_makedepends=(
  lib32-llvm lib32-libdrm lib32-wayland
  lib32-libx11 lib32-libxcb lib32-libxrandr lib32-libxshmfence
  lib32-libxxf86vm lib32-libxdamage lib32-vulkan-icd-loader
  lib32-libglvnd lib32-libunwind
)

_intel_deps=(
  libva spirv-llvm-translator
)
_intel_lib32_deps=(
  lib32-libva lib32-spirv-llvm-translator
)

_amd_deps=(
  libelf libclc spirv-llvm-translator rust rust-bindgen cbindgen
  libxml2 libva
)
_amd_lib32_deps=(
  lib32-libelf lib32-spirv-llvm-translator lib32-libxml2
  lib32-rust-libs lib32-libva
)

_nvidia_deps=(
  libelf libclc spirv-llvm-translator rust rust-bindgen cbindgen
  libva
)
_nvidia_lib32_deps=(
  lib32-libelf lib32-spirv-llvm-translator lib32-libva
)

makedepends=("${_base_makedepends[@]}")
if [[ "$BUILD_LIB32" == "1" ]]; then
  makedepends+=("${_base_lib32_makedepends[@]}")
fi

if [[ "$MESA_COMPILER" == "clang" ]]; then
  makedepends+=(clang lld)
elif [[ "$MESA_COMPILER" == "gcc" ]]; then
  makedepends+=(gcc)
fi

if _has_driver "intel" "${GALLIUM_DRIVERS[@]}" "${VULKAN_DRIVERS[@]}"; then
  makedepends+=("${_intel_deps[@]}")
  [[ "$BUILD_LIB32" == "1" ]] && makedepends+=("${_intel_lib32_deps[@]}")
fi

if _has_driver "amd" "${GALLIUM_DRIVERS[@]}" "${VULKAN_DRIVERS[@]}"; then
  makedepends+=("${_amd_deps[@]}")
  [[ "$BUILD_LIB32" == "1" ]] && makedepends+=("${_amd_lib32_deps[@]}")
fi

if _has_driver "nouveau" "${GALLIUM_DRIVERS[@]}" "${VULKAN_DRIVERS[@]}"; then
  makedepends+=("${_nvidia_deps[@]}")
  [[ "$BUILD_LIB32" == "1" ]] && makedepends+=("${_nvidia_lib32_deps[@]}")
fi

source=("mesa::git+https://gitlab.freedesktop.org/mesa/mesa.git")
sha256sums=('SKIP')

# ==================
#   VERSION STRING
# ==================

pkgver() {
  cd "$srcdir/mesa"
  local _ver="0.0.0"
  if [[ -f VERSION ]]; then
    _ver=$(tr -d '[:space:]' < VERSION | tr '-' '_')
  fi
  local _count _sha
  _count=$(git rev-list --count HEAD)
  _sha=$(git rev-parse --short HEAD)
  printf '%s.r%s.g%s\n' "$_ver" "$_count" "$_sha"
}

# ===========
#   PREPARE
# ===========

prepare() {
  cd "$srcdir/mesa"

  echo ">> Using branch: $MESA_BRANCH"
  git fetch origin --prune
  git checkout -B "$MESA_BRANCH" "origin/$MESA_BRANCH"

  if [[ -n "$MESA_COMMIT" ]]; then
    echo ">> Using commit/ref: $MESA_COMMIT"
    git checkout "$MESA_COMMIT"
  fi

  if (( ${#MESA_MRS[@]} )); then
    echo ">> Applying Merge Requests:"
    local mr
    for mr in "${MESA_MRS[@]}"; do
      echo "   - $mr"
      git fetch origin "merge-requests/${mr#!}/head:mr-${mr#!}"
      git merge --no-edit "mr-${mr#!}"
    done
  fi

  cd "$srcdir"
  rm -rf build64 build32
}

# =========
#   BUILD
# =========

_join_csv() {
  local IFS=,
  echo "$*"
}

_prepend_build64_clc_path() {
  local _tool _bin_path
  for _tool in mesa_clc vtn_bindgen2; do
    _bin_path=$(find "$srcdir/build64" -name "$_tool" -type f -executable 2>/dev/null | head -n1)
    if [[ -n "$_bin_path" ]]; then
      export PATH="$(dirname "$_bin_path"):$PATH"
    fi
  done
}

build() {
  local _extra64 _extra32
  read -r -a _extra64 <<< "$MESA_EXTRA_MESON_64"
  read -r -a _extra32 <<< "$MESA_EXTRA_MESON_32"

  local _gallium _vulkan
  _gallium=$(_join_csv "${GALLIUM_DRIVERS[@]}")
  _vulkan=$(_join_csv "${VULKAN_DRIVERS[@]}")

  local _cc64 _cxx64 _cc32 _cxx32
  case "$MESA_COMPILER" in
    clang)
      _cc64="clang"
      _cxx64="clang++"
      _cc32="clang -m32"
      _cxx32="clang++ -m32"
      ;;
    gcc)
      _cc64="gcc"
      _cxx64="g++"
      _cc32="gcc -m32"
      _cxx32="g++ -m32"
      ;;
    "")
      _cc64=""
      _cxx64=""
      _cc32="gcc -m32"
      _cxx32="g++ -m32"
      ;;
    *)
      echo "ERROR: Unsupported MESA_COMPILER='$MESA_COMPILER' (use '', 'gcc', or 'clang')"
      return 1
      ;;
  esac

  ### 64-Bit ###
  (
    if [[ -n "$_cc64" ]]; then
      export CC="$_cc64"
      export CXX="$_cxx64"
    fi

    meson setup mesa "$srcdir/build64" \
      --prefix=/usr \
      --libdir=lib \
      --buildtype=release \
      -Dplatforms=x11,wayland \
      -Dgallium-drivers="$_gallium" \
      -Dvulkan-drivers="$_vulkan" \
      -Dglvnd=enabled \
      -Dllvm=enabled \
      "${_extra64[@]}"

    ninja -C "$srcdir/build64"
  )

  ### 32-Bit ###
  if [[ "$BUILD_LIB32" == "1" ]]; then
    (
      _prepend_build64_clc_path
      export CC="$_cc32"
      export CXX="$_cxx32"
      export PKG_CONFIG_PATH="/usr/lib32/pkgconfig"
      export LLVM_CONFIG="/usr/bin/llvm-config32"
      export CFLAGS="${CFLAGS:--O2} -m32"
      export CXXFLAGS="${CXXFLAGS:--O2} -m32"
      export LDFLAGS="${LDFLAGS:--Wl,-O1} -m32"

      meson setup mesa "$srcdir/build32" \
        --prefix=/usr \
        --libdir=lib32 \
        --buildtype=release \
        -Dplatforms=x11,wayland \
        -Dgallium-drivers="$_gallium" \
        -Dvulkan-drivers="$_vulkan" \
        -Dglvnd=enabled \
        -Dllvm=enabled \
        "${_extra32[@]}"

      ninja -C "$srcdir/build32"
    )
  fi
}

# ===================
#   PACKAGE: 64-BIT
# ===================

package_mesa-git-custom() {
  depends=(libdrm wayland libx11 llvm vulkan-icd-loader libglvnd)

  provides=(
    "mesa=$pkgver-$pkgrel"
    "mesa-git=$pkgver-$pkgrel"
    "vulkan-intel=$pkgver-$pkgrel"
    "vulkan-radeon=$pkgver-$pkgrel"
    "vulkan-nouveau=$pkgver-$pkgrel"
    vulkan-driver
    opengl-driver
    "libva-mesa-driver=$pkgver-$pkgrel"
    "opencl-mesa=$pkgver-$pkgrel"
    opencl-driver
  )

  conflicts=(
    mesa
    mesa-git
    vulkan-intel
    vulkan-radeon
    vulkan-nouveau
    libva-mesa-driver
    opencl-mesa
  )

  if [[ ! -d "$srcdir/build64" ]]; then
    echo "ERROR: Build directory '$srcdir/build64' not found!"
    return 1
  fi

  DESTDIR="$pkgdir" ninja -C "$srcdir/build64" install
  install -Dm644 "$srcdir/mesa/docs/license.rst" "$pkgdir/usr/share/licenses/$pkgname/LICENSE" 2>/dev/null || :
}

# ===================
#   PACKAGE: 32-BIT
# ===================

package_lib32-mesa-git-custom() {
  depends=("mesa-git-custom=$pkgver-$pkgrel" lib32-vulkan-icd-loader lib32-libglvnd)

  provides=(
    "lib32-mesa=$pkgver-$pkgrel"
    "lib32-mesa-git=$pkgver-$pkgrel"
    "lib32-vulkan-intel=$pkgver-$pkgrel"
    "lib32-vulkan-radeon=$pkgver-$pkgrel"
    "lib32-vulkan-nouveau=$pkgver-$pkgrel"
    lib32-vulkan-driver
    lib32-opengl-driver
    "lib32-libva-mesa-driver=$pkgver-$pkgrel"
    "lib32-opencl-mesa=$pkgver-$pkgrel"
    lib32-opencl-driver
  )

  conflicts=(
    lib32-mesa
    lib32-mesa-git
    lib32-vulkan-intel
    lib32-vulkan-radeon
    lib32-vulkan-nouveau
    lib32-libva-mesa-driver
    lib32-opencl-mesa
  )

  if [[ ! -d "$srcdir/build32" ]]; then
    echo "ERROR: Build directory '$srcdir/build32' not found!"
    return 1
  fi

  DESTDIR="$pkgdir" ninja -C "$srcdir/build32" install

  rm -rf "$pkgdir"/usr/include
  rm -rf "$pkgdir"/usr/share/drirc.d
  rm -rf "$pkgdir"/usr/share/glvnd/egl_vendor.d

  find "$pkgdir/usr/lib32" -name '*.a' -delete
  find "$pkgdir/usr/lib32" -name '*.la' -delete
}
