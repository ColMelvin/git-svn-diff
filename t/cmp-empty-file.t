#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/lib";

use Temp::Repo;

use Test::More tests => 4;
use Test::Repo;

my $repo = Temp::Repo->new();

$repo->svn_new_file("empty", "");
$repo->svn_commit("Initial commit");

$repo->svn_new_file("file", "contents");
$repo->svn_commit("Add file with contents");

$repo->svn_remove_file("empty");
$repo->svn_commit("Remove empty file");

$repo->svn_remove_file("file");
$repo->svn_commit("Remove file with contents");

# Checkout the latest commit in the branch to resolve SVN revisions.
$repo->git_run(qw(git checkout -q git-svn));

test_repo($repo, [qw(-c 1)], "Added empty file");
{
	local $TODO = "Issue #17";
	test_repo($repo, [qw(-c 3)], "Removed empty file");
}

{
	local $TODO = "Issue #16";

	# We expect "empty" to appear before "file" in the diff output.  If not, the test could pass (negating the TODO).
	test_repo($repo, [qw(-r 0:2)], "Add empty and regular file");
}

{
	local $TODO = "Issue #17";
	test_repo($repo, [qw(-r 2:4)], "Remove empty and regular file");
}

exit;

sub test_repo {
	my ($repo, $args, $message) = @_;
	Test::Repo::test_diff($repo, args => $args, git_args => [ "--no-renames" ], name => $message);
}
