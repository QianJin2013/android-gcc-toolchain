if [[ $ANDROID_GCC_DBG ]]; then
    function _agcc-dbg {
        echo "$@" >&2
    }
else
    function _agcc-dbg {
        :
    }
fi

function _agcc-msg {
    echo "$@" >&2
}

function _agcc-toolchain {
    [[ ! $NDK ]] && _agcc-msg "\$NDK is empty. Please run following command first: export NDK=__the_top_dir_of_installed_NDK__" && return 1

    local ARCH APIL STL FORCE ARCH_PREFIX STL_TAG

    _agcc-dbg "analysing args {"
    while [[ $# -gt 0 ]]; do
        _agcc-dbg "  \"$1\""
        case $1 in
            --arch    ) case $2 in [!-]*|"") ARCH=$2; _agcc-dbg "  =\"$2\""; shift;; esac;;
            --api     ) case $2 in [!-]*|"") APIL=$2; _agcc-dbg "  =\"$2\""; shift;; esac;;
            --stl     ) case $2 in [!-]*|"") STL=$2;  _agcc-dbg "  =\"$2\""; shift;; esac;;
            --force   ) FORCE=$1 ;;
            arm|arm64|x86|x86_64|mips|mips64) ARCH=$1 ;;
            min|max|0 ) APIL=$1 ;;
            gnustl|libc++|stlport ) STL=$1 ;;
            -c|-C     ) break ;; #stop parse due to the later args is command and its args
            -*        ) : ;; #skip unrelated option keyword
            *         ) [[ $1 -gt 0 ]] && APIL=$1 ;;
        esac
        shift
    done
    _agcc-dbg "}"

    if [[ $ANDROID_GCC_DBG ]]; then
        _agcc-dbg "analyse result {"
        _agcc-dbg "  ARCH  \"$ARCH\""
        _agcc-dbg "  APIL  \"$APIL\""
        _agcc-dbg "  STL   \"$STL\""
        _agcc-dbg "  FORCE \"$FORCE\""
        _agcc-dbg "}"
    fi

    ############################################################
    #get arch and cross-compile executable's name prefix
    case ${ARCH:=arm} in
        arm)    ARCH_PREFIX=arm-linux-androideabi- ;;
        arm64)  ARCH_PREFIX=aarch64-linux-android- ;;
        x86)    ARCH_PREFIX=i686-linux-android- ;;
        x86_64) ARCH_PREFIX=x86_64-linux-android- ;;
        mips)   ARCH_PREFIX=mipsel-linux-android- ;;
        mips64) ARCH_PREFIX=mips64el-linux-android- ;;
        *) _agcc-msg "\"$ARCH\" is not a valid arch. It must be arm(default)|arm64|x86|x86_64|mips|mips64" && return 1 ;;
    esac

    ############################################################
    #get Android API level
    case ${APIL:=min} in
        min|max|0)
            local dirPrefix=$NDK/platforms/android-
            local dirSuffix=/arch-$ARCH
            local dirList=() #save ordered dir list

            #append dir list if matches
            local tmpList=("$dirPrefix"?$dirSuffix)
            [[ ${tmpList[0]} != "$dirPrefix?$dirSuffix" ]] && dirList=("${dirList[@]}" "${tmpList[@]}")
            local tmpList=("$dirPrefix"??$dirSuffix)
            [[ ${tmpList[0]} != "$dirPrefix??$dirSuffix" ]] && dirList=("${dirList[@]}" "${tmpList[@]}")

            #get first or last dir name, e.x. ...android-9/arch-... or ...android-24/arch-...
            if [[ $APIL == min || $APIL == 0 ]]; then
                APIL=${dirList[0]}
            else
                APIL=${dirList[${#dirList[@]}-1]}
            fi

            #remove prefix and suffix to get pure number
            APIL=${APIL#$dirPrefix}
            APIL=${APIL%$dirSuffix}

            [[ ! $APIL ]] && _agcc-msg "$dirPrefix*$dirSuffix not found" && return 1
            ;;
        *[!0-9]*)
            _agcc-msg "\"$APIL\" is not a valid Android API level. It must be min(default)|max|an integer" && return 1
            ;;
    esac

    ############################################################
    #get C++ STL
    case ${STL:=gnustl} in
        gnustl ) STL_TAG="" ;;
        libc++ ) STL_TAG=-stlc++ ;;
        stlport) STL_TAG=-stlport ;;
        *) _agcc-msg "\"$STL\" is not a valid C++ STL. It must be gnustl(default)|libc++|stlport" && return 1 ;;
    esac

    ############################################################
    #create or check standalone toolchain
    local NAME=android-$APIL-$ARCH$STL_TAG
    local DIR=$NDK/std-toolchains/$NAME
    local BIN=$DIR/bin

    if [[ ! -d $DIR ]]; then
        _agcc-msg "Make \$NDK/std-toolchains/$NAME because it does not exists..."
        "$NDK/build/tools/make_standalone_toolchain.py" --arch "$ARCH" --api "$APIL" --stl "$STL" --install-dir "$DIR" $FORCE

        if [[ -e "$BIN/$ARCH_PREFIX"gcc ]]; then
            _agcc-msg "Done"
            _agcc-msg ""
        else
            _agcc-msg "Failed to create NDK Standalone toolchain."
            _agcc-msg ""
            return 1
        fi
    else
        ls "$BIN/$ARCH_PREFIX"gcc > /dev/null || return 1
    fi

    ############################################################
    #make some symbol-link such as gcc @-> arm-linux-androideabi-gcc
    #also link cc @-> gcc
    pushd "$BIN" > /dev/null
        for f in $ARCH_PREFIX*; do s=${f/$ARCH_PREFIX}; [[ ! -e $s && -x $f ]] && ln -s "$f" "$s"; done
        [[ ! -e cc ]] && ln -s "$ARCH_PREFIX"gcc cc
    popd > /dev/null

    ############################################################
    #restore $PATH and bash prompt changed by android-gcc-enter
    android-gcc-leave

    #save some var for further process
    ANDROID_GCC_PREFIX=$BIN/$ARCH_PREFIX
    ANDROID_GCC_BIN=$BIN
    ANDROID_GCC_TAG=$NAME
    return 0
}

