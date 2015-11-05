#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/lib";

use Temp::Repo;

use Test::More tests => 8;
use Test::Repo qw(cmp_ver get_svn_version);

my $repo = Temp::Repo->new(stdlayout => 1);

$repo->svn_new_file("trunk/file", "contents\n");
$repo->svn_commit("Initial commit");	# r2

$repo->svn_new_file("trunk/other", "stuff\n");
$repo->svn_commit("Added an other file");	# r3

# Set BASE to trunk@r3 (Git-only)
$repo->git_run(qw(git checkout -q origin/trunk));

$repo->svn_run(qw(svn copy), "trunk", "branches/FEATURE");
$repo->svn_commit("Branch for feature");	# r4

$repo->svn_overwrite_file("trunk/file", "updated\ncontents\n");
$repo->svn_new_file("trunk/new", "file\n");
$repo->svn_commit("Add a new file");	# r5

$repo->svn_overwrite_file("branches/FEATURE/other", "stuffed\n");
$repo->svn_commit("Modified other in branch");	# r6

$repo->svn_overwrite_file("trunk/new", "information\n");
$repo->svn_commit("Modified new");	# r7

# Set BASE to trunk@r3 (SVN-only)
my @extra = ('--ignore-ancestry') if cmp_ver(get_svn_version(), '1.7') >= 0;
$repo->svn_run(qw(svn switch -r 3), @extra, "$repo->{repo}/trunk");

# Test with a BASE that is earlier than HEAD.
test_repo($repo, [qw(-r BASE)], 1, undef, "Determine BASE when BASE != SVN HEAD");

$repo->wc_set_file("file", "revised\ncontents\n");  # Last changed in trunk@r2
$repo->wc_set_file("other", "Nothing special");     # Last changed in trunk@r3

# Test with a BASE that is earlier than HEAD and Working Copy changes.
test_repo($repo, [qw(-r BASE)], 1, undef, "Determine BASE when BASE != SVN HEAD & working copy has changes");

# Clear working copy changes
$repo->svn_run(qw(svn revert -R .));
$repo->git_run(qw(git checkout -- .));

# Set BASE to SVN HEAD
$repo->svn_run(qw(svn update));
$repo->git_run(qw(git checkout -q origin/trunk));

test_repo($repo, [qw(-r BASE)], 1, undef, "Determine BASE when BASE == SVN HEAD");
test_repo($repo, [qw(-r BASE)], 1, [ 'file' ], "Determine BASE when an existing file is given");
test_repo($repo, [qw(-r BASE)], 1, [ 'file', 'other' ], "Determine BASE when existing files are given");

$repo->wc_set_file("file", "revised\ncontents\n");  # Last changed in trunk@r5

test_repo($repo, [qw(-r BASE)], 1, undef, "Determine BASE when working copy has changes");

$repo->git_run(qw(git commit -a -m), "Commit in Git only");

test_repo($repo, [qw(-r BASE)], 1, undef, "Determine BASE when Git has commits not in SVN");

$repo->svn_overwrite_file("other", "stuffed\n");
$repo->git_run(qw(git cherry-pick origin/FEATURE));

{
	local $TODO = "Issue #8";
	test_repo($repo, [qw(-r BASE)], 1, undef, "Determine BASE when Git has a cherry-pick from SVN");
}

exit;

sub test_repo {
	my ($repo, $args, $global_rev, $files, $message) = @_;
	Test::Repo::test_diff($repo, args => $args, git_args => [$global_rev ? '--global-revision' : '--no-global-revision'], files => $files, name => $message);
}
