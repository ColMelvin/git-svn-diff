#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/lib";

use Temp::Repo;

use Test::More;
use Test::Repo qw(get_diff cmp_diff cmp_ver get_svn_version);

my $repo = Temp::Repo->new();

my $svn_version = get_svn_version();
plan skip_all => "Git annotations not available before SVN v1.7" if cmp_ver($svn_version, "1.7") < 0;
plan tests => 9 * 2;

# Since SVN is modeling their annotations after Git, we consider Git the
# authority on what should and should not be displayed (which differs from all
# other cmp tests).  The problem is, SVN is *really* bad at doing things
# correctly.  I suspect the SVN developers may not have been as thorough as we
# are in testing.
#
# Some notable issues include:
# A) Incorrect file mode
# A.1) Regular file number is wrong ("10644" instead of "100644")
# A.2) Executable files are always 10644 (see also B)
# A.3) Symlink files are always 10644
# B) No annotations for file mode changes (see also A.2)
# C) No index addresses (SHA1)
# D) Binary delta patches unsupported

# Note the lack of newline in the contents.
$repo->svn_new_file("file", "contents");
$repo->svn_commit("Initial commit");

$repo->svn_overwrite_file("file", "Contents");
$repo->svn_commit("Modify file");

$repo->svn_new_file("exec", "#!/bin/true");
$repo->svn_run(qw(svn propset svn:executable * exec));
$repo->svn_commit("Add executable file");	# This will "chmod +x exec" on POSIX systems

$repo->svn_run(qw(svn propdel svn:executable exec));
$repo->svn_commit("Remove executable bit");

$repo->svn_remove_file("exec");
$repo->svn_commit("Delete file");

my $white = "\x89\x50\x4e\x47\x0d\x0a\x1a\x0a\x00\x00\x00\x0d\x49\x48\x44\x52\x00\x00\x00\x01\x00\x00\x00\x01\x01\x03\x00\x00\x00\x25\xdb\x56\xca\x00\x00\x00\x03\x50\x4c\x54\x45\xff\xff\xff\xa7\xc4\x1b\xc8\x00\x00\x00\x0a\x49\x44\x41\x54\x08\xd7\x63\x60\x00\x00\x00\x02\x00\x01\xe2\x21\xbc\x33\x00\x00\x00\x00\x49\x45\x4e\x44\xae\x42\x60\x82";
my $black = "\x89\x50\x4e\x47\x0d\x0a\x1a\x0a\x00\x00\x00\x0d\x49\x48\x44\x52\x00\x00\x00\x01\x00\x00\x00\x01\x01\x03\x00\x00\x00\x25\xdb\x56\xca\x00\x00\x00\x03\x50\x4c\x54\x45\x00\x00\x00\xa7\x7a\x3d\xda\x00\x00\x00\x0a\x49\x44\x41\x54\x08\xd7\x63\x60\x00\x00\x00\x02\x00\x01\xe2\x21\xbc\x33\x00\x00\x00\x00\x49\x45\x4e\x44\xae\x42\x60\x82";

$repo->svn_new_file("pixel.png", $white);
$repo->svn_commit("Add binary file");

$repo->svn_overwrite_file("pixel.png", $black);
$repo->svn_commit("Modify binary file");

$repo->git_run(qw(git checkout -q git-svn));

{
	local $TODO_diff_only = 'Issue #32';
	test_repo($repo, [qw(-c 1)], "Added a text file");
	test_repo($repo, [qw(-c 2)], "Modified the text file");
}
{
	local $TODO_diff_only = 'SVN failing "A.2" & Issue #32';
	test_repo($repo, [qw(-c 3)], "Added executable file");
}
{
	local $TODO = 'SVN failings "A.2", "B": Mode changes unsupported by SVN';
	test_repo($repo, [qw(-c 4)], "Change file mode (remove executable bit)");
}
{
	local $TODO_diff_only = 'Issue #32';
	test_repo($repo, [qw(-r 2:4)], "Add non-executable file");
	test_repo($repo, [qw(-c 5)], "Deleted file");
}

SKIP: {
	skip "GIT binary patch not available before SVN v1.9", 4 if cmp_ver($svn_version, '1.9') < 0;
	test_repo($repo, [qw(-c 6)], "Add binary file");

	local $TODO_diff_only = 'SVN failing "D": Binary deltas unsupported by SVN';
	test_repo($repo, [qw(-c 7)], "Modify binary file");
}

