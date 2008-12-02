#!/usr/bin/perl
use strict;
use warnings;

# the following as recommended by the Test::Pod docs

use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();
