#!/usr/bin/perl

# Copyright 2008 Kevin Ryde

# This file is part of Gtk2-Ex-TiedListColumn.
#
# Gtk2-Ex-TiedListColumn is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-TiedListColumn is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-TiedListColumn.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use Gtk2::Ex::TiedListColumn;

use Test::More tests => 2518;
use Gtk2;

ok ($Gtk2::Ex::TiedListColumn::VERSION >= 1);
ok (Gtk2::Ex::TiedListColumn->VERSION  >= 1);

diag ("Perl-Gtk2 version ",Gtk2->VERSION);
diag ("Perl-Glib version ",Glib->VERSION);
diag ("Compiled against Glib version ",
      Glib::MAJOR_VERSION(), ".",
      Glib::MINOR_VERSION(), ".",
      Glib::MICRO_VERSION(), ".");
diag ("Running on       Glib version ",
      Glib::major_version(), ".",
      Glib::minor_version(), ".",
      Glib::micro_version(), ".");
diag ("Compiled against Gtk version ",
      Gtk2::MAJOR_VERSION(), ".",
      Gtk2::MINOR_VERSION(), ".",
      Gtk2::MICRO_VERSION(), ".");
diag ("Running on       Gtk version ",
      Gtk2::major_version(), ".",
      Gtk2::minor_version(), ".",
      Gtk2::micro_version(), ".");


# pretend insert_with_values() not available, as pre-Gtk 2.6
#
if (1 || $ENV{'MY_DEVELOPMENT_HACK_NO_INSERT_WITH_VALUES'}) {
  Gtk2::ListStore->can('insert_with_values'); # force autoload
  diag "can insert_with_values: ",
    Gtk2::ListStore->can('insert_with_values')||'no',"\n";

  undef *Gtk2::ListStore::insert_with_values;

  diag "can insert_with_values: ",
    Gtk2::ListStore->can('insert_with_values')||'no',"\n";
  die if Gtk2::ListStore->can('insert_with_values');
}


#------------------------------------------------------------------------------
# new

{
  my $store = Gtk2::ListStore->new ('Glib::String');
  my $aref = Gtk2::Ex::TiedListColumn->new ($store);
  Scalar::Util::weaken ($aref);
  is ($aref, undef, 'aref garbage collected when weakened');
}

{
  my $store = Gtk2::ListStore->new ('Glib::String');
  my $aref = Gtk2::Ex::TiedListColumn->new ($store);
  Scalar::Util::weaken ($store);
  ok ($store, 'store held alive by aref');
  $aref = undef;
  is ($store, undef, 'then garbage collected when aref gone');
}


#------------------------------------------------------------------------------
# accessors

{
  my $store = Gtk2::ListStore->new ('Glib::String');
  my @a;
  tie @a, 'Gtk2::Ex::TiedListColumn', $store, 0;
  is (tied(@a)->model, $store,
      'model() accessor');
  is (tied(@a)->column, 0,
      'column() accessor');
}

{
  my $store = Gtk2::ListStore->new ('Glib::String');
  my $aref = Gtk2::Ex::TiedListColumn->new ($store);

  is (tied(@$aref)->model, $store,
      'model() accessor');
  is (tied(@$aref)->column, 0,
      'column() accessor');
}


#------------------------------------------------------------------------------

my $store = Gtk2::ListStore->new (('Glib::Int') x 6, 'Glib::String');
my @a;
tie @a, 'Gtk2::Ex::TiedListColumn', $store, 6;
my @b;

sub store_contents {
  my @ret;
  for (my $iter = $store->get_iter_first;
       $iter;
       $iter = $store->iter_next($iter)) {
    push @ret, $store->get_value($iter,6);
  }
  return \@ret;
}

sub set_store {
  @b = @_;
  $store->clear;
  foreach (@_) {
    my $iter = $store->insert (999);
    $store->set_value ($iter, 6 => $_);
  }
}

#------------------------------------------------------------------------------
# fetch

