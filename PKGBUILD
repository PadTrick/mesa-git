# ======================
#   USER CONFIGURATION
# ======================

# Branch (default: main)
MESA_BRANCH="main"
# Example:
# MESA_BRANCH="25.3"
# MESA_BRANCH="staging/25.3"

# Commit (empty = latest commit of branch)
MESA_COMMIT=""
# Example:
# MESA_COMMIT="a1b2c3d4e5f6"

# Merge Requests (empty = none)
# Format: ("!12345" "!67890")
MESA_MRS=()
# Example:
# MESA_MRS=("!27358")

# GPU DRIVER SELECTION (choose one or multiple)
# For ALL
#GALLIUM_DRIVERS=("iris" "radeonsi" "nouveau" "zink")
#VULKAN_DRIVERS=("intel" "amd" "nvidia")
# For Intel Arc
GALLIUM_DRIVERS=("iris" "zink")
VULKAN_DRIVERS=("intel")
# For AMD Radeon
#GALLIUM_DRIVERS=("radeonsi" "zink")
#VULKAN_DRIVERS=("amd")
# For NVIDIA
#GALLIUM_DRIVERS=("nouveau" "zink")
#VULKAN_DRIVERS=("nvidia")

# =====================
#   PKGBUILD METADATA
# =====================

pkgbase=mesa-git
pkgname=(mesa-git lib32-mesa-git)
pkgver=999.999.999  # Initial high version
pkgrel=1
arch=(x86_64)
url="https://mesa3d.org/"
license=(MIT)

# ================================================
#   DEPENDENCIES (ADJUST BASED ON GPU SELECTION)
# ================================================

# Base dependencies (required for all GPUs)
_base_makedepends=(
  git meson ninja python-mako python-packaging python-ply
  llvm libdrm wayland wayland-protocols
  libx11 libxrandr libxshmfence libxcb libxxf86vm libxdamage
  vulkan-icd-loader libglvnd libunwind lm_sensors
  glslang libdisplay-info
  lib32-llvm lib32-libdrm lib32-wayland
  lib32-libx11 lib32-libxcb lib32-libxrandr lib32-libxshmfence
  lib32-libxxf86vm lib32-libxdamage lib32-vulkan-icd-loader
  lib32-libglvnd
)

# GPU-specific dependencies (ADD BASED ON YOUR SELECTION ABOVE)
_intel_deps=(
  libva libvdpau libclc spirv-llvm-translator
  lib32-libva lib32-libvdpau lib32-spirv-llvm-translator
)

_amd_deps=(
  libelf libclc spirv-llvm-translator rust rust-bindgen cbindgen
  libxml2
  lib32-libelf lib32-spirv-llvm-translator lib32-libxml2 lib32-rust-libs
)

_nvidia_deps=(
  libelf libclc spirv-llvm-translator
  lib32-libelf lib32-spirv-llvm-translator
)

# Select dependencies based on active driver
if [[ "${VULKAN_DRIVERS[@]}" =~ "intel" ]]; then
  makedepends=("${_base_makedepends[@]}" "${_intel_deps[@]}")
elif [[ "${VULKAN_DRIVERS[@]}" =~ "amd" ]]; then
  makedepends=("${_base_makedepends[@]}" "${_amd_deps[@]}")
elif [[ "${VULKAN_DRIVERS[@]}" =~ "nvidia" ]]; then
  makedepends=("${_base_makedepends[@]}" "${_nvidia_deps[@]}")
else
  makedepends=("${_base_makedepends[@]}")
fi

source=("mesa::git+https://gitlab.freedesktop.org/mesa/mesa.git")
sha256sums=('SKIP')

# ==================
#   VERSION STRING
# ==================

pkgver() {
    _ver="999.999.999"

    if [ -d "$srcdir/mesa" ]; then
        cd "$srcdir/mesa"

        # Try to read from VERSION file
        if [ -f VERSION ]; then
            _ver=$(cat VERSION | tr '-' '_')
        fi

        # Add commit count and short hash
        echo "${_ver}.$(git rev-list --count HEAD).$(git rev-parse --short HEAD)"
    else
        echo "${_ver}.0.0000000"
    fi
}

# ===========
#   PREPARE
# ===========

