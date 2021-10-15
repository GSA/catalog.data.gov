### Commented entries have reasonable defaults.
### Uncomment to edit them.
# Source: <source package name; defaults to package name>
Section: misc
Priority: optional
# Homepage: <enter URL here; no default>
Standards-Version: 3.9.2

Package: cflinuxfs3-fhs-fixup
# Version: <enter version here; defaults to 1.0>
Maintainer: Bret Mogilefsky <bret.mogilefsky@gsa.gov>
# Pre-Depends: <comma-separated list of packages>
# Depends: <comma-separated list of packages>
# Recommends: <comma-separated list of packages>
# Suggests: <comma-separated list of packages>
# Provides: <comma-separated list of packages>
# Replaces: <comma-separated list of packages>
# Architecture: all
# Multi-Arch: <one of: foreign|same|allowed>
# Copyright: <copyright file; defaults to GPL2>
# Changelog: <changelog file; defaults to a generic changelog>
# Readme: <README.Debian file; defaults to a generic one>
# Extra-Files: <comma-separated list of additional files for the doc directory>
# Links: <pair of space-separated paths; First is path symlink points at, second is filename of link>
# Files: <pair of space-separated paths; First is file to include, second is destination>
#  <more pairs, if there's more than one file to include. Notice the starting space>
File: postinst
 #!/bin/sh -e
 .
 set -e
 .
 cat << EOF | xargs mkdir -p
 /usr/share/man
 /usr/share/man/man1
 /usr/share/man/zh_CN
 /usr/share/man/zh_CN/man1
 /usr/share/man/zh_CN/man5
 /usr/share/man/zh_CN/man8
 /usr/share/man/it
 /usr/share/man/it/man1
 /usr/share/man/it/man5
 /usr/share/man/it/man8
 /usr/share/man/fi
 /usr/share/man/fi/man1
 /usr/share/man/zh_TW
 /usr/share/man/zh_TW/man1
 /usr/share/man/sv
 /usr/share/man/sv/man1
 /usr/share/man/sv/man5
 /usr/share/man/sv/man8
 /usr/share/man/ru
 /usr/share/man/ru/man1
 /usr/share/man/ru/man5
 /usr/share/man/ru/man8
 /usr/share/man/pl
 /usr/share/man/pl/man1
 /usr/share/man/pl/man5
 /usr/share/man/pl/man8
 /usr/share/man/ja
 /usr/share/man/ja/man1
 /usr/share/man/ja/man5
 /usr/share/man/ja/man8
 /usr/share/man/pt
 /usr/share/man/pt/man5
 /usr/share/man/pt/man8
 /usr/share/man/man5
 /usr/share/man/nl
 /usr/share/man/nl/man5
 /usr/share/man/nl/man8
 /usr/share/man/man3
 /usr/share/man/cs
 /usr/share/man/cs/man1
 /usr/share/man/cs/man5
 /usr/share/man/cs/man8
 /usr/share/man/hu
 /usr/share/man/hu/man1
 /usr/share/man/ko
 /usr/share/man/ko/man1
 /usr/share/man/da
 /usr/share/man/da/man1
 /usr/share/man/da/man5
 /usr/share/man/da/man8
 /usr/share/man/tr
 /usr/share/man/tr/man1
 /usr/share/man/fr
 /usr/share/man/fr/man1
 /usr/share/man/fr/man5
 /usr/share/man/fr/man8
 /usr/share/man/man7
 /usr/share/man/de
 /usr/share/man/de/man1
 /usr/share/man/de/man5
 /usr/share/man/de/man8
 /usr/share/man/man8
 /usr/share/man/id
 /usr/share/man/id/man1
 /usr/share/man/es
 /usr/share/man/es/man1
 /usr/share/man/es/man5
 /usr/share/man/es/man8
 /usr/share/lintian/overrides
 EOF
Description: Restore expected directories in cflinuxfs3 
 In the creation of cflinuxfs3, certain directories expected by other packages get removed.
 See https://github.com/cloudfoundry/cflinuxfs3/blob/7ee887669476246b7eb05a3ee5b5b5eeba163c22/Dockerfile#L19-L22
 .
 This can prevent package configuration from succeeding. For example, default-jre-headless tries to put a file in /usr/share/man/man1, and fails.
 .
 Installing this package just ensures those directories are present.