#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/lib";

use Temp::Repo;

use Test::More tests => 1;
use Test::Repo qw(test_diff);

my $repo = Temp::Repo->new();

# Note the lack of newline in the contents.
$repo->svn_new_file("first", "contents");
$repo->svn_new_file("second", "data");
$repo->svn_commit("Initial commit");

$repo->svn_overwrite_file("first", "Contents");
$repo->svn_commit("Modify first");

$repo->svn_overwrite_file("second", "Additional data");
$repo->svn_commit("Modify second");

$repo->svn_new_file("third", "");
$repo->svn_commit("Add third file");

$repo->git_run(qw(git checkout -q git-svn));

# Modify working copy without committing
$repo->wc_set_file("first", "Nothing");
$repo->wc_set_file("second", "Nothing");

test_diff($repo, args => [qw(-r 2)], git_args => [ '--global-revision' ], name => "Avoid crash with empty file");

exit;
