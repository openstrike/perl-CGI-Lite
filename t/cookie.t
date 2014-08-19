#
#===============================================================================
#
#         FILE:  cookie.t
#
#  DESCRIPTION:  Test of cookie parsing
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pete Houston (cpan@openstrike.co.uk)
#      COMPANY:  Openstrike
#      VERSION:  $Id: cookie.t,v 1.1 2014/05/26 15:40:15 pete Exp $
#      CREATED:  20/05/14 16:12:33
#     REVISION:  $Revision: 1.1 $
#===============================================================================

use strict;
use warnings;

use Test::More tests => 231;                      # last test to print

use lib './lib';

BEGIN { use_ok ('CGI::Lite') }

# Set up a CGI environment
$ENV{REQUEST_METHOD}  = 'GET';
$ENV{PATH_INFO}       = '/somewhere/else';
$ENV{PATH_TRANSLATED} = '/usr/local/somewhere/else';
$ENV{SCRIPT_NAME}     ='/cgi-bin/foo.cgi';
$ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
$ENV{SERVER_PORT}     = 8080;
$ENV{SERVER_NAME}     = 'there.is.no.try.com';
$ENV{QUERY_STRING}    = '';

$ENV{HTTP_COOKIE}     = 'foo=bar; baz=quux';
my $cgi               = CGI::Lite->new ();
my $cookies           = $cgi->parse_cookies;
my $testname          = 'simple';

is ($cgi->is_error, 0, "Cookie parse ($testname)");
is (scalar keys %$cookies, 2, "Cookie count ($testname)");
ok (exists $cookies->{foo}, "First cookie name ($testname)");
is ($cookies->{foo}, 'bar', "First cookie value ($testname)");
ok (exists $cookies->{baz}, "Second cookie name ($testname)");
is ($cookies->{baz}, 'quux', "Second cookie value ($testname)");



$ENV{HTTP_COOKIE}     = ' foo=bar ; baz = quux ';
$cgi                  = CGI::Lite->new ();
$cookies              = $cgi->parse_cookies;
$testname             = 'extra space';

is ($cgi->is_error, 0, "Cookie parse ($testname)");
is (scalar keys %$cookies, 2, "Cookie count ($testname)");
ok (exists $cookies->{foo}, "First cookie name ($testname)");
is ($cookies->{foo}, 'bar', "First cookie value ($testname)");
ok (exists $cookies->{baz}, "Second cookie name ($testname)");
is ($cookies->{baz}, 'quux', "Second cookie value ($testname)");

$ENV{HTTP_COOKIE}     = 'foo=bar;baz=quux';
$cgi                  = CGI::Lite->new ();
$cookies              = $cgi->parse_cookies;
$testname             = 'zero space';

is ($cgi->is_error, 0, "Cookie parse ($testname)");
is (scalar keys %$cookies, 2, "Cookie count ($testname)");
ok (exists $cookies->{foo}, "First cookie name ($testname)");
is ($cookies->{foo}, 'bar', "First cookie value ($testname)");
ok (exists $cookies->{baz}, "Second cookie name ($testname)");
is ($cookies->{baz}, 'quux', "Second cookie value ($testname)");

$ENV{HTTP_COOKIE}     = '%20foo%20=%20bar%20;b%20a%20z=qu%20ux';
$cgi                  = CGI::Lite->new ();
$cookies              = $cgi->parse_cookies;
$testname             = 'interstitial space';

is ($cgi->is_error, 0, "Cookie parse ($testname)");
is (scalar keys %$cookies, 2, "Cookie count ($testname)");
ok (exists $cookies->{' foo '}, "First cookie name ($testname)");
is ($cookies->{' foo '}, ' bar ', "First cookie value ($testname)");
ok (exists $cookies->{'b a z'}, "Second cookie name ($testname)");
is ($cookies->{'b a z'}, 'qu ux', "Second cookie value ($testname)");

# Other url-escaped chars here

