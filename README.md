# android-gcc-toolchain
Enable you to use NDK's standalone toolchain easily, quickly and magically for cross-compile.

As an example, see [Build NodeJS for Android perfectly](#build-nodejs-for-android-perfectly).

Tested OS:
- **Mac**: OS X 10.11.5/10.11.6 EI Capitan (64bit)
- **Linux**: Ubuntu 16.04 (64bit)
- **Windows**: Windows Pro 7.
 
    Although not supported directly,
    it can be used in Docker (Docker image id: `osexp2000/android-gcc-toolchain`)
    via [Docker-Toolbox](https://github.com/docker/toolbox/releases/download/v1.12.0/DockerToolbox-1.12.0.exe).
    See [Features-9: Use this tool in Docker](#docker).


## Prerequisite

NDK: tested on
 - [NDK 12.1.29 For Mac 64bit](https://dl.google.com/android/repository/android-ndk-r12b-darwin-x86_64.zip)
 - [NDK 12.1.29 For Linux 64bit](https://dl.google.com/android/repository/android-ndk-r12b-linux-x86_64.zip)

Install Android NDK and set env var `NDK` to the dir: `export NDK=__the_top_dir_of_installed_NDK__`.

Otherwise, it will guess NDK dir from env vars: ANDROID_NDK_ROOT ANDROID_NDK_HOME NDK_ROOT NDKROOT ANDROID_NDK ANDROID_SDK_HOME
 ANDROID_SDK_ROOT ANDROID_SDK ANDROID_HOME ANDROID_ROOT.

## Install

Nothing. Just use the `android-gcc-toolchain` with full path, 
otherwise link it to /usr/local/bin/ or add the path to the $PATH. 

## Screenshot

- Run android gcc related commands easily
![android-gcc](img/android-gcc.png)

- Enter a dedicated shell where can run android gcc related commands easily:
![android-gcc-enter](img/android-gcc-enter.png)

## Usage

Use or create toolchain, set env and run command, or print "the bin dir/".

*Note: words in `[  ]` means may be omitted.*
<a name="options"></a>
```
android-gcc-toolchain [OPTIONS] [CMD [ARGS...]]
--------------------------------------------------------------------------------
OPTIONS: Toolchain options, Env Mode, Misc options

Toolchain options: specify which toolchain to use or create
 [--arch] ARCH  Android architecture:
                {arm(default)|arm64|x86|x86_64|mips|mips64} or aliases:
                i386,ia32(=x86), x64(=x86_64), mipsel, mipsel64
 [--api]  APIL  Android API level:
                {min(default)|max|an integer}
 [--stl]  STL   C++ STL to use:
                {gnustl(default)|libc++|stlport}
 --force        Delete existing toolchain dir then create
 -v|--verbose   Show verbose information
 --copy         Force copy files instead of create hard link of files when
                create toolchain first time

Env Mode: Specify whether set $PATH or $CC... or $CC_target...
 omitted        This is the Redirect Mode.
                Set $PATH to redirect gcc... to the toolchain's gcc...
                e.g. export PATH=".../std-toolchains/.../bin:$PATH"
 -c             Set $CC,$CXX,$LINK,$AR,$AS,$RANLIB,$LD,$STRIP,$NM
                e.g. export CC=".../std-toolchains/.../bin/gcc"
 -C             Set $CC_target,$CXX_target,$LINK_target,...,$NM_target
                e.g. export CC_target=".../std-toolchains/.../bin/gcc"

Compiler options:
 --ccache       Speed up compilation by CCACHE. This will wrap android gcc...
                or $CC... or $CC_target... with ccache. When in -c or -C mode,
                this implies appending a host-side hack option "ccache".

Hack options:
 --hack  HACK   Hack host(local) compiler commands. Must be combination of
                available options(use --help-hack to show), joined by comma.
                This option only works for -c or -C option.
                For detail, refer to "About Hack mode" section.

Special options:
 -              Means the end of options and next arg is CMD. But if nothing 
                followed, then just print output the bin dir(slash ended).
 --             Same as -
--------------------------------------------------------------------------------
CMD and ARGS: The external command to be run

 CMD            Any command. Default is /bin/bash.
                The first non-option arg will be treated as CMD.
                To avoid ambiguous with other option, place - or -- before CMD
 ARGS...        The arguments for the CMD
```

The syntax is very natural, option keyword itself(`--arch` etc.) can be omitted, order does not care. e.g.

The following commands are same:
```
android-gcc-toolchain --arch arm64 --api 24
android-gcc-toolchain arm64 24
```

When want run commands(such as gcc), just prepend above command to your command. e.g. 
`CMD ARGS...` -> `android-gcc-toolchain arm64` `CMD ARGS...`, it works as it implies.

----

## Features

### 1. Run android gcc related commands easily.

- Just prepend `android-gcc-toolchain` to your gcc related command.

    ```
    android-gcc-toolchain gcc a.c
    android-gcc-toolchain arm64 gcc a.c
    ```
    
<a name="dedicated-shell"></a>    
### 2. Start a dedicated shell where can run android gcc related commands easily.

- start an interactive shell with gcc... ready

    ```
    android-gcc-toolchain arm64                               #bash
    android-gcc-toolchain arm64 zsh                           #zsh
    ```
    
    See also: [redirected commands list](#about-redirect-mode).
    
- start an interactive bash with $CC... predefined

    ```
    android-gcc-toolchain arm64 -c
    ```

    See also: [env vars passed to CMD](#about-env-vars-passed-to-cmd) 

- start an interactive bash with $CC_target... predefined
    
    ```
    android-gcc-toolchain arm64 -C
    ```

    See also: [env vars passed to CMD](#about-env-vars-passed-to-cmd).


- *Notes*

    To feed multiple commands to the shell non-interactively,
    you can use `<<EOF`[Here Document](http://tldp.org/LDP/abs/html/here-docs.html) or 
    `<<<"..."`[Here String(bash only)](http://tldp.org/LDP/abs/html/x17837.html)
    or `bash -c` to feed commands to the shell, or you call this tool multiple times.
    With options `arm64`,`-C` as example:
    
    ```
    $ android-gcc-toolchain arm64 -C <<EOF
    CMD1 ARGS... && CMD2 ARGS...
    EOF
    $ android-gcc-toolchain arm64 -C <<< "CMD1 ARGS... && CMD2 ARGS..." 
    $ android-gcc-toolchain arm64 -C sh -c "CMD1 ARGS... && CMD2 ARGS..." 
    $ android-gcc-toolchain arm64 -C CMD1 ARGS && android-gcc-toolchain arm64 -c CMD2 ARGS..." 
    ```

    *bash-only: you can use \EOF to disable pathname and var expansion*

### 3. Cross-compile an AUTOCONF project(e.g. ffmpeg) easily.

- Just use `android-gcc-toolchain arm64 -` as prefix of gcc....

    You can treat `-` as a special command which just print toolchain bin dir(slash ended). e.g.
    the result is `/Users/q/Library/Android/sdk/ndk-bundle/std-toolchains/android-21-arm64/bin/`
    
    ```
    ./configure --enable-cross-compile --cross-prefix=`android-gcc-toolchain arm64 -` --target-os=linux --arch=arm64 && make
    ```

### 4. Cross-compile an GYP project(e.g. NodeJS) easily.

- Redirect all compiler related commands to the toolchain's one.

    ```
    android-gcc-toolchain arm64 <<< "./configure --dest-cpu=arm64 --dest-os=android --without-snapshot --without-inspector --without-intl && make"
    ```
    
    This is the most concrete way to do target-only cross-compile.
    Attempt to call gcc related commands without explicit path will fall into the toolchain's one.
    
- Enter a `$CC`... predefined environment to build.

    ```
    android-gcc-toolchain arm64 -c <<< "./configure --dest-cpu=arm64 --dest-os=android --without-snapshot --without-inspector --without-intl && make"
    ```
    
    *The first `-c` option is for `android-gcc-toolchain`, not for bash.*   
    This is a graceful way to do target-only cross-compile.
    
- Enter a `$CC_target`... predefined environment to build.

    ```
    android-gcc-toolchain arm64 -C <<< "./configure --dest-cpu=arm64 --dest-os=android && make"
    ```
    
    *The `-C` option is UPPER CASE.*  
    This is the most graceful way to do a hybrid cross-compile, it assumes:
    - Compiler commands for target(Android) honor the `$CC_target`...,
    - Compiler commands for host(Mac) honor the `$CC_host`... or `$CC`... or pick from `$PATH`.
    
    **But above command will run into error, just because several wrong project settings.**  
    You can use [Hack Mode](#about-hack-mode) to overcome them easily, 
    otherwise you have to find and modify the wrong settings each time.

### 5. Automatically get minimum/maximum `Android API level` from NDK.

- Specify `max`, `min`, or an valid Android API level to the tool.

    By default, get minimum API level from NDK for specified arch smartly, 
    from actual folder names `$NDK/platforms/android-*/arch-$ARCH`, instead of a fixed 21.

    ```
    $ android-gcc-toolchain arm64 max
      ...
      android-24-arm64 toolchain is ready! ...
    ```

### 6. Automatically create standalone toolchain at first time.

- As described in [options](#options), options are compatible with $NDK/build/tools/make_standalone_toolchain.py:
`--arch`,`--api`, `--stl`,`--force`,`--verbose`.

### 7. Use hard links to speed up creation of toolchain and save disk space.

- By default, use hard links. The creation became very fast.
- This is done by run a modified py file on-the-fly instead of original $NDK/build/tools/make_standalone_toolchain.py. 
- The modified py file replace shutil.copy2 and shutil.copytree with customized copy2 and copytree which use hard link.
- You can specify `--copy` to force use traditional copy mode. 

### 8. Support ccache to speed up repeating compilation.

- Specify `--ccache` option will use `ccache gcc ...` to compile.
- This option cooperate with Redirection Mode or Env Mode -c($CC...) or -C($CC_target...).
- When -c or -C, it implicitly add a hack option `ccache` to supersede all host-side compiler commands with a ccache wrapper.

- First you need install `ccache` by `brew install ccache` on Mac or `sudo apt-get install ccache` on Linux. then:

    ```
    export USE_CCACHE=1             #you'd better put this line to your ~/.bash_profile etc.
    export CCACHE_DIR=~/ccache      #you'd better put this line to your ~/.bash_profile etc.
    ccache -M 50G                   #set cache size once is ok
    ```

<a name=docker></a>
### 9. Use this tool in Docker (Docker image id: `osexp2000/android-gcc-toolchain`)

- You can run docker with docker to enter a [dedicated shell](#dedicated-shell). e.g.
 
    ```
    $ docker run -it osexp2000/android-gcc-toolchain arm64 --ccache
    ... ...
    [android-21-arm64] YOUR_COMMAND_HERE 
    ```
    
    *(do not enter the `$` or `[...]` which are just a prompt for illustrate).*

- Quick start of docker: 
    - The `-it` means `--interactive --tty`.
    - Use volume mapping `-v HOST_DIR_OR_FILE:CONTAINER_DIR_OR_FILE` to map dir/files to container. 
      Note: **docker-machine on Windows need you put the host dir or files under `C:\Users\...`(e.g. C:\Users\q\Downloads),
      and the `HOST_DIR_OR_FILE` must be converted to `/c/Users/...` style.
      Otherwise mapping not works.**
    - Use `docker cp` to copy files in/out when forgot to use volume mapping.
    - Do not specify `-t`(`--tty`) if to feed commands to docker via <<<"Here String" or <<EOF Here Document.

### 10. (TODO) Support brew install, bash_autocomplete 

----

## About where the toolchain created

- This tool create dir in your NDK dir, in following format:   
 `$NDK/std-toolchains/android-APIL-ARCH[STL_TAG]`

- This is not only for easy management, but also for keep some commands work.
 
    e.g. `ndk-gdb`, `ndk-which`... call neighbour files from `\$NDK/SOME_DIR` level.
    When in Redirect Mode, such command is called into the toolchain's one.
    To keep them works same as previous, i have to choose such a dir hierarchy.

- After you upgrade your NDK, you need specify `--force` option to recreate toolchains. 

## About env vars passed to CMD

- `PATH`: will be changed under certain conditions(redirect or hack). 
  When called recursively, it will be restored first

- GYP_DEFINES: will be set to "host_os=<mac|linux>" to specify host_os for gyp.

- BIN AGCC_BIN AGCC_HACK_DIR: will be set for cleaner and as mnemonics.

- Following vars will be set for specified Env Mode, otherwise cleared:
 - CC CXX LINK AR CC_target CXX_target LINK_target AR_target
 - AS RANLIB LD STRIP NM AS_target RANLIB_target LD_target STRIP_target NM_target

## About redirect mode

- Without `-c` nor `-C` option, the specified command will run in a `Redirect Mode`.
- In this mode, the following commands are redirected to the toolchain's one.
    - cc(->gcc) gcc g++ c++ cpp clang clang++ yasm ar ar as ranlib ld strip ...
    - readelf objdump nm c++filt elfedit objcopy strings size ...
    - gdb addr2line gcov gprof gcore dwp ...
    - llvm-as llvm-dis llvm-link FileCheck ...
    - ndk-depends ndk-gdb ndk-which ndk-stack ...

- And as a fallback, `python` `make` `awk`... are moved to ../tools which are appended to $PATH 
    so they are also available if no existing one.

<a name="about-hack-mode"></a>
## About Hack mode
 
It solves some common cross-compile problems on Mac or Linux, most are host-side problem:

- [Mac] **ar**: Some projects does not honor `$AR_target` when make Android-side static
 lib(*.a). Instead, they call Mac-side ar command, so cause link error.
 
    `--hack ar-dual-os` supersede gcc/g++/cc/c++ in $PATH, 
    **It detect input \*.o file format, Mac or Android, then call correct one.**
 
- [Mac] **librt**: Some projects use link option `-lrt` (librt) comes from linux, but
 Mac have no librt, so cause "library not found for -lrt".
 
    `--hack gcc-no-lrt` supersede gcc/g++/cc/c++ in $PATH, remove -lrt option.
 
- [Mac/Linux] **m32**: On 64bit OS, some projects added `-m32` option to gcc to produce
 32bit codes, but some forgot, cause link error of mixing 64 and 32bit codes.
 
    `--hack gcc-m32` supersede gcc/g++/cc/c++ in $PATH, add -m32 option.

- [Linux] **libpthread**: Some projects forgot to add this option so cause linker error:
 `...libpthread.so.0: error adding symbols: DSO missing from command line`.

    `--hack gcc-lpthread` supersede gcc/g++/cc/c++ in $PATH, add -lpthread
    (only when found any -l option which means linking to some lib).

----

# Build NodeJS for Android perfectly 

- **`Perfectly` means do not add any `--without-...` option, nor modifying any source (include build settings) as possible.**
    see [Full Build](#full-build).

- Source of [NodeJS](https://github.com/nodejs/node): 6.3.1-6.5.0

- **To speed up repeating compilation, you'd better add `--ccache` option for `android-gcc-toolchain`**

    First you need install `ccache` by `brew install ccache` on Mac or `sudo apt-get install ccache` on Linux. then:
    
    ```
    export USE_CCACHE=1             #you'd better put this line to your ~/.bash_profile etc.
    export CCACHE_DIR=~/ccache      #you'd better put this line to your ~/.bash_profile etc.
    ccache -M 50G                   #set cache size once is ok
    ```

## Limited build

Drop some features by `--without-snapshot` `--without-inspector` `--without-intl` then build on Mac/Linux.

```
android-gcc-toolchain arm    <<< "./configure --dest-cpu=arm    --dest-os=android --without-snapshot --without-inspector --without-intl && make"
android-gcc-toolchain arm64  <<< "./configure --dest-cpu=arm64  --dest-os=android --without-snapshot --without-inspector --without-intl && make"
android-gcc-toolchain x86    <<< "./configure --dest-cpu=x86    --dest-os=android --without-snapshot --without-inspector --without-intl && make"
android-gcc-toolchain x64    <<< "./configure --dest-cpu=x64    --dest-os=android --without-snapshot --without-inspector --without-intl --openssl-no-asm && make"
android-gcc-toolchain mipsel <<< "./configure --dest-cpu=mipsel --dest-os=android --without-snapshot --without-inspector --without-intl && make"
```
    
For x64: `--openssl-no-asm` needed due to openssl not ready for android-x64.

## Full build

Using `android-gcc-toolchain --hack ... -C`, you can build nodejs **with all features** easily.

see [About hack mode](https://github.com/sjitech/android-gcc-toolchain#about-hack-mode), 
it's not terrible as sound, it just supersede compiler commands in $PATH and add/remove some option.

### Full build on Mac

```
android-gcc-toolchain arm --hack ar-dual-os,gcc-no-lrt,gcc-m32 -C    <<< "./configure --dest-cpu=arm    --dest-os=android && make"
android-gcc-toolchain arm64 --hack ar-dual-os,gcc-no-lrt -C          <<< "./configure --dest-cpu=arm64  --dest-os=android && make"
android-gcc-toolchain x86 --hack ar-dual-os,gcc-no-lrt,gcc-m32 -C    <<< "./configure --dest-cpu=x86    --dest-os=android && make"
android-gcc-toolchain x64 --hack ar-dual-os,gcc-no-lrt -C            <<< "sed -i.bak 's/cross_compiling = target_arch != host_arch/cross_compiling = True/' configure && ./configure --dest-cpu=x64 --dest-os=android --openssl-no-asm && make"
android-gcc-toolchain mipsel --hack ar-dual-os,gcc-no-lrt,gcc-m32 -C <<< "./configure --dest-cpu=mipsel --dest-os=android && make"
```
The sed command is to modify a bug of `configure`. 
 
### Full build on Linux
 
```
android-gcc-toolchain arm --hack gcc-m32,gcc-lpthread -C    <<< "./configure --dest-cpu=arm    --dest-os=android && make"
android-gcc-toolchain arm64 --hack gcc-lpthread -C          <<< "./configure --dest-cpu=arm64  --dest-os=android && make"
android-gcc-toolchain x86 --hack gcc-m32,gcc-lpthread -C    <<< "sed -i.bak 's/cross_compiling = target_arch != host_arch/cross_compiling = True/' configure && ./configure --dest-cpu=x86 --dest-os=android && make"
android-gcc-toolchain x64 --hack gcc-lpthread -C            <<< "sed -i.bak 's/cross_compiling = target_arch != host_arch/cross_compiling = True/' configure && ./configure --dest-cpu=x64 --dest-os=android --openssl-no-asm && make"
android-gcc-toolchain mipsel --hack gcc-m32,gcc-lpthread -C <<< "./configure --dest-cpu=mipsel --dest-os=android && make"
```

For x86:You must install 32bit lib by `sudo apt-get install -y g++-multilib gcc-multilib`,otherwise complained about sys/cdefs.h etc. not found.

For more detail and a prebuilt docker image which contains build result of nodejs, 
see [build-nodejs-for-android-perfectly](https://github.com/sjitech/build-nodejs-for-android-perfectly).

Good luck.
