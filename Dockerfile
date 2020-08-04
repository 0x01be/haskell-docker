FROM 0x01be/alpine:edge as builder

ENV GHC_VERSION 8.10.1

RUN apk add --no-cache --virtual haskell-build-dependencies \
    git \
    build-base \
    wget \
    zlib-dev \
    unzip \
    autoconf \
    ncurses-dev \
    python3 \
    gmp-dev \
    binutils-gold

ADD https://downloads.haskell.org/~ghc/$GHC_VERSION/ghc-$GHC_VERSION-x86_64-alpine3.10-linux-integer-simple.tar.xz /
RUN tar xf ghc-$GHC_VERSION-x86_64-alpine3.10-linux-integer-simple.tar.xz
WORKDIR /ghc-$GHC_VERSION-x86_64-unknown-linux

#RUN git clone --recursive --branch ghc-$GHC_VERSION-release https://gitlab.haskell.org/ghc/ghc.git
#WORKDIR /ghc
#RUN ./boot # if built from git

RUN ./configure --prefix=/opt/ghc/
RUN make install

ENV PATH $PATH:/opt/ghc/bin/

RUN git clone --depth 1 https://github.com/haskell/cabal.git /cabal

WORKDIR /cabal

RUN ./bootstrap/bootstrap.py -d ./bootstrap/linux-$GHC_VERSION.json -w /opt/ghc/bin/ghc
RUN mkdir -p /opt/cabal/bin/
RUN cp /cabal/_build/bin/cabal /opt/cabal/bin/

ENV PATH $PATH:/opt/cabal/bin/

RUN cabal update

RUN git clone --depth 1 https://github.com/commercialhaskell/stack /stack

WORKDIR /stack

RUN cabal install
RUN mkdir -p /opt/stack/bin/
RUN cp -L /root/.cabal/bin/stack /opt/stack/bin/

ENV PATH $PATH:/opt/stack/bin/

FROM 0x01be/alpine:edge

COPY --from=builder /opt/ghc/ /opt/ghc/
COPY --from=builder /opt/cabal/ /opt/cabal/
COPY --from=builder /opt/stack/ /opt/stack/

RUN apk add --no-cache --virtual haskell-runtime-dependencies \
    ncurses-dev \
    gmp-dev \
    build-base \
    binutils-gold

RUN ln -s /usr/lib/libncursesw.so.6 /usr/lib/libtinfo.so.6
 
ENV PATH $PATH:/opt/ghc/bin/:/opt/cabal/bin/:/opt/stack/bin/

