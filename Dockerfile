FROM swift:5.1-bionic as builder

RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true && apt-get -q update && \
    apt-get -q install -y \
    libssl-dev \
    zlib1g-dev \
    libpng-dev libjpeg-dev \
    curl \
    && rm -r /var/lib/apt/lists/*

RUN curl -sfLO https://www.imagemagick.org/download/releases/ImageMagick-6.9.10-82.tar.gz && \
    tar -xzf ImageMagick-6.9.10-82.tar.gz && \
    cd ImageMagick-6.9.10-82 && \
    ./configure --without-magick-plus-plus --without-perl --prefix /usr/local && \
    make && \
    make install && \
    cd .. && \
    rm -rf ImageMagick-6.9.10-82
RUN mkdir -p /usr/magick && cp -R /usr/local/lib/*.so* /usr/magick

WORKDIR /app
COPY . .
RUN mkdir -p /build/lib && cp -R /usr/lib/swift/linux/*.so* /build/lib
RUN swift build -c release \
    -Xswiftc -I/usr/local/include/ImageMagick-6 \
    -Xlinker -L/usr/local/lib \
    -Xlinker -lMagickWand-6.Q16 \
    -Xlinker -lMagickCore-6.Q16 \
    -Xcc -DMAGICKCORE_HDRI_ENABLE=0 \
    -Xcc -DMAGICKCORE_QUANTUM_DEPTH=16 && \
    mv `swift build -c release --show-bin-path` /build/bin

# Production image
FROM ubuntu:18.04

# DEBIAN_FRONTEND=noninteractive for automatic UTC configuration in tzdata
RUN apt-get -qq update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  libatomic1 libicu60 libxml2 libcurl4 libz-dev libbsd0 tzdata \
  libgomp1 libpng-dev libjpeg-dev \
  && rm -r /var/lib/apt/lists/*
  
WORKDIR /app
COPY --from=builder /build/bin/Run .
COPY --from=builder /build/lib/* /usr/lib/
COPY --from=builder /usr/magick/* /usr/local/lib/
RUN ldconfig /usr/local/lib/

ENTRYPOINT ./Run serve --env production --hostname 0.0.0.0 --port 8082
