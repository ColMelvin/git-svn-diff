#!/usr/bin/perl

use FindBin;
use File::Temp;
use Test::More tests => 5;

my $diff_bin = "$FindBin::Bin/../bin/git-svn-diff";
my $dir = File::Temp::tempdir(TMPDIR => 1, CLEANUP => 1);
chdir $dir;

system qw(git init);
write_file("file", "contents\n");
system qw(git add -A);
system qw(git commit -m), "Initial commit";

write_file("file", "Changed contents\n");
system qw(git add -A);
system qw(git commit -m), "Modifications";

write_file("file", "Changed contents\nWorking copy\n");

my $got = qx{"$^X" "$diff_bin" -c 1 2>&1};
my $expected = <<ERR;
fatal: Cannot find revision: 1
ERR
is($got, $expected, "Revision 1 not found");

$got = qx{"$^X" "$diff_bin" -c 2 2>&1};
$expected = <<ERR;
fatal: Cannot find revision: 2
ERR
is($got, $expected, "Revision 2 not found");

$got = qx{"$^X" "$diff_bin" HEAD^ HEAD 2>&1};
$expected = <<ERR;
fatal: Commit '[0-9a-f]{40}' must be in SVN repository
ERR
like($got, qr/$expected/, "Cannot resolve revision");

$got = qx{"$^X" "$diff_bin" 2>&1};
$expected = <<ERR;
fatal: Cannot find SVN base commit in branch
ERR
is($got, $expected, "Cannot resolve revision");

$got = qx{"$^X" "$diff_bin" -r 1 2>&1};
my $expected = <<ERR;
fatal: Cannot find revision: 1
ERR
is($got, $expected, "Revision 1 not found");

sub write_file {
	my ($filename, $contents) = @_;

	open my $fh, '>', $filename or die "Cannot open file “$filename”: $!";
	print {$fh} $contents;
	close $fh or warn "Cannot close file “$filename”: $!";

	return;
}
