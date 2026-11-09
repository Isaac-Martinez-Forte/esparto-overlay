#!/bin/bash
# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
# Real NSS/PKCS#12 integration tests in a disposable home; no Python required.
set -euo pipefail
source "${BASH_SOURCE[0]%/*}/autofirma-browser-setup"
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/autofirma-browser-test.XXXXXX")
trap 'rm -rf -- "${test_dir}"' EXIT
umask 077
test_home="${test_dir}/home with spaces"
test_config="${test_home}/xdg config"
test_data="${test_home}/xdg data"
legacy="${test_home}/.mozilla/firefox"
modern="${test_config}/mozilla/firefox"
absolute="${test_home}/absolute profile with spaces"
mkdir -p "${legacy}" "${modern}"
for root in "${legacy}" "${modern}"; do
	printf '\357\273\277[General]\r\nStartWithLastProfile=1\r\n[InstallExample]\r\nDefault=relative profile\r\n[Profile0]\r\nIsRelative=1\r\nPath=relative profile\r\n[Profile1]\r\nPath=%s\r\nIsRelative=0\r\n' \
		"${absolute}" > "${root}/profiles.ini"
done
databases=( "${legacy}/relative profile" "${modern}/relative profile" "${absolute}"
	"${test_home}/.pki/nssdb" "${test_data}/pki/nssdb" )
for database in "${databases[@]}"; do
	mkdir -p "${database}"
	certutil -N -d "sql:${database}" --empty-password
done
autofirma_browser_setup "${test_home}" "${test_config}" "${test_data}"
identity="${test_home}/.afirma/Autofirma/autofirma.pfx"
ca="${identity%/*}/Autofirma_ROOT.cer"
identity_hash=$(sha256sum "${identity}")
for database in "${databases[@]}"; do
	certutil -L -d "sql:${database}" > "${test_dir}/trust.txt"
	grep -Fq 'AutoFirma ROOT (Esparto ' "${test_dir}/trust.txt"
	grep -Fq 'C,,' "${test_dir}/trust.txt"
done
openssl pkcs12 -in "${identity}" -passin pass:654321 -clcerts -nokeys > "${test_dir}/leaf.pem"
openssl verify -CAfile "${ca}" -verify_hostname localhost "${test_dir}/leaf.pem"
openssl verify -CAfile "${ca}" -verify_ip 127.0.0.1 "${test_dir}/leaf.pem"
openssl verify -CAfile "${ca}" -verify_ip ::1 "${test_dir}/leaf.pem"
certutil -A -d "sql:${databases[0]}" -n test-loopback-server -t ',,' -i "${test_dir}/leaf.pem"
certutil -V -d "sql:${databases[0]}" -n test-loopback-server -u V
keytool -list -storetype PKCS12 -keystore "${identity}" -storepass 654321 > "${test_dir}/keytool.txt"
grep -Fq socketautofirma "${test_dir}/keytool.txt"
[[ $(stat -c %a "${identity}") == 600 ]]
printf '%s\n' 'PASS: browser trust, TLS loopback names and Java PKCS#12 compatibility'

autofirma_browser_setup "${test_home}" "${test_config}" "${test_data}"
new_profile="${test_home}/.config/mozilla/firefox/new profile"
mkdir -p "${new_profile}"
printf '[Profile0]\nPath=new profile\nIsRelative=1\n' > "${new_profile%/*}/profiles.ini"
certutil -N -d "sql:${new_profile}" --empty-password
autofirma_browser_setup "${test_home}" "${test_config}" "${test_data}"
certutil -L -d "sql:${new_profile}" > "${test_dir}/trust.txt"
grep -Fq 'AutoFirma ROOT (Esparto ' "${test_dir}/trust.txt"
[[ $(sha256sum "${identity}") == "${identity_hash}" ]]
printf '%s\n' 'PASS: relaunch preserves identity and configures new profiles'

mv "${ca}" "${identity%/*}/AutoFirma_ROOT.cer"
autofirma_browser_setup "${test_home}" "${test_config}" "${test_data}"
[[ -f ${ca} && $(sha256sum "${identity}") == "${identity_hash}" ]]
printf '%s\n' 'PASS: existing AUR/upstream identity is reused'

legacy_db="${test_home}/legacy CA profile"
mkdir -p "${legacy_db}"
certutil -N -d "sql:${legacy_db}" --empty-password
certutil -A -d "sql:${legacy_db}" -n 'AutoFirma ROOT' -t C,, -i "${ca}"
printf '[Profile2]\nIsRelative=0\nPath=%s\n' "${legacy_db}" >> "${legacy}/profiles.ini"
database_hash=$(sha256sum "${legacy_db}/cert9.db")
autofirma_browser_setup "${test_home}" "${test_config}" "${test_data}"
[[ $(sha256sum "${legacy_db}/cert9.db") == "${database_hash}" ]]
printf '%s\n' 'PASS: existing AUR browser trust is not re-imported'

broken_home="${test_home}/broken identity"
mkdir -p "${broken_home}/.afirma/Autofirma"
printf '%s' 'invalid existing keystore' > "${broken_home}/.afirma/Autofirma/autofirma.pfx"
if autofirma_browser_setup "${broken_home}" "${test_config}" "${test_data}"; then
	printf '%s\n' 'FAIL: corrupt existing keystore was accepted' >&2
	exit 1
fi
[[ $(cat "${broken_home}/.afirma/Autofirma/autofirma.pfx") == 'invalid existing keystore' ]]
printf '%s\n' 'PASS: corrupt existing identity is preserved'
