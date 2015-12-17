#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/lib";

use Temp::Repo;

use Test::More;
use Test::Repo qw(cmp_ver get_svn_version);

eval { symlink("","") };
plan skip_all => "System does not support symlinks" if $@;
plan skip_all => "Versions before SVN 1.9 do not support direct typechanges" if cmp_ver(get_svn_version(), '1.9') < 0;

my $repo = Temp::Repo->new();

$repo->svn_new_file("file", "content\n");
$repo->svn_set_symlink("file", "link");
$repo->svn_run(qw(svn add link));
$repo->svn_commit("Initial commit");

plan skip_all => "The system is creating fake symlinks" if !-l ($repo->get_svn_wc() . "/link");
plan tests => 2;

$repo->svn_remove_file("link");
$repo->svn_new_file("link", "actual file");
$repo->svn_commit("Convert to real file");

# Checkout the latest commit in the branch to resolve SVN revisions.
$repo->git_run(qw(git checkout -q git-svn));

$TODO = "Issue #11";
test_repo($repo, [qw(-c 1)], "Added symlinks");
$TODO = "Issue #18";
test_repo($repo, [qw(-c 2)], "Change symlink to regular file");

exit;

sub test_repo {
	my ($repo, $args, $message) = @_;
	Test::Repo::test_diff($repo, args => $args, svn_args => ['--ignore-properties'], name => $message);
}
