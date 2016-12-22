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

$repo->svn_new_file("file", "content\n");
$repo->svn_new_dir("dir/");
$repo->svn_new_file("dir/subfile", "Other content\n");
$repo->svn_set_symlink("file", "link-to-file");
$repo->svn_set_symlink("dir", "link-to-dir");
$repo->svn_set_symlink("link-to-file", "link-to-link");
$repo->svn_set_symlink("does-not-exist", "link-to-nothing");
$repo->svn_run(qw(svn add link-to-file link-to-dir link-to-link link-to-nothing));
$repo->svn_commit("Initial commit");

$repo->svn_set_symlink("link-to-dir", "link-to-link");
$repo->svn_commit("Move the symlink target");

$repo->svn_run(qw(svn rm link-to-nothing));
$repo->svn_run(qw(svn rm link-to-link));
$repo->svn_run(qw(svn rm link-to-dir));
$repo->svn_commit("Remove links");

# Checkout the latest commit in the branch to resolve SVN revisions.
$repo->git_run(qw(git checkout -q git-svn));

plan skip_all => "The system is creating fake symlinks" if !-l ($repo->get_svn_wc() . "/link-to-file");
plan tests => 3;

{
	local $TODO = "Issue #11";
	test_repo($repo, [qw(-c 1)], "Added symlinks");
}
test_repo($repo, [qw(-c 2)], "Move symlink target");
{
	# Before SVN 1.9, the implicit deletion of properties was not shown for
	# deleted files.
	local $TODO = "Issue #11" if cmp_ver(get_svn_version(), '1.9') >= 0;
	test_repo($repo, [qw(-c 3)], "Removed symlinks");
}

exit;

sub test_repo {
	my ($repo, $args, $message) = @_;
	Test::Repo::test_diff($repo, args => $args, name => $message);
}
