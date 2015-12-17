#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Spec;
use Temp::Repo;

use Test::More;
use Test::Repo qw(test_diff get_svn_version cmp_ver);

plan skip_all => "Annotation “nonexistent” not used before SVN v1.9" if cmp_ver(get_svn_version(), "1.9") < 0;
plan tests => 1;

my $repo = Temp::Repo->new();

# Note the lack of newline in the contents.
$repo->svn_new_file("file", "contents");
$repo->svn_commit("Initial commit");

$repo->git_run(qw(git checkout -q git-svn));

# Modify working copy without committing
$repo->svn_remove_file("file");
unlink File::Spec->catfile($repo->get_git_wc(), 'file') or die "Cannot remove file";

test_diff($repo, name => "Working copy shows (nonexistent)");

exit;
