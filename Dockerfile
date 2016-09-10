#https://github.com/sjitech/ndk-workspace/blob/master/Dockerfile
FROM osexp2000/ndk-workspace

#install android-gcc-toolchain
RUN sudo DEBIAN_FRONTEND=noninteractive apt-get install -y git && \
    git clone https://github.com/sjitech/android-gcc-toolchain -b master --single-branch
ENV PATH=$PATH:/home/devuser/android-gcc-toolchain

#make android-9-arm toolchain
RUN android-gcc-toolchain -

ENTRYPOINT ["android-gcc-toolchain"]
