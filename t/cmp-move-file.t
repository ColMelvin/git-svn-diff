#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/lib";

use Temp::Repo;

use Test::More tests => 2;
use Test::Repo;

my $repo = Temp::Repo->new();

$repo->svn_new_file("file", "content\n");
$repo->svn_commit("Initial commit");

$repo->svn_run(qw(svn move file new-name));
$repo->svn_commit("Rename commit");

$repo->svn_new_file("file", "Other stuff!\n");
$repo->svn_commit("Re-add commit");

# Checkout the latest commit in the branch to resolve SVN revisions.
$repo->git_run(qw(git checkout -q git-svn));

test_repo($repo, [qw(-c 2)], "Renamed file");
test_repo($repo, [qw(-r 1:3)], "Added new file with same filename as older");

exit;

sub test_repo {
	my ($repo, $args, $message) = @_;
	Test::Repo::test_diff($repo, args => $args, git_args => [ '--no-renames' ], name => $message);
}
