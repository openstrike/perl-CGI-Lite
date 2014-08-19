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
#===============================================================================

use strict;
use warnings;

use Test::More tests => 290;                      # last test to print

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

is ($cgi->is_error(), 0, 'No errors');
