#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/lib";

use Temp::Repo;

use Test::More tests => 2;
use Test::Repo;

my $repo = Temp::Repo->new();

$repo->svn_new_dir("dir/");
$repo->svn_commit("Initial commit");

$repo->svn_run(qw(svn rm dir));
$repo->svn_commit("Remove directory");

# Checkout the latest commit in the branch to resolve SVN revisions.
$repo->git_run(qw(git checkout -q git-svn));

test_repo($repo, [qw(-c 1)], "Added directory");
test_repo($repo, [qw(-c 2)], "Removed directory");

exit;

sub test_repo {
	my ($repo, $args, $message) = @_;
	Test::Repo::test_diff($repo, args => $args, git_args => [ "--no-renames" ], name => $message);
}
