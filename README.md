# LIR – Learning Information Retrieval

## VERSION

This documentation refers to LIR version 0.3


## DESCRIPTION

LIR – Learning Information Retrieval ("Lehr- und Lernsystem Information Retrieval") is an experimental information retrieval environment to teach and learn information retrieval concepts. It is designed to be highly configurable and parametrisable. Refer to the original project [overview](web/files/betz_-_projekt_lir_-_lehr-_und_lernsystem_information_retrieval.pdf) and [documentation](web/files/betz,_hörnig,_lepsky_-_lehr-_und_lernsystem_information_retrieval.pdf) for more background information.

The original aim (and still current use-case) was to support a practical course on Automatic Indexing at the Institute of Information Science at TH Köln. It should allow students to test their indexing results and experiment with different algorithms for relevance ranking.

The main interface is through a pair of CGI scripts for indexing and querying. This is completed by corresponding console scripts which provide a subset of the functionality.

First, you need to perform automatic indexing on your source documents (e.g., using [Lingo](https://lex-lingo.de)) and obtain frequency counts for the index terms. Then you create index files for LIR with `lir_index.pl` (either CGI or console) and you're ready to query your collection through `lir.pl` (again, either CGI or console).

### Status

This project is more or less unmaintained and no longer actively developed. It's even unfinished in parts, but should be functional on the whole (you can find a working installation in the LINKS section below). YMMV, though.


## INSTALL

### Requirements

LIR depends on some Perl modules and external programs. The following list names the Debian packages which need to be installed:

* libapache2-mod-perl2
* libhtml-template-perl
* libdatetime-perl
* libmldbm-perl
* pdl

### Web server configuration

Sample configuration for Apache (assuming that LIR has been installed in `/usr/local/lir`):

```apache
ScriptAlias /lir/cgi-bin /usr/local/lir/cgi-bin
<Directory /usr/local/lir/cgi-bin>
  Options None
  Require all granted
</Directory>

Alias /lir /usr/local/lir/web
<Directory /usr/local/lir/web>
  Options Indexes MultiViews FollowSymLinks
  Require all granted

  AddType application/xhtml+xml .html
</Directory>

# Restrict access to lir_index.pl
<Files lir_index.pl>
  AuthType Basic
  AuthName "lir_index.pl"
  AuthUserFile /etc/apache2/passwd

  Require valid-user
</Files>
```

The directory `data/lab` has to be writable by the web server process.


## LINKS

Name        | Link
------------|-----------------------------------
Source code | https://github.com/blackwinter/lir
Demo        | https://ixtrieve.fh-koeln.de/lir


## AUTHORS

* [Jens Wille](mailto:jens.wille@gmail.com)


## LICENSE AND COPYRIGHT

Copyright (C) 2004-2020 Jens Wille

LIR is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

LIR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License along with LIR. If not, see http://www.gnu.org/licenses/.
