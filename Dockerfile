FROM msaraiva/erlang:18.1

RUN apk --update add erlang-crypto erlang-sasl && rm -rf /var/cache/apk/*

ARG VERSION=0.0.1
ENV APP_NAME democracy
ENV MIX_ENV=prod
ENV PORT 80

RUN mkdir -p /$APP_NAME
ADD rel/$APP_NAME/bin /$APP_NAME/bin
ADD rel/$APP_NAME/lib /$APP_NAME/lib
ADD rel/$APP_NAME/releases/start_erl.data                 /$APP_NAME/releases/start_erl.data
ADD rel/$APP_NAME/releases/$VERSION/$APP_NAME.sh      /$APP_NAME/releases/$VERSION/$APP_NAME.sh
ADD rel/$APP_NAME/releases/$VERSION/$APP_NAME.boot    /$APP_NAME/releases/$VERSION/$APP_NAME.boot
ADD rel/$APP_NAME/releases/$VERSION/$APP_NAME.rel     /$APP_NAME/releases/$VERSION/$APP_NAME.rel
ADD rel/$APP_NAME/releases/$VERSION/$APP_NAME.script  /$APP_NAME/releases/$VERSION/$APP_NAME.script
ADD rel/$APP_NAME/releases/$VERSION/start.boot        /$APP_NAME/releases/$VERSION/start.boot
ADD rel/$APP_NAME/releases/$VERSION/sys.config        /$APP_NAME/releases/$VERSION/sys.config
ADD rel/$APP_NAME/releases/$VERSION/vm.args           /$APP_NAME/releases/$VERSION/vm.args

EXPOSE $PORT

CMD trap exit TERM; /$APP_NAME/bin/$APP_NAME foreground & wait