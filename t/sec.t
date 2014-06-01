#!perl -w

use strict;
use warnings;

use Debian::Releases;
use Test::More tests => 4;

my $DR = Debian::Releases->new();

ok(!$DR->is_supported('lenny'));
ok($DR->is_supported('squeeze')); # LTS support till feb 2016
ok($DR->is_supported('wheezy'));
ok(!$DR->is_supported('jessie')); # no because it's not yet maintained by the security team

