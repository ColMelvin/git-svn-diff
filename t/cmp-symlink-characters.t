#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/lib";

use Temp::Repo;

use Test::More;
use Test::Repo qw(cmp_ver get_svn_version);

eval { symlink("","") };
plan skip_all => "System does not support symlinks" if $@;
plan skip_all => "Windows has 2 types of symlinks" if $^O eq "msys" || $^O eq "MSWin32";

my $repo = Temp::Repo->new();

$repo->svn_set_symlink("link to file with whitespace", "link-with-whitespace");
$repo->svn_set_symlink("link\nto an odd file\nname", "link-with-newlines");
$repo->svn_set_symlink("link\'with\"quotes", "link-with-quotes");
$repo->svn_set_symlink("link\\with/slashes", "link-with-slashes");
$repo->svn_set_symlink("link\awith\bcontrol\1characters\x1f", "link-with-control-characters");
$repo->svn_run(qw(svn add link-with-whitespace link-with-newlines link-with-quotes link-with-slashes link-with-control-characters));
$repo->svn_commit("Initial commit");

$repo->svn_set_symlink("link\tto\tfile\twith\twhitespace", "link-with-whitespace");
$repo->svn_commit("Move the symlink target");

$repo->svn_set_symlink(".", "link-with-whitespace");
$repo->svn_set_symlink(".", "link-with-newlines");
$repo->svn_set_symlink(".", "link-with-quotes");
$repo->svn_set_symlink(".", "link-with-slashes");
$repo->svn_set_symlink(".", "link-with-control-characters");
$repo->svn_commit("Clear links");

# Checkout the latest commit in the branch to resolve SVN revisions.
$repo->git_run(qw(git checkout -q git-svn));

plan skip_all => "The system is creating fake symlinks" if !-l ($repo->get_svn_wc() . "/link-with-whitespace");
plan tests => 3;

{
	local $TODO = "Issue #11";
	test_repo($repo, [qw(-c 1)], "Added symlinks");
}
test_repo($repo, [qw(-c 2)], "Move symlink target");
test_repo($repo, [qw(-c 3)], "Cleared symlinks");

exit;

sub test_repo {
	my ($repo, $args, $message) = @_;
	Test::Repo::test_diff($repo, args => $args, name => $message);
}