for my $special (33 .. 47, 58 .. 64, 91 .. 96, 123 .. 126) {
	$ENV{HTTP_COOKIE}     = sprintf 'a=%%%X;%%%X=1', $special, $special;
	$cgi                  = CGI::Lite->new ();
	$cookies              = $cgi->parse_cookies;
	$testname             = "Special value ($ENV{HTTP_COOKIE})";
	is ($cgi->is_error, 0, "Cookie parse ($testname)");
	is (scalar keys %$cookies, 2, "Cookie count ($testname)");
	ok (exists $cookies->{'a'}, "First cookie name ($testname)");
	is ($cookies->{'a'}, chr($special), "First cookie value ($testname)");
	ok (exists $cookies->{chr($special)}, "Second cookie name ($testname)");
	is ($cookies->{chr($special)}, 1, "Second cookie value ($testname)");
}

$ENV{HTTP_COOKIE}     = '=bar';
$cgi                  = CGI::Lite->new ();
$cookies              = $cgi->parse_cookies;
$testname             = 'Missing key';

is ($cgi->is_error, 0, "Cookie parse ($testname)");
is (scalar keys %$cookies, 1, "Cookie count ($testname)");
ok (exists $cookies->{''}, "First cookie name ($testname)");
is ($cookies->{''}, 'bar', "First cookie value ($testname)");

# Bad cookies!

$ENV{HTTP_COOKIE}     = 'f;o;o=b;a;r';
$cgi                  = CGI::Lite->new ();
$cookies              = $cgi->parse_cookies;
$testname             = 'Extra semicolons';

is ($cgi->is_error, 0, "Cookie parse ($testname)");
is (scalar keys %$cookies, 4, "Cookie count ($testname)");
ok (exists $cookies->{'o'}, "First cookie name ($testname)");
is (ref $cookies->{'o'}, 'ARRAY', "First cookie ref ($testname)");
is ($cookies->{'o'}->[0], '', "First cookie first elem ($testname)");
is ($cookies->{'o'}->[1], 'b', "First cookie second elem ($testname)");

$ENV{HTTP_COOKIE}     = 'foo==bar';
$cgi                  = CGI::Lite->new ();
$cookies              = $cgi->parse_cookies;
$testname             = 'Extra equals';

is ($cgi->is_error, 0, "Cookie parse ($testname)");
is (scalar keys %$cookies, 1, "Cookie count ($testname)");
ok (exists $cookies->{'foo'}, "First cookie name ($testname)");
is ($cookies->{'foo'}, '=bar', "First cookie value ($testname)");

# Need to decide how strict the cookie validation should be. If strict,
# then these tests could be used. Leaving it lax for now.
# See eg. http://bugs.python.org/issue2193
#
#for my $char (split (//, '()<>@:\"/[]?={} ')) {
#
#	$ENV{HTTP_COOKIE}     = "f${char}o=bar";
#	$cgi                  = CGI::Lite->new ();
#	$cookies              = $cgi->parse_cookies;
#	$testname             = qq#Bad key char: "$char"#;
#
#	is ($cgi->is_error, 1, "Cookie parse ($testname)");
#	is (scalar keys %$cookies, 0, "Cookie count ($testname)");
#
#	$ENV{HTTP_COOKIE}     = "foo=b${char}r";
#	$cgi                  = CGI::Lite->new ();
#	$cookies              = $cgi->parse_cookies;
#	$testname             = qq#Bad value char: "$char"#;
#
#	is ($cgi->is_error, 1, "Cookie parse ($testname)");
#	is (scalar keys %$cookies, 0, "Cookie count ($testname)");
#
#}
#
# What about multiple cookies with the same name?
# cookie o is actually an arrayref, which is neat, but does it match the
# RFC?
#ok (exists $cookies->{'b a z'}, "Second cookie name ($testname)");
#is ($cookies->{'b a z'}, 'qu ux', "Second cookie value ($testname)");
