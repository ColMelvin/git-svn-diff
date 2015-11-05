#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/lib";

use Temp::Repo;

use Test::More tests => 3;
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

$repo->svn_new_file("third", "wheel");
$repo->svn_commit("Add third file");

$repo->git_run(qw(git checkout -q git-svn));

# Modify working copy without committing
$repo->wc_set_file("first", "Nothing");
$repo->wc_set_file("second", "Nothing");

test_diff($repo, args => [qw(-r 1:3)], git_args => [ '--global-revision' ], name => "Use global revision when revisions specified");
{
	local $TODO = "Issue #15";
	test_diff($repo, args => [qw(-r 2)], git_args => [ '--global-revision' ], name => "Use global revision when revisions specified");
}

test_diff($repo, git_args => [ '--no-global-revision' ], name => "Avoid global revision when no revisions specified");

exit;
