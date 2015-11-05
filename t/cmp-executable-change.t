#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/lib";

use Temp::Repo;

use Test::More tests => 6;
use Test::Repo;

my $repo = Temp::Repo->new();

# Note the lack of newline in the contents.
$repo->svn_new_file("file", <<EXEC);
#!/bin/sh
/bin/true
EXEC
$repo->svn_commit("Initial commit");

$repo->svn_run(qw(svn propset svn:executable * file));
$repo->svn_commit("Make executable");

$repo->svn_run(qw(svn copy file copy));
$repo->svn_commit("Copy executable file");

$repo->svn_run(qw(svn propdel svn:executable file));
$repo->svn_commit("Remove execution bit");

$repo->svn_run(qw(svn rm copy));
$repo->svn_commit("Remove executable file");

# Checkout the latest commit in the branch to resolve SVN revisions.
$repo->git_run(qw(git checkout -q git-svn));

{
	local $TODO = "Issue #9";
	test_repo($repo, [qw(-c 2)], "Added execution bit");
	test_repo($repo, [qw(-c 4)], "Removed execution bit");

	test_repo($repo, [qw(-c 3)], "Add executable file");
	test_repo($repo, [qw(-r 0:2)], "Add executable file (multiple commits)");

	test_repo($repo, [qw(-c 4)], "Remove executable file");
}
test_repo($repo, [qw(-r 1:5)], "No change (multiple commits)");

exit;

sub test_repo {
	my ($repo, $args, $message) = @_;
	Test::Repo::test_diff($repo, args => $args, name => $message);
}
