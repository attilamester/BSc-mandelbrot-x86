FROM ubuntu:24.04 AS build

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
    nasm \
    gcc-multilib \
    libc6-dev-i386 \
    pkg-config \
    libsdl2-dev:i386 \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY src ./src
COPY build.sh ./

RUN chmod +x build.sh && ./build.sh


FROM ubuntu:24.04 AS runtime

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
    libsdl2-2.0-0:i386 \
    libx11-6:i386 \
    libxext6:i386 \
    libxrandr2:i386 \
    libxrender1:i386 \
    libxi6:i386 \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /app/bin/mandelbrot ./mandelbrot
CMD ["/bin/bash", "-lc", "mkdir -p /tmp/runtime && chmod 700 /tmp/runtime && export XDG_RUNTIME_DIR=/tmp/runtime && exec /app/mandelbrot"]