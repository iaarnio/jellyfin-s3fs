FROM ghcr.io/linuxserver/baseimage-ubuntu:focal

# set version label
ARG BUILD_DATE
ARG VERSION
ARG JELLYFIN_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thelamer"

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"
ENV NVIDIA_DRIVER_CAPABILITIES="compute,video,utility"

######################
# S3FS
######################
RUN \
  export DEBIAN_FRONTEND=noninteractive && \
  echo "/usr/local/lib" > /etc/ld.so.conf.d/libc.conf && \
  export MAKEFLAGS="-j$[$(nproc) + 1]" && \
  export SRC=/usr/local && \
  export PKG_CONFIG_PATH=${SRC}/lib/pkgconfig && \
  apt-get update && \
  apt-get -y install fuse libfuse2 libcurl3-gnutls libxml2 libssl1.1 wget && \
  BUILD_REQS='automake autotools-dev curl g++ git libcurl4-gnutls-dev libfuse-dev libssl-dev libxml2-dev make pkg-config' && \
  apt-get -y install $BUILD_REQS && \
  DIR=$(mktemp -d) && \
  cd ${DIR} \
  wget https://github.com/s3fs-fuse/s3fs-fuse/archive/refs/tags/v1.91.tar.gz -O s3fs.tar.gz && \
  tar -xzf s3fs.tar.gz -C . --strip-components=1 && \
  ./autogen.sh && \
  ./configure && \
  make && \
  make install && \
  rm -rf ${DIR} && \
  ldconfig && \
  /usr/local/bin/s3fs --version && \
  apt-get -y remove $BUILD_REQS && apt-get -y autoremove && rm -rf /var/lib/apt/lists/*

######################
# JELLYFIN
######################
RUN \
  echo "**** install packages ****" && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    gnupg && \
  echo "**** install jellyfin *****" && \
  curl -s https://repo.jellyfin.org/ubuntu/jellyfin_team.gpg.key | apt-key add - && \
  echo 'deb [arch=amd64] https://repo.jellyfin.org/ubuntu focal main' > /etc/apt/sources.list.d/jellyfin.list && \
  if [ -z ${JELLYFIN_RELEASE+x} ]; then \
    JELLYFIN="jellyfin-server"; \
  else \
    JELLYFIN="jellyfin-server=${JELLYFIN_RELEASE}"; \
  fi && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    at \
    ${JELLYFIN} \
    jellyfin-ffmpeg5 \
    jellyfin-web \
    libfontconfig1 \
    libfreetype6 \
    libssl1.1 \
    mesa-va-drivers && \
  echo "**** cleanup ****" && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

# add local files
COPY root/ /

# ports and volumes
EXPOSE 8096 8920
VOLUME /config

ADD entry.sh /

ENTRYPOINT ["/entry.sh"]
