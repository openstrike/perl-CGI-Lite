#
#===============================================================================
#
#         FILE:  uploads.t
#
#  DESCRIPTION:  Test of multipart/form-data uploads
#
#        FILES:  good_upload.txt
#         BUGS:  ---
#        NOTES:  This borrows very heavily from upload.t in CGI.pm
#       AUTHOR:  Pete Houston (cpan@openstrike.co.uk)
#      COMPANY:  Openstrike
#      VERSION:  $Id: uploads.t,v 1.3 2014/06/17 14:04:13 pete Exp $
#      CREATED:  20/05/14 14:01:34
#     REVISION:  $Revision: 1.3 $
#===============================================================================

use strict;
use warnings;

use Test::More tests => 15;                      # last test to print

use lib './lib';

BEGIN { use_ok ('CGI::Lite') }

# Set up a CGI environment
$ENV{REQUEST_METHOD}  = 'POST';
$ENV{PATH_INFO}       = '/somewhere/else';
$ENV{PATH_TRANSLATED} = '/usr/local/somewhere/else';
$ENV{SCRIPT_NAME}     ='/cgi-bin/foo.cgi';
$ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
$ENV{SERVER_PORT}     = 8080;
$ENV{SERVER_NAME}     = 'there.is.no.try.com';
$ENV{QUERY_STRING}    = '';
my $datafile          = 't/good_upload.txt';
$ENV{CONTENT_LENGTH}  = (stat ($datafile))[7];
$ENV{CONTENT_TYPE}    = q#multipart/form-data; boundary=`!"$%^&*()-+[]{}'@.?~\#|aaa#;

my $uploaddir = 'tmpcgilite';
mkdir $uploaddir unless -d $uploaddir;


my ($cgi, $form) = post_data ($datafile, $uploaddir);

is ($cgi->is_error, 0, 'Parsing data with POST');
like ($form->{'does_not_exist_gif'}, qr/[0-9]+__does_not_exist\.gif/, 'Second file');
like ($form->{'100;100_gif'}, qr/[0-9]+__100;100\.gif/, 'Third file');
like ($form->{'300x300_gif'}, qr/[0-9]+__300x300\.gif/, 'Fourth file');

# XXX Duplicate field names for files do NOT work currently. Fix this
# and then implement some tests.

my @files = qw/does_not_exist_gif 100;100_gif 300x300_gif/;
my @sizes = qw/0 896 1656/;
for my $i (0..2) {
	my $file = "$uploaddir/$form->{$files[$i]}";
	ok (-e "$file", "Uploaded file exists ($i)") or warn "Name = '$file'\n" . $cgi->get_error_message;
	is ((stat($file))[7], $sizes[$i], "File size check ($i)") or
		warn_tail ($file);
}

is ($cgi->set_directory ('/srhslgvsgnlsenhglsgslvngh'), 0,
	'Set directory (non-existant)');
my $testdir = 'testperms';
mkdir $testdir, 0400;
SKIP: {
	skip "subdir '$testdir' could not be created", 3 unless (-d $testdir);

	is ($cgi->set_directory ($testdir), 0, 'Set directory (unwriteable)');
	chmod 0200, $testdir;
	is ($cgi->set_directory ($testdir), 0, 'Set directory (unreadable)');
	rmdir $testdir and open my $td, '>', $testdir;
	print $td "Test\n";
	close $td;
	is ($cgi->set_directory ($testdir), 0, 'Set directory (non-directory)');
	unlink $testdir;
}




sub post_data {
	my ($datafile, $dir) = @_;
	local *STDIN;
	open STDIN, '<', $datafile
		or die "Cannot open test file $datafile: $!";
	binmode STDIN;
	my $cgi = CGI::Lite->new;
	$cgi->set_platform ('DOS') if $^O eq 'MSWin32';
	$cgi->set_directory ($dir);
	my $form = $cgi->parse_form_data;
	close STDIN;
	return ($cgi, $form);
}

sub warn_tail {
	# If there's a size mismatch on the uploaded files, dump the end of
	# the file here. Ideally this should never be called.
	my $file = shift;
	my $n    = 32;
	open (my $in, '<', $file) or die "Cannot open $file for reading.  $!";
	binmode $in;
	local $/ = undef;
	my $contents = <$in>;
	close $file;
	my $lastn = substr ($contents, 0 - $n);
	foreach (split (//, $lastn, $n)) {
		print $n-- . " chars from the end: " . ord ($_) . "\n";
	}
}