function android-gcc-enter {
    if [[ $1 == --help ]]; then
        _agcc-msg "Switch toolchain(create if) & redirect cross-compile and related commands there."
        _agcc-msg "Options: [[--arch] ARCH］[[--api] APIL] [[--stl] STL] [--force]"
        _agcc-msg " --arch ARCH    Android architecture"
        _agcc-msg "   ARCH         {arm(default)|arm64|x86|x86_64|mips|mips64}"
        _agcc-msg " --api APIL     Android API Level"
        _agcc-msg "   APIL         {min(default)|max|an integer}"
        _agcc-msg " --stl STL      C++ STL to use"
        _agcc-msg "   STL          {gnustl(default)|libc++|stlport}"
        _agcc-msg " --force        delete existing toolchain dir then create"
        _agcc-msg ""
        _agcc-msg "Toolchain commands: (most are link to file like arm-linux-androideabi-xxx)"
        _agcc-msg " cc(->gcc) gcc g++ c++ cpp clang clang++ ld ar as ranlib strip"
        _agcc-msg " readelf objdump nm c++filt strings elfedit objcopy"
        _agcc-msg " addr2line size gcov gprof dwp"
        _agcc-msg " gdb yasm llvm-as llvm-dis llvm-link FileCheck"
        _agcc-msg " make awk python pydoc"
        _agcc-msg " ndk-depends ndk-gdb ndk-which ndk-stack"
        _agcc-msg ""
        return 1
    fi

    #create standalone toolchain(once)
    _agcc-toolchain "$@" || return 1

    ############################################################
    #modify $PATH to redirect gcc ... to toolchain/bin/gcc ...
    #change bash prompt
    PATH=$ANDROID_GCC_BIN:$PATH
    PS1="[$ANDROID_GCC_TAG] $PS1"

    #clear CC etc.
    [[ $CC ]] && OLD_CC=$CC && CC=
    [[ $CXX ]] && OLD_CC=$CXX && CXX=
    [[ $LD ]] && OLD_LD=$LD && LD=
    [[ $AR ]] && OLD_AR=$AR && AR=
    [[ $AS ]] && OLD_AS=$AS && AS=
    [[ $RANLIB ]] && OLD_RANLIB=$RANLIB && RANLIB=
    [[ $STRIP ]] && OLD_STRIP=$STRIP && STRIP=
    [[ $NM ]] && OLD_NM=$NM && NM=
    [[ $LINK ]] && OLD_LINK=$LINK && LINK=

    ############################################################
    echo "# NDK standalone toolchain for $ANDROID_GCC_TAG"
    echo "# "
    echo "# The follwoing bin dir has been prepended to \$PATH."
    echo "#  \"\$NDK/std-toolchains/$ANDROID_GCC_TAG/bin\""
    echo "# "
    echo "# So you can use these commands directly here:"
    echo "#  cc(->gcc) gcc g++ c++ cpp clang clang++ ld ar as ranlib strip"
    echo "#  readelf objdump nm c++filt strings elfedit objcopy"
    echo "#  addr2line size gcov gprof dwp"
    echo "#  gdb yasm llvm-as llvm-dis llvm-link FileCheck"
    echo "#  make awk python pydoc"
    echo "#  ndk-depends ndk-gdb ndk-which ndk-stack"
    echo "# "
    echo "# Type android-gcc-leave to restore \$PATH and bash prompt."
}

