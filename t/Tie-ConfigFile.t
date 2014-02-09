#!/usr/bin/env perl

#
# Copyright (C) 2014 by Tomasz Konojacki
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.18.2 or,
# at your option, any later version of Perl 5 you may have available.
#

use utf8;

use strict;
use warnings;

use Test::More tests => 15;
use File::Temp qw(tempfile);

BEGIN { use_ok('Tie::ConfigFile') };

# create temporary file for tests
my($fh, $filename) = tempfile(UNLINK => 0);

# we won't be using filehandle
close $fh;

my(%config, $err);

ok(
    tie(%config, 'Tie::ConfigFile', filename => $filename, readonly => 0),
    'Tie hash (read-write)'
);

ok($config{test} = 1337, 'Write to hash');

ok($config{test2} = 'ąśćź', 'Write to hash (utf-8)');

ok(!($config{test3} = ''), 'Write to hash (empty)');

ok(untie(%config), 'Untie hash (read-write)');

ok(
    tie(%config, 'Tie::ConfigFile', filename => $filename),
    'Tie hash (readonly)'
);

ok($config{test} == 1337, 'Read from hash (1)');

ok(
    ($config{test2} eq 'ąśćź') && utf8::is_utf8($config{test2}),
    'Read from hash (utf-8)'
);

ok(!defined($config{test3} && exists($config{test3})), 'Read from hash (empty) (1)');

eval {
    $config{this} = 'should die'
};

if ($@) { $err = $@ }

ok($err, 'Write to hash (readonly)');

ok(untie(%config), 'Untie hash (readonly)');

ok(
    tie(%config, 'Tie::ConfigFile', filename => $filename, empty_is_undef => 0),
    'Tie hash (empty)'
);

ok(defined($config{test3}) && ($config{test3} eq ''), 'Read from hash (empty) (2)');

ok(untie(%config), 'Untie hash (empty)');

# clean-up
unlink $filename;