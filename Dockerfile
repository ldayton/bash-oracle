FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y gcc make && rm -rf /var/lib/apt/lists/*
WORKDIR /src
COPY . .
RUN touch configure && ./configure && make -j$(nproc) CFLAGS="-DBASH_ORACLE -O2" && strip bash-oracle
