FROM alpine:edge

RUN apk --update add erlang erlang-sasl erlang-crypto erlang-syntax-tools && rm -rf /var/cache/apk/*

RUN mkdir -p /app
ARG VERSION=0.0.1
COPY rel/democracy/releases/${VERSION}/democracy.tar.gz /app/democracy.tar.gz
COPY scripts/wait-for-postgres.sh app/wait-for-postgres.sh
WORKDIR /app
RUN tar xvzf democracy.tar.gz
ENV PORT 80
CMD ["/app/bin/democracy", "foreground"]
