#!/usr/bin/perl

# Copyright 2007, 2008 Kevin Ryde

# This file is part of Gtk2-Ex-TiedListColumn.
#
# Gtk2-Ex-TiedListColumn is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 2, or (at your option) any
# later version.
#
# Gtk2-Ex-TiedListColumn is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-TiedListColumn.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile
  (NAME         => 'Gtk2-Ex-TiedListColumn',
   ABSTRACT     => 'Tie an array to a Gtk2-Perl TreeModel.',
   VERSION_FROM => 'lib/Gtk2/Ex/TiedListColumn.pm',
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,

   PREREQ_PM    => {
                    # think any version might be
                    'Gtk2' => 0,

                    # actually Gtk2 requires perl 5.8, which these builtin
                    # already
                    'List::Util' => 0,
                    'Test::More' => 0,
                   },

   clean        => { FILES => "TiedListColumn.html" },

   EXTRA_META => <<'HERE',
no_index:
    directory:
        - devel
resources:
    homepage: http://www.geocities.com/user42_kevin/gtk2-ex-tiedlistcolumn/index.html
HERE
  );

sub MY::postamble {
  return <<'MAKE_FRAG';

LINT_FILES = $(TO_INST_PM) t/*.t examples/*.pl devel/*.pl
lint:
	perl -MO=Lint $(LINT_FILES)
	podchecker    $(LINT_FILES)
pc:
	perlcritic $(LINT_FILES)

myman:
	mv MANIFEST MANIFEST.old
	touch SIGNATURE
	(make manifest 2>&1; diff -u MANIFEST.old MANIFEST) |less

TiedListColumn.html: lib/Gtk2/Ex/TiedListColumn.pm Makefile
	-perl -MPod::Simple::HTML -e Pod::Simple::HTML::go \
	  lib/Gtk2/Ex/TiedListColumn.pm \
	| sed 's!http://search.cpan.org/perldoc?Glib%3A%3A\([^"]*\)!http://gtk2-perl.sourceforge.net/doc/pod/Glib/\1.html!' \
	| sed 's!http://search.cpan.org/perldoc?Gtk2%3A%3A\([^"%]*\)"!http://gtk2-perl.sourceforge.net/doc/pod/Gtk2/\1.html"!' \
	  >TiedListColumn.html

# find files in the dist with mod times this year, but without this year in
# the copyright line
copyright-years-check:
	year=`date +%Y`; \
	tar tvfz Gtk2-Ex-TiedListColumn-$(VERSION).tar.gz \
	| grep $$year- \
	| sed 's:^.*Gtk2-Ex-TiedListColumn-$(VERSION)/::' \
	| (result=0; \
	  while read i; do \
	    case $$i in \
	      '' | */ \
	      | debian/changelog | debian/compat | debian/control \
	      | t/pod.t \
	      | COPYING | MANIFEST* | SIGNATURE | META.yml) \
	      continue ;; \
	    esac; \
	    if test -e "$(srcdir)/$$i"; then f="$(srcdir)/$$i"; \
	    else f="$$i"; fi; \
	    if ! grep -q "Copyright.*$$year" $$f; then \
	      echo "$$i:1: this file"; \
	      grep Copyright $$f; \
	      result=1; \
	    fi; \
	  done; \
	  exit $$result)

debug-constants-check:
	if egrep -n 'DEBUG => [^0]' $(TO_INST_PM); then exit 1; else exit 0; fi

MAKE_FRAG
}
