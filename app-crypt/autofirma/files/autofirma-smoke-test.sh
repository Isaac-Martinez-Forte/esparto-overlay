#!/bin/bash
# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
set -euo pipefail
jar_path=$1
test_dir=$(mktemp -d "${2%/}.XXXXXX")
trap 'rm -rf -- "${test_dir}"' EXIT
mkdir -p "${test_dir}/home"
java_command=( "${JAVA_HOME:?}/bin/java"
    "-Duser.home=${test_dir}/home" "-Djava.util.prefs.userRoot=${test_dir}/prefs"
    -Djava.awt.headless=true -cp "${jar_path}"
    es.gob.afirma.standalone.CommandLineLauncher )
"${java_command[@]}" -help > "${test_dir}/help.txt" 2>&1
grep -q 'listaliases' "${test_dir}/help.txt"
"${JAVA_HOME}/bin/keytool" -genkeypair -alias esparto-test -keyalg RSA \
    -keysize 2048 -validity 1 -dname 'CN=Esparto packaging test' \
    -storetype PKCS12 -keystore "${test_dir}/test.p12" \
    -storepass changeit -keypass changeit > "${test_dir}/keytool.log" 2>&1
printf '%s\n' 'Esparto AutoFirma source build test.' > "${test_dir}/input.txt"
"${java_command[@]}" sign -i "${test_dir}/input.txt" \
    -o "${test_dir}/signature.csig" -format cades -algorithm sha256 \
    -store "pkcs12:${test_dir}/test.p12" -password changeit -alias esparto-test \
    > "${test_dir}/sign.log" 2>&1
openssl cms -verify -binary -inform DER -in "${test_dir}/signature.csig" \
    -content "${test_dir}/input.txt" -noverify -out "${test_dir}/verified.txt"
cmp "${test_dir}/input.txt" "${test_dir}/verified.txt"
