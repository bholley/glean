#!/usr/bin/env bash

# This should be invoked from inside xcode, not manually
if [ "$#" -ne 3 ]
then
    echo "Usage (note: only call inside xcode!):"
    echo "Args: $*"
    echo "path/to/build-scripts/xc-universal-binary.sh <FFI_TARGET> <GLEAN_ROOT_PATH> <buildvariant>"
    exit 1
fi

# what to pass to cargo build -p, e.g. glean_ffi
FFI_TARGET=$1
# path to app services root
GLEAN_ROOT=$2
# buildvariant from our xcconfigs
BUILDVARIANT=$3

RELFLAG=
if [[ "$BUILDVARIANT" != "debug" ]]; then
    RELFLAG=--release
fi

set -euvx

if [[ -n "${SDK_DIR:-}" ]]; then
  # Assume we're in Xcode, which means we're probably cross-compiling.
  # In this case, we need to add an extra library search path for build scripts and proc-macros,
  # which run on the host instead of the target.
  # (macOS Big Sur does not have linkable libraries in /usr/lib/.)
  export LIBRARY_PATH="${SDK_DIR}/usr/lib:${LIBRARY_PATH:-}"
fi

IS_SIMULATOR=0
if [ "${LLVM_TARGET_TRIPLE_SUFFIX-}" = "-simulator" ]; then
  IS_SIMULATOR=1
fi

for arch in $ARCHS; do
  case "$arch" in
    x86_64)
      if [ $IS_SIMULATOR -eq 0 ]; then
        echo "Building for x86_64, but not a simulator build. What's going on?" >&2
        exit 2
      fi

      # Intel iOS simulator
      export CFLAGS_x86_64_apple_ios="-target x86_64-apple-ios"
      $HOME/.cargo/bin/cargo rustc -p $FFI_TARGET --lib --crate-type staticlib $RELFLAG --target x86_64-apple-ios
      ;;

    arm64)
      if [ $IS_SIMULATOR -eq 0 ]; then
        # Hardware iOS targets
        $HOME/.cargo/bin/cargo rustc -p $FFI_TARGET --lib --crate-type staticlib $RELFLAG --target aarch64-apple-ios
      else
        # M1 iOS simulator -- currently in Nightly only and requires to build `libstd`
        $HOME/.cargo/bin/cargo rustc -p $FFI_TARGET --lib --crate-type staticlib $RELFLAG --target aarch64-apple-ios-sim
      fi
  esac
done
