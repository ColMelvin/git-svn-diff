#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Spec;
use Temp::Repo;

use Test::More tests => 2;
use Test::Repo;

my $repo = Temp::Repo->new();

$repo->svn_new_file("file", "content\n");
$repo->svn_commit("Initial commit");

$repo->svn_run(qw(svn copy file copy-of-file));
$repo->svn_commit("Copy file");
my $copy = File::Spec->catfile($repo->get_svn_wc(), 'copy-of-file');
die "File not copied" if !-f $copy;

$repo->svn_overwrite_file("file", "Other stuff!\n");
$repo->svn_commit("Overwrite original file");

# Checkout the latest commit in the branch to resolve SVN revisions.
$repo->git_run(qw(git checkout -q git-svn));

test_repo($repo, [qw(-c 2)], "Renamed file");
test_repo($repo, [qw(-r 1:3)], "Added new file with same filename as older");

exit;

sub test_repo {
	my ($repo, $args, $message) = @_;
	Test::Repo::test_diff($repo, args => $args, git_args => [ "--no-renames" ], name => $message);
}
