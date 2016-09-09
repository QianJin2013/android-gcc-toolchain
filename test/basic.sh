#!/bin/bash
function _agcc-msg { echo "$@" >&2; }
function _agcc-dbg { [[ $AGCC_DBG == 1 ]] && echo "$@" >&2; }
function _agcc-guide { echo "" "$@" >&2; }

thisDir=${0%/*}; if target=`readlink "${0}"`; then if [[ $target == /* ]]; then thisDir=${target%/*}; elif [[ $target == */* ]]; then thisDir+=/${target%/*}; fi; fi
_agcc-dbg "thisDir: \"$thisDir\""
hackDir=$thisDir/../hack

[[ `android-gcc-toolchain - 2>&1 <<<"echo hi"` == */std-toolchains/android-9-arm/bin/ ]] && echo OK || echo $LINENO
[[ `android-gcc-toolchain arm     2>&1 <<<"echo hi"` == hi ]] && echo OK || echo $LINENO
[[ `android-gcc-toolchain arm    --hack ar-dual-os,gcc-no-lrt,gcc-m32 -C  2>&1 <<<"echo hi"` == *"invalid long option"* ]] && echo OK || echo $LINENO
[[ `android-gcc-toolchain arm    --host ar-dual-os,gcc-no-lrt,gcc-m32 -C  2>&1 <<<"echo hi"` == hi ]] && echo OK || echo $LINENO
[[ `android-gcc-toolchain arm     -c 2>&1 <<<"echo hi"` == hi ]] && echo OK || echo $LINENO
[[ `android-gcc-toolchain arm     -C 2>&1 <<<"echo hi"` == hi ]] && echo OK || echo $LINENO
[[ `android-gcc-toolchain --host a 2>&1 <<<"echo hi"` == *"--host option must be used with -C option"* ]] && echo OK || echo $LINENO
[[ `android-gcc-toolchain --host a -C 2>&1 <<<"echo hi"` == *"invalid host compiler rule"* ]] && echo OK || echo $LINENO

mkdir $hackDir/gcc-m32/xxx
[[ `android-gcc-toolchain --host gcc-m32/xxx -C 2>&1 <<<"echo hi"` == *"unavailable host compiler rule"* ]] && echo OK || echo $LINENO
touch $hackDir/gcc-m32/xxx/xxx
[[ `android-gcc-toolchain --host gcc-m32/xxx -C 2>&1 <<<"echo hi"` == "hi" ]] && echo OK || echo $LINENO
rm -fr $hackDir/gcc-m32/xxx

[[ `android-gcc-toolchain --host ,, -C 2>&1 <<<"echo hi"` == *"invalid host compiler rule"* ]] && echo OK || echo $LINENO
[[ `android-gcc-toolchain --host ,, -C --help-host 2>&1 <<<"echo hi"` == *"Available host compiler rules"*gcc-m32* ]] && echo OK || echo $LINENO
