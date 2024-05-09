#!/bin/bash

set -x

while true; do

USERID=$(uuidgen)

curl -H "X-BokBank-User-ID: ${USERID}" http://localhost:2265/accounts

sleep $((RANDOM % 5))
curl -H "X-BokBank-User-ID: ${USERID}" http://localhost:2265/accounts
sleep $((RANDOM % 5))
curl -H "X-BokBank-User-ID: ${USERID}" http://localhost:2265/accounts
sleep $((RANDOM % 5))
curl -H "X-BokBank-User-ID: ${USERID}" http://localhost:2265/accounts

curl -H "X-BokBank-User-ID: ${USERID}" http://localhost:2265/merchants

sleep $((RANDOM % 10))

curl -H "X-BokBank-User-ID: ${USERID}" http://localhost:2265/accounts/xxx/transactions

sleep $((RANDOM % 10))

done