prepare() {
  cd mesa

  echo ">> Using branch: $MESA_BRANCH"
  git fetch origin
  git checkout "$MESA_BRANCH"

  if [[ -n "$MESA_COMMIT" ]]; then
    echo ">> Using commit: $MESA_COMMIT"
    git checkout "$MESA_COMMIT"
  fi

  if (( ${#MESA_MRS[@]} )); then
    echo ">> Applying Merge Requests:"
    for mr in "${MESA_MRS[@]}"; do
      echo "   - $mr"
      git fetch origin "merge-requests/${mr#!}/head:mr-${mr#!}"
      git merge --no-edit "mr-${mr#!}"
    done
  fi

  _new_pkgver=$(pkgver)
  if [ "$_new_pkgver" != "999.999.999.0.0000000" ]; then
    sed -i "s|^pkgver=.*|pkgver=${_new_pkgver}|" "$startdir/PKGBUILD"
  fi
}

# =========
#   BUILD
# =========

build() {
  ### 64-Bit ###
  meson setup mesa build64 \
    --prefix=/usr \
    --libdir=lib \
    -Dbuildtype=release \
    -Dplatforms=x11,wayland \
    -Dgallium-drivers=$(IFS=,; echo "${GALLIUM_DRIVERS[*]}") \
    -Dvulkan-drivers=$(IFS=,; echo "${VULKAN_DRIVERS[*]}") \
    -Dllvm=enabled

  ninja -C build64

  ### 32-Bit ###
  export CC="gcc -m32"
  export CXX="g++ -m32"
  export PKG_CONFIG_PATH="/usr/lib32/pkgconfig"
  export CFLAGS="-m32"
  export CXXFLAGS="-m32"
  export LDFLAGS="-m32"

  meson setup mesa build32 \
    --prefix=/usr \
    --libdir=lib32 \
    --buildtype=release \
    -Dplatforms=x11,wayland \
    -Dgallium-drivers=$(IFS=,; echo "${GALLIUM_DRIVERS[*]}") \
    -Dvulkan-drivers=$(IFS=,; echo "${VULKAN_DRIVERS[*]}") \
    -Dllvm=enabled

  ninja -C build32
}

# ===================
#   PACKAGE: 64-BIT
# ===================

package_mesa-git() {
  depends=(libdrm wayland libx11 llvm vulkan-icd-loader libva libvdpau)

  provides=(
    mesa=$pkgver-$pkgrel
    vulkan-intel=$pkgver-$pkgrel
    vulkan-radeon=$pkgver-$pkgrel
    vulkan-nouveau=$pkgver-$pkgrel
    vulkan-driver
    opengl-driver
    libva-mesa-driver=$pkgver-$pkgrel
    mesa-vdpau=$pkgver-$pkgrel
    opencl-mesa=$pkgver-$pkgrel
    opencl-driver
  )

  conflicts=(
    'mesa'
    'vulkan-intel'
    'vulkan-radeon'
    'vulkan-nouveau'
    'libva-mesa-driver'
    'mesa-vdpau'
    'opencl-mesa'
  )

  # Sicherheitscheck: Prüfe ob build64 existiert
  if [ ! -d "build64" ]; then
    echo "ERROR: Build directory 'build64' not found!"
    echo "Run 'makepkg' without -R flag to build first."
    return 1
  fi

  DESTDIR="$pkgdir" ninja -C build64 install

  # Install license
  #install -Dm644 "$srcdir/mesa/docs/license.rst" "$pkgdir/usr/share/licenses/$pkgname/LICENSE" 2>/dev/null || :
}

# ===================
#   PACKAGE: 32-BIT
# ===================

package_lib32-mesa-git() {
  depends=(mesa-git lib32-vulkan-icd-loader lib32-libva lib32-libvdpau)

  provides=(
    lib32-mesa=$pkgver-$pkgrel
    lib32-vulkan-intel=$pkgver-$pkgrel
    lib32-vulkan-radeon=$pkgver-$pkgrel
    lib32-vulkan-nouveau=$pkgver-$pkgrel
    lib32-vulkan-driver
    lib32-opengl-driver
    lib32-libva-mesa-driver=$pkgver-$pkgrel
    lib32-mesa-vdpau=$pkgver-$pkgrel
    lib32-opencl-mesa=$pkgver-$pkgrel
    lib32-opencl-driver
  )

  conflicts=(
    'lib32-mesa'
    'lib32-vulkan-intel'
    'lib32-vulkan-radeon'
    'lib32-vulkan-nouveau'
    'lib32-libva-mesa-driver'
    'lib32-mesa-vdpau'
    'lib32-opencl-mesa'
  )

  if [ ! -d "build32" ]; then
    echo "ERROR: Build directory 'build32' not found!"
    echo "Run 'makepkg' without -R flag to build first."
    return 1
  fi

  DESTDIR="$pkgdir" ninja -C build32 install

  # Remove duplicate files that should only exist in 64-bit package
  rm -rf "$pkgdir"/usr/include
  rm -rf "$pkgdir"/usr/share/drirc.d
  rm -rf "$pkgdir"/usr/share/glvnd/egl_vendor.d

  # Clean up unwanted library files
  find "$pkgdir/usr/lib32" -name "*.a" -delete
  find "$pkgdir/usr/lib32" -name "*.la" -delete
}
