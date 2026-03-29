# APEX Telemetry Stack - Production Container
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install in stages to catch errors
RUN apt-get update

# Core build tools
RUN apt-get install -y \
    build-essential \
    git \
    wget \
    curl \
    ca-certificates

# Redis
RUN apt-get install -y redis-server

# LuaJIT and development files
RUN apt-get install -y \
    luajit \
    libluajit-5.1-dev

# Luarocks (might fail, we'll handle it)
RUN apt-get install -y luarocks || echo "Luarocks not available, will install manually"

# Python
RUN apt-get install -y \
    python3 \
    python3-pip

# Cleanup
RUN rm -rf /var/lib/apt/lists/*

# Install Luarocks manually if package failed
RUN if ! command -v luarocks &> /dev/null; then \
        wget https://luarocks.org/releases/luarocks-3.9.2.tar.gz && \
        tar zxpf luarocks-3.9.2.tar.gz && \
        cd luarocks-3.9.2 && \
        ./configure && make && make install && \
        cd .. && rm -rf luarocks-3.9.2*; \
    fi

# Install Zig (use stable 0.13.0)
RUN wget https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz && \
    tar xf zig-linux-x86_64-0.13.0.tar.xz && \
    mv zig-linux-x86_64-0.13.0 /opt/zig && \
    ln -s /opt/zig/zig /usr/local/bin/zig && \
    rm zig-linux-x86_64-0.13.0.tar.xz

# Install Lua dependencies
RUN luarocks install lua-cjson && \
    luarocks install luasocket && \
    luarocks install redis-lua

# Install Python dependencies
RUN pip3 install --no-cache-dir fastf1 pandas matplotlib

# Create app directory
WORKDIR /app

# Copy source code
COPY src/ ./src/
COPY examples/ ./examples/

# Build Zig libraries
WORKDIR /app/src/core
RUN zig build-lib can_decoder.zig -dynamic -O ReleaseFast -femit-bin=libcan_decoder.so && \
    zig build-lib kalman_filter.zig -dynamic -O ReleaseFast -femit-bin=libkalman.so

# Copy libraries
RUN cp *.so ../telemetry/

WORKDIR /app

# Expose ports
EXPOSE 8082 6379

# Copy startup script
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
