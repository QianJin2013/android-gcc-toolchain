## android-gcc-toolchain
A single command to enter android cross compile environment without manually create NDK standalone toolchain. 

Tested on Mac OS X 10.11.5 EI Capitan, NDK 12.1.29.  
Should also works on Linux (not tested yet).

![android-gcc](doc/android-gcc.png)
![android-gcc-toolchain](doc/android-gcc-toolchain.png)
![android-gcc-enter](doc/android-gcc-enter.png)


###Features/Ideas

- **Run android gcc related commands easily.**

    ```
    $ android-gcc  a.c
    $ android-gcc++  a.cc
    $ ARCH=arm64 android-gcc  a.c
    ```    
    Alternatively, you can use:
    ```
    $ `android-gcc-toolchain`gcc  a.c
    $ `android-gcc-toolchain arm64`gdb
    ```
    Obviously, options are same as original gcc,g++, yet with the ability to specify toolchain's arch, api level etc.
    
- **Cross-compile gyp/autoconf project easily.**

    - For gyp build, e.g. Node.JS:
    
        ```
        $ android-gcc-toolchain arm64 -c ./configure --dest-cpu=arm64 --dest-os=android --without-snapshot --without-inspector --without-intl 
        $ android-gcc-toolchain arm64 -c make -j4 
        ```
    
        The `-c` means pass env `CC=toolchain's gcc`... to later command. 
        To pass env `CC_target`, use `-C` option.
        
        <sub>
        Besides, normally, once configure ok, $CC is saved to Makefile so can just call `make`, 
        but some sub project may still depends on $CC, so it's safe to wrap the `make` command with this tool.
        </sub>
    
    - For autoconf build, e.g. ffmpeg:
    
        ```
        $ ./configure --enable-cross-compile --cross-prefix=`android-gcc-toolchain arm64` --target-os=linux --arch=arm64 ...
        $ make -j4
        ```

- **Enter a dedicated environment where can run android gcc related commands directly.**

    - `android-gcc-enter` to run cc c++ gdb readelf make python ... without path.

        ```
        $ android-gcc-enter arm64
        ...
        [android-21-arm64] $ which gcc
        /Users/q/Library/Android/sdk/ndk-bundle/std-toolchains/android-21-arm64/bin/gcc
        [android-21-arm64] $ gcc  a.c
        [android-21-arm64] $ android-gcc-leave
        $ 
        ```
    - `android-gcc-toolchain -c` to start a separate bash so can run $CC ...
    
        It does not change $PATH.
        ```
        $ android-gcc-toolchain arm64 -c
        bash-3.2$ echo $CC
        /Users/q/Library/Android/sdk/ndk-bundle/std-toolchains/android-21-arm64/bin/gcc
        bash-3.2$ $CC  a.c
        bash-3.2$ exit
        $ 
        ```

- **Automatically create standalone toolchain the first time.**

    With same command-line options of 
    $NDK/build/tools/make_standalone_toolchain.py (except for --install-dir options of course).    

    ```
    $ android-gcc-toolchain --help
    ...
    $ android-gcc-enter --help
    Options: [[--arch] ARCH］[[--api] APIL] [[--stl] STL] [--force]
     --arch ARCH    Android architecture
       ARCH         {arm(default)|arm64|x86|x86_64|mips|mips64}
     --api APIL     Android API Level
       APIL         {min(default)|max|an integer}
     --stl STL      C++ STL to use
       STL          {gnustl(default)|libc++|stlport}
     --force        delete existing toolchain dir then create
     ...
    ```
    Option keyword itself(`--arch`,`--api`,`--stl`) can be omitted. Order is not cared.
    
    The `android-gcc` and `android-gcc++` is controlled by $`ARCH`, $`APIL`, $`STL`, 
    the toolchain will also be created if not exists. 
    
- **Automatically get minimum/maximum `Android API level` from NDK.**

    ```
    $ android-gcc-toolchain --api max
    $ android-gcc-toolchain 23
    $ android-gcc-enter arm64 23
    ```
    By default, get minimum API level from NDK for specified arch.

- (TODO): Use symbol/hard link to speed up creation of toolchain and save disk space. 
- (TODO): Auto detect NDK, auto download NDK optionally. 
- (TODO): Support bash-completion. 
- (TODO): Support brew install. 
- (TODO): Create a docker container for this tool. 

###Prerequisite

- Install Android NDK (from Android SDK Manager or directly download it) and set NDK env to the dir.

    ```
    export NDK=__the_top_dir_of_installed_NDK__
    ```

###Install

Just download this project to somewhere e.g. `~/Downloads/android-gcc-toolchain`, and can directly call commands inside the project by full path, 
except for `android-gcc-enter`(a shell function come from this project) which need you load my `bashrc` first.
   
Optionally, you can 
- Add the dir to $PATH so you can run `android-gcc-toolchain`, `android-gcc` ... without specify full path.
- Add init script to your `~/.bash_profile` so you can use `android-gcc-enter` commands in bash.

These steps can be done by:
```
source ~/Downloads/android-gcc-toolchain/bashrc --save
```
Tip: you can specify other bash profile such as ~/.profile as last argument.
    
###Uninstall

Manually remove script with mark "_ANDROID_GCC_BASHRC" from your .bash_profile or use following command to remove it.
```
source ~/Downloads/android-gcc-toolchain/bashrc --restore
```
    
###Caveats
- This tool create files in your NDK dir, named `std-toolchains`.

    `$NDK/std-toolchains/android-APIL-ARCH`

    This is not only for easy management, but also for some commands e.g. 
    `ndk-gdb`,`ndk-which`... call neighbour files from this dir level.
    This is only necessary for `android-gcc-enter`'s dedicated environment
    where `ndk-*` be redirected so need keep it works as normal.

- If you upgrade your NDK, you need specify `--force` option to 
`android-gcc-toolchain` or `android-gcc-enter` to recreate toolchains. 
