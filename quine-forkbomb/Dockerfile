FROM rust:1.81

WORKDIR /app

COPY ./entrypoint.sh /entrypoint.sh

RUN git clone https://github.com/pelmers/quine.git

WORKDIR /app/quine

ENTRYPOINT ["/entrypoint.sh"]