{
  my @a;
  tie @a, 'Gtk2::Ex::TiedListColumn', $store, 6;

  set_store ();
  is ($a[0], undef);
  is ($a[1], undef);

  set_store ('a');
  is ($a[0], 'a');
  is ($a[1], undef);
  is ($a[-1], 'a');

  set_store ('a','b');
  is ($a[0], 'a');
  is ($a[1], 'b');
  is ($a[2], undef);
  is ($a[-1], 'b');
  is ($a[-2], 'a');
}


#------------------------------------------------------------------------------
# store

{
  set_store ('a');
  $a[0] = 'b';
  $b[0] = 'b';
  is_deeply (store_contents(), \@b);
  $a[-1] = 'c';
  $b[-1] = 'c';
  is_deeply (store_contents(), \@b);

  set_store ('a','b');
  $a[0] = 'x';
  $b[0] = 'x';
  is_deeply (store_contents(), \@b);
  $a[1] = 'y';
  $b[1] = 'y';
  is_deeply (store_contents(), \@b);
  $a[-1] = 'z';
  $b[-1] = 'z';
  is_deeply (store_contents(), \@b);
  $a[-2] = 'w';
  $b[-2] = 'w';
  is_deeply (store_contents(), \@b);

  set_store ('a','b');
  $a[2] = 'x';
  $b[2] = 'x';
  is_deeply (store_contents(), \@b,
             'immediate past end');

  set_store ('a','b');
  $a[5] = 'x';
  $b[5] = 'x';
  is_deeply (store_contents(), \@b,
             'a distance past end');
}


#------------------------------------------------------------------------------
# fetchsize

