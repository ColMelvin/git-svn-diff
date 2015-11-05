#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/lib";

use Temp::Repo;

use Test::More;
use Test::Repo;

eval { symlink("","") };
plan skip_all => "System does not support symlinks" if $@;

my $repo = Temp::Repo->new();

$repo->svn_new_file("file", "content\n");
$repo->svn_set_symlink("file", "link");
$repo->svn_run(qw(svn add link));
$repo->svn_commit("Initial commit");

plan skip_all => "The system is creating fake symlinks" if !-l ($repo->get_svn_wc() . "/link");
plan tests => 2;

$repo->svn_remove_file("link");
$repo->svn_commit("Remove link");

$repo->svn_new_file("link", "actual file");
$repo->svn_commit("Convert to real file");

# Checkout the latest commit in the branch to resolve SVN revisions.
$repo->git_run(qw(git checkout -q git-svn));

$TODO = "Issue #11";
test_repo($repo, [qw(-c 1)], "Added symlinks");
$TODO = "Issue #18";
test_repo($repo, [qw(-r 1:3)], "Change symlink to regular file");

exit;

sub test_repo {
	my ($repo, $args, $message) = @_;
	Test::Repo::test_diff($repo, args => $args, name => $message);
}
