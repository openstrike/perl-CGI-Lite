#
#===============================================================================
#
#         FILE:  forms.t
#
#  DESCRIPTION:  Test form-handling
#
#        FILES:  post_text.txt
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pete Houston (cpan@openstrike.co.uk)
#      COMPANY:  Openstrike
#      CREATED:  14/05/14 12:27:26
#
#  Updates:
#    25/08/2014 Now tests get_ordered_keys and print_data.
#===============================================================================

use strict;
use warnings;

use Test::More tests => 32;                      # last test to print

use lib './lib';

BEGIN { use_ok ('CGI::Lite') }

# Set up a CGI environment
$ENV{REQUEST_METHOD}  = 'GET';
$ENV{QUERY_STRING}    = 'game=chess&game=checkers&weather=dull';
$ENV{PATH_INFO}       = '/somewhere/else';
$ENV{PATH_TRANSLATED} = '/usr/local/somewhere/else';
$ENV{SCRIPT_NAME}     = '/cgi-bin/foo.cgi';
$ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
$ENV{SERVER_PORT}     = 8080;
$ENV{SERVER_NAME}     = 'the.good.ship.lollypop.com';

CGI::Lite->parse_form_data;

my $cgi   = CGI::Lite->new;
my $form  = $cgi->parse_form_data;

is ($cgi->is_error, 0, 'Parsing data with GET');
is ($form->{weather}, 'dull', 'Parsing scalar param with GET');
is (ref $form->{game}, 'ARRAY', 'Parsing array param with GET');
is ($form->{game}->[1], 'checkers', 'Extracting array param value with GET');

$ENV{QUERY_STRING}    =~ s/\&/;/g;
$form = $cgi->parse_new_form_data;

is ($cgi->is_error, 0, 'Parsing semicolon data with GET');
is ($form->{weather}, 'dull', 'Parsing semicolon scalar param with GET');
is (ref $form->{game}, 'ARRAY', 'Parsing semicolon array param with GET');
is ($form->{game}->[1], 'checkers', 'Extracting semicolon array param value with GET');

$ENV{QUERY_STRING}    = '&=&&foo=bar';
$form = $cgi->parse_new_form_data;

is ($cgi->is_error, 0, 'GET with missing kv pair');
is ($form->{foo}, 'bar', 'Value after GET with missing kv pair');

# Now with POSTed application/x-www-form-urlencoded
$ENV{REQUEST_METHOD}  = 'POST';
$ENV{QUERY_STRING}    = '';
my $datafile = 't/post_text.txt';

$ENV{CONTENT_LENGTH}  = (stat ($datafile))[7];
# Now what? Print to STDIN?
#

($cgi, $form) = post_data ($datafile);

is ($cgi->is_error, 0, 'Parsing data with POST');
is ($form->{bar}, 'quux', 'Parsing scalar param with POST');
is (ref $form->{foo}, 'ARRAY', 'Parsing array param with POST');
is ($form->{foo}->[1], 'baz', 'Extracting array param value with POST');

$ENV{CONTENT_TYPE} = 'baz';
($cgi, $form) = post_data ($datafile);
is ($cgi->is_error, 1, 'Invalid content type with POST');
is ($cgi->get_error_message, 'Invalid content type!', 'Invalid content type message with POST');

$ENV{CONTENT_TYPE} = 'application/x-www-form-urlencoded';
($cgi, $form) = post_data ($datafile);
is ($cgi->is_error, 0, 'Content type x-www-form-urlencoded with POST');

$ENV{CONTENT_TYPE} = 'application/x-www-form-urlencoded; charset=UTF-8';
($cgi, $form) = post_data ($datafile);
is ($cgi->is_error, 0, 'Content type x-www-form-urlencoded and charset with POST');
is ($form->{bar}, 'quux', 'Scalar param with POST as x-www-form-urlencoded');
is (ref $form->{foo}, 'ARRAY', 'Parsing array param with POST as x-www-form-urlencoded');
is ($form->{foo}->[1], 'baz', 'Extracting array param value with POST as x-www-form-urlencoded');

my $ref = [];
$ref = $cgi->get_ordered_keys;
is_deeply ($ref, ['foo', 'bar', 'notused'], 
	'get_ordered_keys arrayref for form data');
my @ref = $cgi->get_ordered_keys;
is_deeply (\@ref, ['foo', 'bar', 'notused'], 
	'get_ordered_keys array for form data');

SKIP: {
	skip "No file created for stdout", 3 unless open my $tmp, '>', 'tmpout';
	select $tmp;
	$cgi->print_data;
	close $tmp;
	open $tmp, '<', 'tmpout';
	chomp (my $printed = <$tmp>);
	is ($printed, q#foo = bar baz#, 'print_data double value');
	chomp ($printed = <$tmp>);
	is ($printed, q#bar = quux#, 'print_data single value');
	chomp ($printed = <$tmp>);
	is ($printed, q#notused = #, 'print_data no value');
	close $tmp and unlink 'tmpout';
}

($cgi, $form) = post_data ($datafile, 20);
is ($cgi->is_error, 1, 'Posted data larger than specified limit');

is ($cgi->set_size_limit ('alpha'), -1, 'Non-numeric size limit trapped');
is ($cgi->set_size_limit (10.537), -1, 'Non-integer size limit trapped');
is ($cgi->set_size_limit (-500), -1, 'Non-integer size limit trapped');
is ($cgi->set_size_limit (0), 0, 'Zero size limit accepted');

sub post_data {
	my ($datafile, $size_limit) = @_;
    local *STDIN;
	open STDIN, '<', $datafile
		or die "Cannot open test file $datafile: $!";
	binmode STDIN;
	my $cgi = CGI::Lite->new;
	$cgi->set_size_limit($size_limit) if defined $size_limit;
	my $form = $cgi->parse_form_data;
	close STDIN;
	return ($cgi, $form);
}
