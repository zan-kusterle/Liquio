FROM bitwalker/alpine-erlang:4.0

EXPOSE 80
ENV PORT=80

ENV MIX_ENV=prod
ARG VERSION=0.0.1
ADD rel/democracy/releases/${VERSION}/democracy.tar.gz ./
RUN tar -xzvf democracy.tar.gz

USER default

CMD ./bin/democracy foreground