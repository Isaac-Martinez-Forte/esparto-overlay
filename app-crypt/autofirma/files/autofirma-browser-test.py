#!/usr/bin/env python3
# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
"""Exercise browser bootstrap using real NSS databases in a temporary home."""
import hashlib
import os
from pathlib import Path
import runpy
import subprocess
import tempfile
import unittest
from unittest.mock import patch

MODULE = runpy.run_path(str(Path(__file__).with_name('autofirma-browser-setup')))
setup = MODULE['setup']
command = MODULE['command']


class BrowserSetup(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temporary = tempfile.TemporaryDirectory(prefix='autofirma-browser-test-')
        cls.home = Path(cls.temporary.name) / 'home with spaces'
        cls.home.mkdir()
        cls.environment = patch.dict(os.environ, {
            'HOME': str(cls.home), 'XDG_CONFIG_HOME': str(cls.home / 'xdg config'),
            'XDG_DATA_HOME': str(cls.home / 'xdg data')})
        cls.environment.start()
        cls.previous_umask = os.umask(0o077)
        cls.legacy = cls.home / '.mozilla/firefox'
        cls.modern = cls.home / 'xdg config/mozilla/firefox'
        cls.absolute = cls.home / 'absolute profile with spaces'
        for root in (cls.legacy, cls.modern):
            root.mkdir(parents=True)
            (root / 'profiles.ini').write_text('[Profile0]\nIsRelative=1\nPath=relative profile\n'
                f'[Profile1]\nPath={cls.absolute}\nIsRelative=0\n')
        cls.databases = [cls.legacy / 'relative profile', cls.modern / 'relative profile',
                         cls.absolute, cls.home / '.pki/nssdb', cls.home / 'xdg data/pki/nssdb']
        for database in cls.databases:
            database.mkdir(parents=True, exist_ok=True)
            command('certutil', '-N', '-d', f'sql:{database}', '--empty-password')
        assert setup(cls.home) == 0
        cls.identity = cls.home / '.afirma/Autofirma/autofirma.pfx'
        cls.identity_hash = hashlib.sha256(cls.identity.read_bytes()).hexdigest()

    @classmethod
    def tearDownClass(cls):
        cls.environment.stop()
        os.umask(cls.previous_umask)
        cls.temporary.cleanup()

    def test_browser_trust_and_loopback_certificate(self):
        for database in self.databases:
            result = command('certutil', '-L', '-d', f'sql:{database}').stdout.decode()
            self.assertIn('AutoFirma ROOT (Esparto ', result)
            self.assertIn('C,,', result)
        leaf = command('openssl', 'pkcs12', '-in', str(self.identity), '-passin',
                       'pass:654321', '-clcerts', '-nokeys').stdout
        leaf_path = self.home / 'leaf.pem'
        leaf_path.write_bytes(leaf)
        ca = self.identity.parent / 'Autofirma_ROOT.cer'
        for hostname in ('localhost', '127.0.0.1', '::1'):
            option = '-verify_ip' if ':' in hostname or hostname[0].isdigit() else '-verify_hostname'
            command('openssl', 'verify', '-CAfile', str(ca), option, hostname, str(leaf_path))
        database = self.databases[0]
        command('certutil', '-A', '-d', f'sql:{database}', '-n', 'test-loopback-server',
                '-t', ',,', '-i', str(leaf_path))
        command('certutil', '-V', '-d', f'sql:{database}', '-n', 'test-loopback-server', '-u', 'V')
        result = command('keytool', '-list', '-storetype', 'PKCS12', '-keystore',
                         str(self.identity), '-storepass', '654321').stdout
        self.assertIn(b'socketautofirma', result)
        self.assertEqual(self.identity.stat().st_mode & 0o777, 0o600)

    def test_relaunch_preserves_identity_and_covers_new_profile(self):
        self.assertEqual(setup(self.home), 0)
        new_profile = self.home / '.config/mozilla/firefox/new profile'
        new_profile.mkdir(parents=True)
        (new_profile.parent / 'profiles.ini').write_text('[Profile0]\nPath=new profile\nIsRelative=1\n')
        command('certutil', '-N', '-d', f'sql:{new_profile}', '--empty-password')
        self.assertEqual(setup(self.home), 0)
        self.assertIn(b'AutoFirma ROOT (Esparto ',
                      command('certutil', '-L', '-d', f'sql:{new_profile}').stdout)
        self.assertEqual(hashlib.sha256(self.identity.read_bytes()).hexdigest(), self.identity_hash)

    def test_existing_aur_identity_is_reused(self):
        ca = self.identity.parent / 'Autofirma_ROOT.cer'
        ca.rename(ca.with_name('AutoFirma_ROOT.cer'))
        self.assertEqual(setup(self.home), 0)
        self.assertTrue(ca.exists())
        self.assertEqual(hashlib.sha256(self.identity.read_bytes()).hexdigest(), self.identity_hash)

    def test_existing_aur_browser_trust_is_not_reimported(self):
        database = self.home / 'legacy CA profile'
        database.mkdir()
        command('certutil', '-N', '-d', f'sql:{database}', '--empty-password')
        command('certutil', '-A', '-d', f'sql:{database}', '-n', 'AutoFirma ROOT',
                '-t', 'C,,', '-i', str(self.identity.parent / 'Autofirma_ROOT.cer'))
        with (self.legacy / 'profiles.ini').open('a') as ini:
            ini.write(f'[Profile2]\nIsRelative=0\nPath={database}\n')
        imports = []

        def observe(*args, **kwargs):
            if args[0] == 'certutil' and '-A' in args and f'sql:{database}' in args:
                imports.append(args)
            return command(*args, **kwargs)

        with patch.dict(setup.__globals__, {'command': observe}):
            self.assertEqual(setup(self.home), 0)
        self.assertEqual(imports, [])
        self.assertIn(b'AutoFirma ROOT', command('certutil', '-L', '-d', f'sql:{database}').stdout)

    def test_invalid_existing_identity_is_not_overwritten(self):
        home = self.home / 'broken identity'
        directory = home / '.afirma/Autofirma'
        directory.mkdir(parents=True)
        pfx = directory / 'autofirma.pfx'
        pfx.write_bytes(b'invalid existing keystore')
        with self.assertRaises(subprocess.CalledProcessError):
            setup(home)
        self.assertEqual(pfx.read_bytes(), b'invalid existing keystore')


if __name__ == '__main__':
    unittest.main()
