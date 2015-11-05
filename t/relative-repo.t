#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/lib";

use Temp::Repo;

use Test::More tests => 5;
use Test::Repo;

my $repo = Temp::Repo->new(stdlayout => 1);
sleep 1;	# Issue #28

$repo->svn_new_file("trunk/file", "content\n");
$repo->svn_new_dir("trunk/dir/");
$repo->svn_new_file("trunk/dir/nested", "Nested file\n");
$repo->svn_commit("Initial commit");
sleep 1;	# Issue #28

$repo->svn_run(qw(svn copy), "trunk", "branches/FEATURE");
$repo->svn_commit("Branch for feature");
sleep 1;	# Issue #28

$repo->svn_overwrite_file("trunk/file", "Contents\n");
$repo->svn_overwrite_file("trunk/dir/nested", "Nested file\nupdated\n");
$repo->svn_commit("Modify mainline copy");
sleep 1;	# Issue #28

$repo->svn_overwrite_file("branches/FEATURE/file", "content\nchanged\n");
$repo->svn_overwrite_file("branches/FEATURE/dir/nested", "Nested file\nchanged\n");
$repo->svn_commit("Modify feature copy");

$repo->git_run(qw(git checkout -q origin/FEATURE));

Test::Repo::cmp_diff($repo->git_svn_diff(qw(-c 2)), '', "Before branch (plain)");
Test::Repo::cmp_diff($repo->git_svn_diff(qw(-c 4 --relative-repo)), <<DIFF, "Outside branch");
Index: branches/FEATURE/dir/nested
===================================================================
--- branches/FEATURE/dir/nested\t(revision 0)
+++ branches/FEATURE/dir/nested\t(revision 3)
@@ -0,0 +1 @@
+Nested file
Index: branches/FEATURE/file
===================================================================
--- branches/FEATURE/file\t(revision 0)
+++ branches/FEATURE/file\t(revision 3)
@@ -0,0 +1 @@
+content
DIFF

Test::Repo::cmp_diff($repo->git_svn_diff(qw(-c 5 --relative-repo)), <<DIFF, "Inside branch");
Index: branches/FEATURE/dir/nested
===================================================================
--- branches/FEATURE/dir/nested\t(revision 3)
+++ branches/FEATURE/dir/nested\t(revision 5)
@@ -1 +1,2 @@
 Nested file
+changed
Index: branches/FEATURE/file
===================================================================
--- branches/FEATURE/file\t(revision 3)
+++ branches/FEATURE/file\t(revision 5)
@@ -1 +1,2 @@
 content
+changed
DIFF

$repo->git_run(qw(git checkout -q origin/trunk));

Test::Repo::cmp_diff($repo->git_svn_diff(qw(-c 2 --relative-repo)), <<DIFF, "Trunk before branch");
Index: trunk/dir/nested
===================================================================
--- trunk/dir/nested\t(revision 0)
+++ trunk/dir/nested\t(revision 2)
@@ -0,0 +1 @@
+Nested file
Index: trunk/file
===================================================================
--- trunk/file\t(revision 0)
+++ trunk/file\t(revision 2)
@@ -0,0 +1 @@
+content
DIFF

Test::Repo::cmp_diff($repo->git_svn_diff(qw(-c 4 --relative-repo)), <<DIFF, "Inside trunk");
Index: trunk/dir/nested
===================================================================
--- trunk/dir/nested\t(revision 2)
+++ trunk/dir/nested\t(revision 4)
@@ -1 +1,2 @@
 Nested file
+updated
Index: trunk/file
===================================================================
--- trunk/file\t(revision 2)
+++ trunk/file\t(revision 4)
@@ -1 +1 @@
-content
+Contents
DIFF
