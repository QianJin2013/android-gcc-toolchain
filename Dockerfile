#https://hub.docker.com/r/osexp2000/ndk-workspace/ -> https://github.com/sjitech/ndk-workspace/blob/master/Dockerfile
#FROM osexp2000/ndk-workspace
FROM osexp2000/ubuntu-non-root-with-utils

RUN rm -fr /home/devuser/android-gcc-toolchain
#install android-gcc-toolchain
RUN sudo DEBIAN_FRONTEND=noninteractive apt-get install -y git
RUN git clone https://github.com/sjitech/android-gcc-toolchain
ENV PATH=$PATH:/home/devuser/android-gcc-toolchain

CMD android-gcc-toolchain