{
  set_store ('a');
  my @a;
  tie @a, 'Gtk2::Ex::TiedListColumn', $store;

  set_store ();
  is ($#a, -1);
  is (scalar(@a), 0);

  set_store ('a');
  is ($#a, 0);
  is (scalar(@a), 1);

  set_store ('a','b');
  is ($#a, 1);
  is (scalar(@a), 2);
}


#------------------------------------------------------------------------------
# storesize

{
  set_store ();
  $#a = -1;
  $#b = -1;
  is_deeply (store_contents(), \@b);

  set_store ();
  $#a = -2;
  $#b = -2;
  is_deeply (store_contents(), \@b);

  set_store ('b');
  $#a = -1;
  $#b = -1;
  is_deeply (store_contents(), \@b,
             'storesize truncate from 1 to empty');

  set_store ('b');
  $#a = 0;
  $#b = 0;
  is_deeply (store_contents(), \@b,
             'storesize unchanged 1');

  set_store ('a','b','c','d');
  $#a = 1;
  $#b = 1;
  is_deeply (store_contents(), \@b,
             'storesize truncate from 4 to 2');

  set_store ();
  $#a = 2;
  $#b = 2;
  is_deeply (store_contents(), \@b,
             'extend 0 to 3');

  set_store ('a');
  $#a = 1;
  $#b = 1;
  is_deeply (store_contents(), \@b,
             'extend 1 to 2');
}

#------------------------------------------------------------------------------
# exists

{
  set_store ();
  is (exists($a[0]), exists($b[0]));
  is (exists($a[1]), exists($b[1]));
  is (exists($a[-1]), exists($b[-1]));

  set_store ('b');
  is (exists($a[0]), exists($b[0]));
  is (exists($a[1]), exists($b[1]));
  is (exists($a[2]), exists($b[2]));
  is (exists($a[-1]), exists($b[-1]));
  is (exists($a[-2]), exists($b[-2]));
  is (exists($a[-99]), exists($b[-99]));

  set_store ('a','b');
  foreach my $i (-3 .. 3) {
    is (exists($a[$i]), exists($b[$i]), "exists $i");
  }
}



#------------------------------------------------------------------------------
# delete

{
  set_store ();
  delete $a[0];
  delete $b[0];
  is_deeply (store_contents(), \@b,
             'delete non-existant');

  set_store ('a');
  delete $a[0];
  delete $b[0];
  is_deeply (store_contents(), \@b,
             'delete sole element');

  set_store ('a');
  delete $a[99];
  delete $b[99];
  is_deeply (store_contents(), \@b,
             'delete big non-existant');

  set_store ('a','b');
  delete $a[0];
  delete $b[0];
  is_deeply (store_contents(), \@b);
  #
  # tied array not the same as ordinary perl array for exists on deleted
  # elements
  # is (exists($a[0]), exists($b[0]));

  set_store ('a','b');
  delete $a[1];
  delete $b[1];
  is_deeply (store_contents(), \@b,
             'delete last of 2');

}


#------------------------------------------------------------------------------
# clear

{
  set_store ();
  @a = ();
  @b = ();
  is_deeply (store_contents(), \@b,
             'clear empty');

  set_store ('a','b','c');
  @a = ();
  @b = ();
  is_deeply (store_contents(), \@b,
             'clear 3');
}


#------------------------------------------------------------------------------
# push

SKIP: {
  $store->can('insert_with_values')
    or skip 'no insert_with_values()', 2;

  set_store ();
  push @a, 'z';
  push @b, 'z';
  is_deeply (store_contents(), \@b);

  push @a, 'x','y';
  push @b, 'x','y';
  is_deeply (store_contents(), \@b);
}

#------------------------------------------------------------------------------
# pop

{
  set_store ();
  is (pop @a, pop @b);
  is_deeply (store_contents(), \@b,
             'pop empty');

  set_store ('x');
  is (pop @a, pop @b);
  is_deeply (store_contents(), \@b);

  set_store ('x','y');
  is (pop @a, pop @b);
  is_deeply (store_contents(), \@b);
}

#------------------------------------------------------------------------------
# shift

{
  set_store ();
  is_deeply ([shift @a], [shift @b]);
  is_deeply (store_contents(), \@b,
             'shift empty');

  set_store ('x');
  is_deeply ([shift @a], [shift @b]);
  is_deeply (store_contents(), \@b);

  set_store ('x','y');
  is_deeply ([shift @a], [shift @b]);
  is_deeply (store_contents(), \@b);
}

#------------------------------------------------------------------------------
# unshift

SKIP: {
  $store->can('insert_with_values')
    or skip 'no insert_with_values()', 4;

  set_store ();
  is (unshift(@a,'z'), unshift(@b,'z'));
  is_deeply (store_contents(), \@b);

  is (unshift(@a,'x','y'), unshift(@b,'x','y'));
  is_deeply (store_contents(), \@b);
}


#------------------------------------------------------------------------------
# splice

# this is pretty excessive, but makes sure to cover all combinations of
# positive and negative offset and length exceeding or not the array bounds.
#
SKIP: {
  $store->can('insert_with_values')
    or skip 'no insert_with_values()', 2437;

  my $a_warn = 0;
  my $b_warn = 0;
  local $SIG{__WARN__} = sub {
    my ($msg) = @_;
    if ($msg =~ /^TiedListColumn/) {
      $a_warn++;
    } elsif ($msg =~ /^splice()/) {
      $b_warn++;
    } else {
      print STDERR $msg;
    }
  };
  foreach my $old_content ([], ['w'], ['w','x'],
                           ['w','x','y'], ['w','x','y','z']) {
    foreach my $new_content ([], ['f'], ['f','g','h']) {
      foreach my $offset (-3 .. 3) {
        if ($offset < - @$old_content) { next; }

        foreach my $length (-3 .. 3) {
          my $name =
            "'" . join(',',@$old_content) . "'"
              . " splice "
                . " " . (defined $offset ? $offset : 'undef')
                  . "," . (defined $length ? $length : 'undef')
                    . "  '" . join(',',@$new_content) . "'";

          set_store (@$old_content);
          my $a_ret = scalar (splice @a, $offset, $length, @$new_content);
          my $b_ret = scalar (splice @b, $offset, $length, @$new_content);
          is        ($a_ret, $b_ret,
                     "scalar context return: " . $name);
          is_deeply (store_contents(), \@b,
                     "scalar context leaves: " . $name);

          set_store (@$old_content);
          $a_ret = [splice @a, $offset, $length, @$new_content];
          $b_ret = [splice @b, $offset, $length, @$new_content];
          is_deeply ($a_ret, $b_ret,
                     "array context return: " . $name);
          is_deeply (store_contents(), \@b,
                     "array context leaves: " . $name);
        }
      }
    }
  }
  is ($a_warn, $b_warn, 'warnings count');
}

exit 0;
