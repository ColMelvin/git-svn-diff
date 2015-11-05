#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/lib";

use Temp::Repo;

use Test::More tests => 6;
use Test::Repo;

my $repo = Temp::Repo->new();

# Note the lack of newline in the contents.
$repo->svn_new_file("file", "contents");
$repo->svn_commit("Initial commit");
test_repo($repo, [qw(-c 1)], "Added a text file");

$repo->svn_overwrite_file("file", "Contents");
$repo->svn_commit("Modification commit");
$repo->git_run(qw(git checkout -q git-svn));
test_repo($repo, [qw(-c 2)], "Modified the text file");

test_repo($repo, [qw(-r 0:2)], "Diff over multiple commits");

$repo->svn_remove_file("file");
$repo->svn_commit("Deletion commit");
$repo->git_run(qw(git checkout -q git-svn));
test_repo($repo, [qw(-c 3)], "Deleted the text file");

test_repo($repo, [qw(-r 1:3)], "Deletion combination");
test_repo($repo, [qw(-r 0:3)], "Empty diff");

exit;

sub test_repo {
	my ($repo, $args, $message) = @_;
	Test::Repo::test_diff($repo, args => $args, name => $message);
}
