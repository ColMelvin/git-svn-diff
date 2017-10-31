#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 4;
use Test::Repo;

{
	package Temp::Repo::GitSubdir;

	use File::Spec;
	use Temp::Repo;

	our @ISA = qw(Temp::Repo);

	sub set_subdir {
		my ($self, $subdir) = @_;
		$self->{_subdir} = $subdir;
	}

	sub get_git_wc {
		my ($self) = @_;
		return File::Spec->catdir($self->SUPER::get_git_wc(), $self->{_subdir}) if $self->{_subdir};
		return $self->SUPER::get_git_wc();
	}
}

my $repo = Temp::Repo::GitSubdir->new();

# Note the lack of newline in the contents.
$repo->svn_new_file("file", "contents\n");
$repo->svn_new_dir("dir/");
$repo->svn_new_file("dir/nested", "Nested file\n");
$repo->svn_commit("Initial commit");

$repo->svn_overwrite_file("file", "Contents\n");
$repo->svn_commit("Modification commit");

$repo->svn_overwrite_file("dir/nested", "Changed\n");
$repo->svn_commit("Second modification");
$repo->git_run(qw(git checkout -q git-svn));

Test::Repo::cmp_diff($repo->git_svn_diff(qw(-c 2 --relative-repo)), <<DIFF, "Root working copy (top-level)");
Index: file
===================================================================
--- file\t(revision 1)
+++ file\t(revision 2)
@@ -1 +1 @@
-contents
+Contents
DIFF
Test::Repo::cmp_diff($repo->git_svn_diff(qw(-c 3 --relative-repo)), <<DIFF, "Root working copy (nested)");
Index: dir/nested
===================================================================
--- dir/nested\t(revision 2)
+++ dir/nested\t(revision 3)
@@ -1 +1 @@
-Nested file
+Changed
DIFF

$repo->set_subdir("dir");

# When this test is run as part of a git-rebase, it can fail because this
# environmental variable is set.  Clear it for consistent runs.
delete $ENV{GIT_DIR};

$TODO = "Issue #7";
Test::Repo::cmp_diff($repo->git_svn_diff(qw(-c 2 --relative-repo)), <<DIFF, "Root working copy (top-level)");
Index: file
===================================================================
--- file\t(revision 1)
+++ file\t(revision 2)
@@ -1 +1 @@
-contents
+Contents
DIFF
Test::Repo::cmp_diff($repo->git_svn_diff(qw(-c 3 --relative-repo)), <<DIFF, "Root working copy (nested)");
Index: dir/nested
===================================================================
--- dir/nested\t(revision 2)
+++ dir/nested\t(revision 3)
@@ -1 +1 @@
-Nested file
+Changed
DIFF
