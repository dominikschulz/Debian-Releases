#!perl -w

use strict;
use warnings;

use Debian::Releases;
use Test::More tests => 4;

my $DR = Debian::Releases->new();

ok($DR->is_released('lenny'));
ok($DR->is_released('squeeze'));
ok($DR->is_released('wheezy'));
ok(!$DR->is_released('jessie'));

