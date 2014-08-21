#
#===============================================================================
#
#         FILE:  basic.t
#
#  DESCRIPTION:  Test of the most basic functionality
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pete Houston (cpan@openstrike.co.uk)
#      COMPANY:  Openstrike
#      VERSION:  $Id: basic.t,v 1.4 2014/07/04 11:26:03 pete Exp $
#      CREATED:  13/05/14 21:36:53
#     REVISION:  $Revision: 1.4 $
#
#  Updates:
#    21/08/2014 Now tests set_platform, wrap_textarea and get_error_message.
#===============================================================================

use strict;
use warnings;

use Test::More tests => 302;                      # last test to print

use lib './lib';

BEGIN { use_ok ('CGI::Lite') }

is ($CGI::Lite::VERSION, '2.04', 'Version test');
is (CGI::Lite::Version (), $CGI::Lite::VERSION, 'Version subroutine test');

my $cgi = CGI::Lite->new ();

is (ref $cgi, 'CGI::Lite', 'New');

is (browser_escape ('<&>'), '&#60;&#38;&#62;', 'browser_escape');

{
	no warnings 'qw';
	my @from = qw/! " # $ % ^ & * ( ) _ + - =/;
	my @to   = qw/%21 %22 %23 %24 %25 %5E %26 %2A %28 %29 _ %2B - %3D/;

	for my $i (0..$#from) {
		is (url_encode($from[$i]), $to[$i], "url_encode $from[$i]");
		is (url_decode($to[$i]), $from[$i], "url_decode $to[$i]");
	}
}

my $dangerous = ';<>*|`&$!#()[]{}:\'"';

for my $i(0..255) {
	my $chr = chr($i);
	if (index ($dangerous, $chr) eq -1) {
		# Not
		is (is_dangerous ($chr), 0, "Dangerous $i (not)");
	} else {
		is (is_dangerous ($chr), 1, "Dangerous $i");
	}
}

for my $platform (qw/WINdows WINdows95 dos nt pc/) {
	$cgi->set_platform ($platform);
	is ($cgi->{platform}, 'PC', "Set platform ($platform)");
}
for my $platform (qw/mac MacIntosh/) {
	$cgi->set_platform ($platform);
	is ($cgi->{platform}, 'Mac', "Set platform ($platform)");
}
# Unix is default
$cgi->set_platform ('foo');
is ($cgi->{platform}, 'Unix', "Set default platform");

my $longstr = '123 456 789 0123456 7 89 0';
is ($cgi->wrap_textarea ($longstr, 5), "123\n456\n789\n0123456\n7 89\n0",
	"wrap_textarea Unix");
$cgi->set_platform ("DOS");
is ($cgi->wrap_textarea ($longstr, 5), "123\r\n456\r\n789\r\n0123456\r\n7 89\r\n0",
	"wrap_textarea DOS");
$cgi->set_platform ("Mac");
is ($cgi->wrap_textarea ($longstr, 5), "123\r456\r789\r0123456\r7 89\r0",
	"wrap_textarea Mac");

is ($cgi->is_error(), 0, 'No errors');
is ($cgi->get_error_message, undef, 'No error message');
