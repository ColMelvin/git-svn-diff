#!/usr/bin/perl

use Test::More tests => 1;

close STDERR;
system $^X, '-c', 'bin/git-svn-diff' and BAIL_OUT "Cannot compile script 'git-svn-diff'";
pass("Script git-svn-diff compilation");
