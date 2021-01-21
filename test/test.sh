#!/bin/bash
# This script builds and starts hpws echo server and then run autobahn websocket test suite.
# This script must be run from hpws repo root. eg: ./test/test.sh
# Requires docker.

make hpws test || { echo "Build failed. Make sure you are running this script from hpws repo root."; exit 1; }

# Generate tls key files.
if [ -f key.pem -a -f cert.pem ]; then
    :
else
    rm key.pem cert.pem > /dev/null 2>&1
    openssl req -newkey rsa:2048 -new -nodes -x509 -days 3650 -keyout key.pem -out cert.pem -subj "/C=AU/ST=ACT/L=AU/O=hpws/CN=hpws"
fi

# Start hpws echo server.
./echo-server &> echo-server.log &
svrpid=$!

# Pull latest autobahn docker image if not exists.
docker image inspect crossbario/autobahn-testsuite >/dev/null 2>&1 || \
    docker pull crossbario/autobahn-testsuite || \
    { echo "Check whether docker is installed properly."; exit 1; }

# Run the test suite.
docker run -it --rm -v "${PWD}/test/autobahn:/autobahn" --name hpws-autobahn-tester \
    crossbario/autobahn-testsuite /usr/local/bin/wstest --mode fuzzingclient --spec /autobahn/config.json

# Kill hpws echo server.
kill $svrpid
wait 2>/dev/null

echo "hpws server execution logged to ${PWD}/echo-server.log"
echo "test report generated at ${PWD}/test/autobahn/reports/index.html"
