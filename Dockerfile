FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    build-essential \
    autoconf \
    bison \
    libncurses-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY . .

RUN ./configure && make -j$(nproc) CFLAGS="-DBASH_ORACLE -O2" && strip bash-oracle

CMD ["cat", "bash-oracle"]
