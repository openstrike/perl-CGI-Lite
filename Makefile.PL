# $Id: Makefile.PL,v 1.2 2014/05/26 16:07:02 pete Exp $

use ExtUtils::MakeMaker;
use strict;
use warnings;
require 5.002;


my %MF = (
	NAME      =>   "CGI::Lite",
	ABSTRACT  =>   "Process and decode WWW forms and cookies",
	AUTHOR    =>   'Pete Houston (cpan@openstrike.co.uk)',
	BUILD_REQUIRES => {
		'Test::More'    => '0',
	},
	LICENSE         => 'perl',
	VERSION_FROM    => 'lib/CGI/Lite.pm',
   	'dist'    =>   {
		COMPRESS => 'gzip -9f', 
		SUFFIX   => 'gz'
   	}
);

if ($ExtUtils::MakeMaker::VERSION lt 6.55) { delete $MF{BUILD_REQUIRES}; }
if ($ExtUtils::MakeMaker::VERSION lt 6.31) { delete $MF{LICENSE};        }
WriteMakefile (%MF);

print <<End_of_Text;

Now do the following to install CGI::Lite:

    % make
    % make test
    % make install

End_of_Text
