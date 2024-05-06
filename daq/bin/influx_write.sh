#! /usr/bin/env bash

if [ "$#" -lt 1 ]; then
    echo "usage: $0 [data]"
    exit 1
fi

TOKEN="FNDVnu7yKPbw6zEZ744Unkm3___bEhEnrEC95OsDckhtKZVdb6MjivjZxIU-hTlTEox6PPXMU2PQ0bGdpTRrag=="
DATA="$@"

curl --request POST \
     "http://eicdesk04.bo.infn.it:8086/api/v2/write?org=dRICH&bucket=drich&precision=ns" \
     --header "Authorization: Token ${TOKEN}" \
     --header "Content-Type: text/plain; charset=utf-8" \
     --header "Accept: application/json" \
     --data-binary "$DATA" &> /dev/null

exit $?
