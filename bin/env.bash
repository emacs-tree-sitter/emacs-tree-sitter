set -euo pipefail

system=$(uname)
if [[ $system == "Linux" ]] || [[ $system == "NetBSD" ]]; then
    ext="so"
elif [[ $system == "Darwin" ]]; then
    ext="dylib"
else
    echo "Unsupported system: $system"
    exit 1
fi

here=$(cd "$(dirname "$BASH_SOURCE")"; pwd)

PROJECT_ROOT=$(cd "$here/.."; pwd)
export PROJECT_ROOT

export MODULE_ORIGINAL=${MODULE_ORIGINAL:-libtsc_dyn.$ext}
export MODULE_NAME=${MODULE_NAME:-tsc-dyn}
export MODULE_RENAMED=${MODULE_NAME}.$ext
export EMACS=${EMACS:-emacs}