SKIP: {
	eval { symlink("","") };
	skip "Symlinks not supported on this system", 2 if $@;

	my $link = $repo->svn_set_symlink("file", "link-to-file");
	skip "The system is creating fake symlinks", 2 if !-l $link;

	$repo->svn_run(qw(svn add link-to-file));
	$repo->svn_commit("Add symlink");
	$repo->git_run(qw(git checkout -q git-svn));

	local $TODO_diff_only = 'SVN failing "A.3" & Issue #32';
	test_repo($repo, [qw(-c 8)], "Add symlink");
}

exit;

sub test_repo {
	my ($repo, $args, $message) = @_;

	my @svn_args = ('--ignore-properties');
	@svn_args = () if cmp_ver($svn_version, '1.8') < 0;

	my ($got, $expected) = get_diff($repo, args => [@$args, '--git'], svn_args => \@svn_args, git_args => ['--binary']);

	# SVN failing "A.1": SVN actually gets the file mode wrong; in this
	# instance, git is the authority.  SVN diff will show regular files as
	# "10000" which, on POSIX.1-2008 compliant systems, represents a FIFO.  On
	# these systems, a regular file is "100000" (one extra "0").  Fix SVN since
	# it fails us, but note the modification in the output (so we could notice
	# if SVN fixes the issue).
	while ($expected =~ s/^([^-+@].*\bmode) 1(\d{4})$/$1 10$2/mg) {
		diag("Updated expected line to use correct POSIX file type: '$1': '1$2' → '10$2'");
	}

	# The "GIT binary patch" contains zlib compressed data encoded in base-85
	# (using non-standard character set), where each line is prefixed with a
	# letter indicated how long that line is.
	#
	# There is a minor difference between Git and SVN at the zlib layer. Git
	# chooses to use less/no compression and SVN uses the default.  This
	# difference changes the contents of the second byte in the zlib output,
	# but has no consequence on the compressed stream with these small
	# examples.  Because of the base-85 encoding, changing that one byte
	# affects the first 5 characters.
	#
	# This is a valid stylistic choice, so this test will need to work around
	# this insignificant difference.  To do that, change the SVN output to
	# match Git's.
	normalize_binary_diff(\$expected);
	normalize_binary_diff(\$got);	# Just in case Git changes algorithms.

	# SVN failing "C": The extra "index" annotation is not available in SVN,
	# but we have the data in git and that will cause the comparison to fail.
	# Strip off the index from the git-svn-diff output, but count how many
	# times we do that; there should be an index line for every file.
	my $index_count = $got =~ s/^index [0-9a-f]{6,40}\.\.[0-9a-f]{6,40}(?: [0-7]{5,6})?\n//mg;
	my $file_count = $got =~ m/^Index: /mg;
	cmp_ok($index_count, '==', $file_count, "$message: Correct number of 'index ...' lines from git-svn-diff");

	local $TODO = $TODO_diff_only if $TODO_diff_only;
	cmp_diff($got, $expected, $message);
}

sub normalize_binary_diff {
	my ($diff_ref) = @_;

	# Replace the 2nd byte of the zlib data (i.e. the compression level) to
	# normalize the contents.  As all files are small, the resulting output
	# should be valid zlib data.
	$$diff_ref =~ s{^((?:literal|delta) \d+\n.)(.{5})}{
		my $pre = $1;
		my $hex = decode_base85_block($2);
		$hex =~ s/^78../7801/;
		"$pre".encode_base85_block($hex);
	}emg;
}

sub BASE85 {
	'0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
	'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
	'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
	'U', 'V', 'W', 'X', 'Y', 'Z',
	'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
	'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't',
	'u', 'v', 'w', 'x', 'y', 'z',
	'!', '#', '$', '%', '&', '(', ')', '*', '+', '-',
	';', '<', '=', '>', '?', '@', '^', '_', '`', '{',
	'|', '}', '~'
}

sub encode_base85_block {
	my ($hex) = @_;

	my @lookup = BASE85();

	my $int = unpack 'N', pack 'H8', $hex;
	my $str;
	for (0..4) {
		$str .= $lookup[$int % 85];
		$int /= 85;
	}

    return scalar reverse $str;
}

sub decode_base85_block {
	my ($str) = @_;

	my $index = 0;
	my %lookup = map { $_ => $index++ } BASE85();

	my $int = 0;
	for (0..4) {
		my $char = substr $str, $_, 1;
		$int *= 85;
		$int += $lookup{$char};
	}

	return unpack 'H8', pack 'N', $int;
}
