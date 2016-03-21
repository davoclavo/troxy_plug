#!/bin/sh

command -v openssl >/dev/null 2>&1 || \
    ( echo >&2 "openssl required but not installed"; exit 1 )

PRIV_DIR="priv/erl_cowboy"
PREFIX="dummy"
PASS=""

mkdir -p $PRIV_DIR

openssl req \
        -new \
        -newkey rsa:1024 \
        -days 365 \
        -nodes \
        -x509 \
        -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com" \
        -keyout $PRIV_DIR/$PREFIX.key \
        -out $PRIV_DIR/$PREFIX.crt


echo "Update the erl_cowboy section of the sys.config file (it is commented by deafault):\n"\
     "[{erl_cowboy, [
               {port, 8080},
               {tls_enabled, true},
               {tls_opts, [{certfile, \"${PREFIX}.crt\"},
                           {keyfile, \"${PREFIX}.key\"},
                           {password, \"${PASS}\"}]}
              ]}]."