function android-gcc-leave {
    #restore $PATH
    if [[ $ANDROID_GCC_BIN ]]; then
        PATH=${PATH#$ANDROID_GCC_BIN:}        #remove bin: from head
        PATH=${PATH//:$ANDROID_GCC_BIN:/:}    #replace :bin: with :
        PATH=${PATH%:$ANDROID_GCC_BIN}        #remove :bin
    fi

    #restore bash prompt $PS1
    [[ $ANDROID_GCC_TAG && $PS1 ]] && PS1=${PS1/\[$ANDROID_GCC_TAG\] }

    unset ANDROID_GCC_PREFIX ANDROID_GCC_TAG ANDROID_GCC_BIN

    #restore CC etc.
    [[ $OLD_CC ]] && CC=$OLD_CC && unset OLD_CC
    [[ $OLD_CXX ]] && CC=$OLD_CXX && unset OLD_CXX
    [[ $OLD_LD ]] && LD=$OLD_LD && unset OLD_LD
    [[ $OLD_AR ]] && AR=$OLD_AR && unset OLD_AR
    [[ $OLD_AS ]] && AS=$OLD_AS && unset OLD_AS
    [[ $OLD_RANLIB ]] && RANLIB=$OLD_RANLIB && unset OLD_RANLIB
    [[ $OLD_STRIP ]] && STRIP=$OLD_STRIP && unset OLD_STRIP
    [[ $OLD_NM ]] && NM=$OLD_NM && unset OLD_NM
    [[ $OLD_LINK ]] && LINK=$OLD_LINK && unset OLD_LINK
}

function android-gcc-toolchain {
    if [[ $1 == --help ]]; then
        _agcc-msg "Switch toolchain(create if) & show path of toolchain bin dir."
        _agcc-msg "Options: [[--arch] ARCH］[[--api] APIL] [[--stl] STL] [--force]"
        _agcc-msg "         [--cross] [--hack]"
        _agcc-msg "         [-c|-C [command [arguments] ]"
        _agcc-msg " --arch ARCH    Android architecture"
        _agcc-msg "   ARCH         {arm(default)|arm64|x86|x86_64|mips|mips64}"
        _agcc-msg " --api APIL     Android API Level"
        _agcc-msg "   APIL         {min(default)|max|an integer}"
        _agcc-msg " --stl STL      C++ STL to use"
        _agcc-msg "   STL          {gnustl(default)|libc++|stlport}"
        _agcc-msg " --force        Delete existing toolchain dir then create"
        _agcc-msg " --cross        Show prefix of cross-compile commands instead of bin dir"
        _agcc-msg " --hack         When -C, correctly handle ar, ld -lrt"
        _agcc-msg " -c|-C command  Run command with cross-compile env. Should be placed at the end"
        _agcc-msg "--------------------------------------------------------------------------------"
        _agcc-msg "Toolchain commands: (most are link to file like arm-linux-androideabi-xxx)"
        _agcc-msg " cc(->gcc) gcc g++ c++ cpp clang clang++ ld ar as ranlib strip"
        _agcc-msg " readelf objdump nm c++filt strings elfedit objcopy"
        _agcc-msg " addr2line size gcov gprof dwp"
        _agcc-msg " gdb yasm llvm-as llvm-dis llvm-link FileCheck"
        _agcc-msg " make awk python pydoc"
        _agcc-msg " ndk-depends ndk-gdb ndk-which ndk-stack"
        _agcc-msg "--------------------------------------------------------------------------------"
        _agcc-msg "Without -c or -C options, output will be bin path(slash ended). e.g."
        _agcc-msg "  \$NDK/std-toolchains/android-9-arm/bin/"
        _agcc-msg ""
        _agcc-msg "--cross means append arch prefix to all above bin path, e.g."
        _agcc-msg "  \"...bin/\" changed to \"...bin/arm-linux-androideabi-\""
        _agcc-msg "--------------------------------------------------------------------------------"
        _agcc-msg "-c command...: Run command(bash if omitted) with \$CC etc. set:"
        _agcc-msg " CC,CXX,LD,AR,AS,RANLIB,STRIP,NM,LINK"
        _agcc-msg " e.g. CC=\"\$NDK/std-toolchains/android-9-arm/bin/gcc\""
        _agcc-msg "--------------------------------------------------------------------------------"
        _agcc-msg "The uppercase -C is same as -c except env name are suffixed with \"_target\""
        _agcc-msg " e.g. CC_target=\"\$NDK/std-toolchains/android-9-arm/bin/gcc\""
        _agcc-msg ""
        _agcc-msg "--hack works for -C. Currently it solves following problems for Mac OS X:"
        _agcc-msg "1. ar: Some project does not honor \$AR_target when make Android-side static"
        _agcc-msg " lib(*.a). Instead, they call Mac-side ar command, so cause wrong result."
        _agcc-msg " --hack prepend hack/...bin to \$PATH so ...bin/ar will be called instead."
        _agcc-msg " It detect input *.o file format, Mac or Android, then call correct one."
        _agcc-msg "2. librt: Some project use link option -lrt (librt) comes from linux, but"
        _agcc-msg " Mac have no librt, so cause \"library not found for -lrt\"."
        _agcc-msg " --hack append hack/...lib to \$LIBRARY_PATH, so the fake librt can be linked."
        _agcc-msg " Te fake librt does not export any symbol, it is just a reference to the most"
        _agcc-msg " commonly linked lib: /usr/lib/libSystem.B.dylib"
        _agcc-msg "--------------------------------------------------------------------------------"
        _agcc-msg "Examples:"
        _agcc-msg " \$ \`android-gcc-toolchain arm64\`gcc a.c"
        _agcc-msg " \$ cd ~/Download/ffmpeg && ./configure --enable-cross-compile --cross-prefix=\`android-gcc-toolchain arm64\` --arch=arm64 --target-os=linux"
        _agcc-msg " \$ cd ~/Download/node; GYP_DEFINES=host_os=mac android-gcc-toolchain arm64 --hack -C"
        _agcc-msg " bash-3.2\$ ./configure --dest-cpu=arm64 --dest-os=android"
        _agcc-msg " bash-3.2\$ make -j4"
        return 1
    fi

    #create standalone toolchain(once)
    _agcc-toolchain "$@" || { echo "/android-gcc-toolchain-failed/"; return 1; }

    local resultPath=$ANDROID_GCC_BIN/
    for arg in "$@"; do 
        if [[ $arg == "--cross" ]]; then
            resultPath=$ANDROID_GCC_PREFIX
            break
        fi
    done

    local needHack
    while [[ $# -gt 0 ]]; do
        if [[ $1 == "--hack" ]]; then
            needHack=1

        elif [[ $1 == "-c" ]]; then
            shift
            local cmd_and_args=(bash)
            [[ $1 ]] && cmd_and_args=("$@")

            CC=${resultPath}gcc \
            CXX=${resultPath}g++ \
            LD=${resultPath}ld \
            AR=${resultPath}ar \
            AS=${resultPath}as \
            RANLIB=${resultPath}ranlib \
            STRIP=${resultPath}strip \
            NM=${resultPath}nm \
            LINK=${resultPath}g++ \
            "${cmd_and_args[@]}"

            return

        elif [[ $1 == "-C" ]]; then
            shift
            local cmd_and_args=(bash)
            [[ $1 ]] && cmd_and_args=("$@")

            if [[ $needHack ]]; then
                local thisDir=${BASH_SOURCE[0]%/*}
                local thisOS=`uname -s` #Darwin or Linux
                local hackDir=$thisDir/hack/$thisOS

                [[ ! -d $hackDir ]] && needHack=""
            fi

            if [[ $needHack ]]; then
                local _LIBRARY_PATH=$hackDir/lib
                [[ $LIBRARY_PATH ]] && _LIBRARY_PATH=$LIBRARY_PATH:$_LIBRARY_PATH

                CC_target=${resultPath}gcc \
                CXX_target=${resultPath}g++ \
                LD_target=${resultPath}ld \
                AR_target=${resultPath}ar \
                AS_target=${resultPath}as \
                RANLIB_target=${resultPath}ranlib \
                STRIP_target=${resultPath}strip \
                NM_target=${resultPath}nm \
                LINK_target=${resultPath}g++ \
                _AR_host=`which ar` \
                PATH=$hackDir/bin:$PATH \
                LIBRARY_PATH=$_LIBRARY_PATH \
                "${cmd_and_args[@]}"
            else
                CC_target=${resultPath}gcc \
                CXX_target=${resultPath}g++ \
                LD_target=${resultPath}ld \
                AR_target=${resultPath}ar \
                AS_target=${resultPath}as \
                RANLIB_target=${resultPath}ranlib \
                STRIP_target=${resultPath}strip \
                NM_target=${resultPath}nm \
                LINK_target=${resultPath}g++ \
                "${cmd_and_args[@]}"
            fi

            return
        fi

        shift
    done

    echo "$resultPath"
    return 0
}

function android-gcc {
    if [[ $1 == --help ]]; then
        _agcc-msg "Call gcc of toolchain(create if). All arguments are same as original gcc."
        _agcc-msg "This tool is affected by following env vars"
        _agcc-msg " \$ARCH         {arm(default)|arm64|x86|x86_64|mips|mips64}"
        _agcc-msg "                Android CPU architecture"
        _agcc-msg " \$APIL         {min(default)|max|an integer}"
        _agcc-msg "                Android API level"
        _agcc-msg " \$STL          {gnustl(default)|libc++|stlport}"
        _agcc-msg "                C++ STL to use"
        _agcc-msg ""
        _agcc-msg "You can config these env vars for whole bash session, e.g."
        _agcc-msg " export ARCH=arm64"
        _agcc-msg " android-gcc somefile.c"
        _agcc-msg ""
        _agcc-msg "Alternatively, you can specify these env vars just in time., e.g."
        _agcc-msg " ARCH=arm64 APIL=22 android-gcc somefile.c"
        _agcc-msg ""
        return 1
    fi

    #switch toolchain and get prefix of cross-compile commands
    local prefix=`android-gcc-toolchain --arch $ARCH --api "$APIL" --stl "$STL"`
    [[ -z $prefix || $prefix == "/android-gcc-toolchain-failed/" ]] && return 1

    #run cross-compile commands with original arguments 
    ${prefix}gcc "$@"
}

function android-gcc++ {
    if [[ $1 == --help ]]; then
        _agcc-msg "Call g++ of toolchain(create if). All arguments are same as original g++."
        _agcc-msg "This tool is affected by following env vars"
        _agcc-msg " \$ARCH         {arm(default)|arm64|x86|x86_64|mips|mips64}"
        _agcc-msg "                Android CPU architecture"
        _agcc-msg " \$APIL         {min(default)|max|an integer}"
        _agcc-msg "                Android API level"
        _agcc-msg " \$STL          {gnustl(default)|libc++|stlport}"
        _agcc-msg "                C++ STL to use"
        _agcc-msg ""
        _agcc-msg "You can config these env vars for whole bash session, e.g."
        _agcc-msg " export ARCH=arm64"
        _agcc-msg " android-gcc somefile.c"
        _agcc-msg ""
        _agcc-msg "Alternatively, you can specify these env vars just in time., e.g."
        _agcc-msg " ARCH=arm64 APIL=22 android-gcc++ somefile.cc"
        _agcc-msg ""
        return 1
    fi

    #switch toolchain and get prefix of cross-compile commands
    local prefix=`android-gcc-toolchain --arch "$ARCH" --api "$APIL" --stl "$STL"`
    [[ -z $prefix || $prefix == "/android-gcc-toolchain-failed/" ]] && return 1

    #run cross-compile commands with original arguments 
    ${prefix}g++ "$@"
}

##############################################################################
if [[ $1 == --save || $1 == --restore ]]; then
    function _agcc-save-or-restore-bash-profile {
        #get bash_profile path
        local profile=$2
        [[ ! $profile ]] && profile=~/.bash_profile

        local profile2=`readlink $profile 2>/dev/null`
        [[ $profile2 ]] && profile=$profile2

        #get current script dir
        local thisDir=${BASH_SOURCE[0]%/*}

        local didBackup

        #check whether bash_profile contains ANDROID_GCC_BASHRC mark
        if grep -q ANDROID_GCC_BASHRC "$profile" 2>/dev/null; then
            _agcc-msg "Backup \"$profile\" -> \"${profile}.bak\""
            cp "$profile" "${profile}.bak" || return 1
            didBackup=true

            _agcc-msg "Remove lines contains \"ANDROID_GCC_BASHRC\" from \"$profile\"."
            grep -v ANDROID_GCC_BASHRC "$profile" > "${profile}.tmp"
            [[ $? > 1 ]] && return 1

            mv "${profile}.tmp" "$profile" || return 1
            _agcc-msg "Done"
        else
            [[ -f $profile ]] && _agcc-msg "\"$profile\" is already clean."
        fi

        if [[ $1 == --save ]]; then
            if [[ ! $didBackup && -f $profile ]]; then
                _agcc-msg "Backup \"$profile\" -> \"${profile}.bak\""
                cp "$profile" "${profile}.bak" || return 1
            fi

            _agcc-msg "Append init script(with mark \"ANDROID_GCC_BASHRC\") -> \"$profile\""
            echo "#                                                  mark for ANDROID_GCC_BASHRC"            >> "$profile" || return 1
            echo "export ANDROID_GCC_BASHRC_DIR=\"$thisDir\""                                                >> "$profile" || return 1
            echo "source \"\$ANDROID_GCC_BASHRC_DIR/bashrc\" && export PATH=\$PATH:\$ANDROID_GCC_BASHRC_DIR" >> "$profile" || return 1

            _agcc-msg "Done"

            [[ ! -x $thisDir/android-gcc ]] && chmod a+x "$thisDir/android-gcc"
            [[ ! -x $thisDir/android-gcc++ ]] && chmod a+x "$thisDir/android-gcc++"
            [[ ! -x $thisDir/android-gcc-toolchain ]] && chmod a+x "$thisDir/android-gcc-toolchain"
            [[ -d $thisDir/hack/Darwin/bin && ! -x $thisDir/hack/Darwin/bin/ar ]] && chmod a+x "$thisDir/hack/Darwin/bin/ar"
        fi
        return 0
    }

    _agcc-save-or-restore-bash-profile "$@"
fi
