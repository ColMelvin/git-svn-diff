#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/lib";

use Temp::Repo;

use Test::More tests => 3;
use Test::Repo;

my $repo = Temp::Repo->new();

# Control characters 00-1F, 7F are disallowed by SVN.
$repo->svn_new_file("file with spaces", "contents");
$repo->svn_commit("Initial commit");

$repo->svn_overwrite_file("file with spaces", "Changed contents");
$repo->svn_commit("Modification commit");

$repo->svn_remove_file("file with spaces");
$repo->svn_commit("Deletion commit");

$repo->git_run(qw(git checkout -q git-svn));

test_repo($repo, [qw(-c 1)], "Created files");
test_repo($repo, [qw(-c 2)], "Modified files");
test_repo($repo, [qw(-c 3)], "Deleted file");

exit;

sub test_repo {
	my ($repo, $args, $message) = @_;
	Test::Repo::test_diff($repo, args => $args, name => $message);
}
