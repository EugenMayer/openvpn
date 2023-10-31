# openvpn Cookbook CHANGELOG

This file is used to list changes made in each version of the openvpn cookbook.

## 8.0.0

Forked from sous - BREAKING CHANGES

- migrated to easy-rsa 3.0
- entirely and soley use easy-rsa and stay easy-rsa compliant
- support for debian 12 bookworm
- fixed several quirks with easy-rsa
- only support easy-rsa 3.0 distros: debian 10+ and ubuntu 20+
- removed user management
- removed support for freebsd, arch, macos, windows, rhel and suse

BREAKING CHANGES !! BREAKING CHANGES
This release has a gazzilion breaking changes and you should not upgrade from sous directly.
Only upgrade if you are willing to nuke your pki and start the pki all over again.
