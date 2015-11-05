#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/lib";

use Temp::Repo;

use Test::More tests => 1;
use Test::Repo;

my $repo = Temp::Repo->new();

$repo->svn_new_file("file", "content\n");
$repo->svn_commit("Initial commit");

$repo->svn_remove_file("file");
$repo->svn_commit("Deletion commit");

$repo->svn_new_file("file", "Other stuff!\n");
$repo->svn_commit("Re-add commit");

# Checkout the latest commit in the branch to resolve SVN revisions.
$repo->git_run(qw(git checkout -q git-svn));

test_repo($repo, [qw(-r 1:3)], "Readded file");

exit;

sub test_repo {
	my ($repo, $args, $message) = @_;
	Test::Repo::test_diff($repo, args => $args, name => $message);
}
