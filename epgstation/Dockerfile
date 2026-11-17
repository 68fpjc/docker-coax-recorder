FROM l3tnun/epgstation:latest

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends ffmpeg libavcodec-extra \
    && rm -rf /var/lib/apt/lists/*
