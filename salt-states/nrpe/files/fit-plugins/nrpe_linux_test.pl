#! /usr/bin/perl -w
#
#  $URL: svn://subversion.eu.fit/nagios/plugins/nrpe/nrpe_linux_test.pl $
#  $Rev: 219 $
#   $Id: nrpe_linux_test.pl 219 2014-02-26 07:19:10Z itlangs $
#
#  File: nrpe_linux_cpu.pl
#    OS: Linux (nagios)
#
#
################################################################################
use strict;
use warnings;
use Getopt::Long;
use Sys::Syslog qw( :DEFAULT setlogsock);
use POSIX;

use FindBin;
use lib "$FindBin::Bin";

##  nagios stuff  ##
use utils qw(%ERRORS $TIMEOUT);

##  defined variables  ##
my $debug = 0;
my $vhelp = undef;
my $vwarn = undef;
my $vcrit = undef;

my @aerr = ( "OK", "WARNING", "CRITICAL", "UNKNOWN", "DEPENDENT");
my $terr = 0;
my ( $stmp, @atmp, %htmp, %stat );

setlogsock('unix');
openlog( $0, '', 'user');
syslog('info', "run it");
closelog;

print $aerr[0]." run|\n";
exit $ERRORS{$aerr[$terr]};

