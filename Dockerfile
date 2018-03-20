FROM ubuntu:14.04

MAINTAINER Andrey Zaycev <andrezaycev@gmail.com>

RUN apt-get update && apt-get install build-essential libtool autotools-dev automake pkg-config bsdmainutils curl git g++-mingw-w64-x86-64 wget libboost-all-dev libssl-dev libevent-dev qt5-qmake qt5-default libzmq3-dev libqt5gui5 libqt5core5a libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev protobuf-compiler -y

ENV RACE_ROOT=$(pwd)

# Pick some path to install BDB to, here we create a directory within the race directory
ENV BDB_PREFIX="${RACE_ROOT}/db4"
RUN mkdir -p $BDB_PREFIX

# Fetch the source and verify that it is not tampered with
RUN wget 'http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz'
# -> db-4.8.30.NC.tar.gz: OK
RUN tar -xzvf db-4.8.30.NC.tar.gz

# Build the library and install to our prefix
WORKDIR db-4.8.30.NC/build_unix/
#  Note: Do a static build so that it can be embedded into the executable, instead of having to find a .so at runtime
RUN ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=$BDB_PREFIX
RUN make install


WORKDIR /usr/src
RUN git clone https://github.com/racecrypto/racecoin.git
RUN chmod -R a+rw racecoin

COPY depends /usr/src/racecoin/depends
WORKDIR /usr/src/racecoin/depends

RUN make -j 4 HOST=x86_64-w64-mingw32
WORKDIR /usr/src/racecoin
RUN ./autogen.sh
RUN CONFIG_SITE=$PWD/depends/x86_64-w64-mingw32/share/config.site ./configure LDFLAGS="-L${BDB_PREFIX}/lib/" CPPFLAGS="-I${BDB_PREFIX}/include/" --prefix=/
RUN make -j 4

