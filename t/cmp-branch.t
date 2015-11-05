#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/lib";

use Temp::Repo;

use Test::More tests => 4;
use Test::Repo;

my $repo = Temp::Repo->new(stdlayout => 1);

$repo->svn_new_file("trunk/file", "content\n");
$repo->svn_new_dir("trunk/dir/");
$repo->svn_new_file("trunk/dir/nested", "Nested file\n");
$repo->svn_commit("Initial commit");

$repo->svn_run(qw(svn copy), "trunk", "branches/FEATURE");
$repo->svn_commit("Branch for feature");

$repo->svn_overwrite_file("trunk/file", "Contents\n");
$repo->svn_overwrite_file("trunk/dir/nested", "Nested file\nupdated\n");
$repo->svn_commit("Modify mainline copy");

$repo->svn_overwrite_file("branches/FEATURE/file", "content\nchanged\n");
$repo->svn_overwrite_file("branches/FEATURE/dir/nested", "Nested file\nchanged\n");
$repo->svn_commit("Modify feature copy");

$repo->svn_run(qw(svn copy), "trunk", "branches/HOTFIX");
$repo->svn_commit("Branch for hotfix");

$repo->svn_overwrite_file("branches/HOTFIX/file", "Moar contents\n");
$repo->svn_commit("Modify hotfix copy");

$TODO = "Issues #22 & #23";
test_repo($repo, "trunk", "FEATURE", "Compare trunk and branch");
test_repo($repo, "trunk", "HOTFIX", "Compare trunk and branch");
test_repo($repo, "FEATURE", "HOTFIX", "Compare 2 branches");

Test::Repo::test_diff($repo,
	svn_args => [ svn_branch($repo, "trunk@2"), svn_branch($repo, "FEATURE") ],
	git_args => [ "origin/trunk^", "origin/FEATURE" ],
	name => "Compare versioned revisions",
);

exit;

sub test_repo {
	my ($repo, $old, $new, $message) = @_;
	Test::Repo::test_diff($repo, svn_args => [ svn_branch($repo, $old), svn_branch($repo, $new) ], git_args => [ "origin/$old", "origin/$new" ], name => $message);
}

sub svn_branch {
	my ($repo, $branch) = @_;
	return "$repo->{repo}/$branch" if $branch =~ m/^trunk(?:\@\d+)?$/;
	return "$repo->{repo}/branches/$branch";
}
