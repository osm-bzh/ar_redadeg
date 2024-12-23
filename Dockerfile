FROM ubuntu:20.04
RUN apt update && apt install git \
    python3 \
    pip -y


