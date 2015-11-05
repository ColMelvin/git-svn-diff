#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/lib";

use Temp::Repo;

use Test::More tests => 6;
use Test::Repo;

my $GitEmptyTree = "4b825dc642cb6eb9a060e54bf8d69288fbee4904";

my $repo = Temp::Repo->new();

# Note the lack of newline in the contents.
$repo->svn_new_file("file", "contents");
$repo->svn_commit("Initial commit");
test_repo($repo, [qw(-c 1)], [$GitEmptyTree, "git-svn"], "Added a text file");

$repo->svn_overwrite_file("file", "Contents");
$repo->svn_commit("Modification commit");
test_repo($repo, [qw(-c 2)], [qw(git-svn~ git-svn)], "Modified the text file");

test_repo($repo, [qw(-r 0:2)], [$GitEmptyTree, "git-svn"], "Diff over multiple commits");

$repo->svn_remove_file("file");
$repo->svn_commit("Deletion commit");
test_repo($repo, [qw(-c 3)], [qw(git-svn~ git-svn)], "Deleted the text file");

test_repo($repo, [qw(-r 1:3)], [qw(git-svn~2 git-svn)], "Deletion combination");
test_repo($repo, [qw(-r 0:3)], [$GitEmptyTree, "git-svn"], "Empty diff");

exit;

sub test_repo {
	my ($repo, $svn, $git, $message) = @_;
	Test::Repo::test_diff($repo, svn_args => $svn, git_args => $git, name => $message);
}
