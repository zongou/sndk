#!/bin/sh
ROOT_DIR=$(dirname $(dirname $(realpath $0)))

if test "${PREFIX+1}"; then
    if test -f ${PREFIX}/etc/profile.d/java.sh; then
        . ${PREFIX}/etc/profile.d/java.sh
    fi
fi

$ROOT_DIR/setup_gradle.sh ${PREFIX}/opt
$ROOT_DIR/setup_sdk.sh ${PREFIX}/opt
