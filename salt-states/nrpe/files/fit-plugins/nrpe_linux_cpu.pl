#! /usr/bin/perl -w
#
#  $URL: http://fcil01v140.fci.internal/svn/Nagios-Plugins/plugins/nrpe_scripts/nrpe_linux_cpu.pl $
#  $Rev: 316 $
#   $Id: nrpe_linux_cpu.pl 316 2017-03-09 15:36:45Z itlangs $
#
#  File: nrpe_linux_cpu.pl
#    OS: Linux (nagios)
#
#
################################################################################
use strict;
use warnings;
use Getopt::Long;
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

###  function  #################################################################
#

##  usage message  ##
sub usage {
    print "Usage: $0 [-h] -w <warn level> -c <critical level>\n";
}

##  help message  ##
sub help {
    print "\n";
    print "Usage: $0 [-h] -w <warn level> -c <critical level>\n";
    print "\t-h,  print this help message\n";
    print "\t-w,  warning level in percentage\n";
    print "\t-c,  critical level in percentage\n";
    print "\n";
}

##  check options  ##
sub check_options {
    Getopt::Long::Configure ("bundling");
    GetOptions( 'h' => \$vhelp, 'w:s' => \$vwarn, 'c:s' => \$vcrit );

    if ( defined( $vhelp )) { 
	help(); 
	exit $ERRORS{$aerr[3]}
    };

    if ( ! defined( $vwarn ) || ! defined( $vcrit )) {
	print "Put warning and critical values!\n";
	usage();
	exit $ERRORS{$aerr[3]};
    }
    
    $vwarn =~ s/\%//g;
    $vcrit =~ s/\%//g;
    if ( &isnnum( $vwarn ) || &isnnum( $vcrit )) {
	print "Numeric value for warning or critical !\n";
	usage();
	exit $ERRORS{$aerr[3]};
    }
    if (( $vcrit != 0 ) && ( $vwarn > $vcrit )) {
	print "warning <= critical ! \n";
	usage();
	exit $ERRORS{$aerr[3]};
    }
}

##  is a number  ##
sub isnnum { # Return true if arg is not a number
  my $num = shift;
  if ( $num =~ /^(\d+\.?\d*)|(^\.\d+)$/ ) { return 0 ;}
  return 1;
}

###   main   ###################################################################
#

check_options();

## /usr/bin/iostat -c
## Linux 3.8-trunk-amd64 (jasmin) 	15.01.2014 	_x86_64_	(4 CPU)
##
## avg-cpu:  %user   %nice %system %iowait  %steal   %idle
##            4,21   88,44    1,91    0,13    0,00    5,31
##

if ( -f '/usr/bin/iostat' ) {

#    my @atmp = `/usr/bin/iostat -c` ;
    my @atmp = `/usr/bin/iostat -c  1 2 | tail -2 | head -1` ;
    foreach $stmp ( @atmp ) {
	chomp $stmp;
	if ( $stmp eq "" ||  $stmp =~ /^Linux/ || $stmp =~ /^avg-cpu:/ ) { 
	    next; 
	}
	$stmp =~ s/,/./g ;
	my @atmp1 = split(" ", $stmp );
	$stat{user}   = $atmp1[0];
	$stat{nice}   = $atmp1[1];
	$stat{system} = $atmp1[2];
	$stat{iowait} = $atmp1[3];
	$stat{steal}  = $atmp1[4];
	$stat{idle}   = $atmp1[5];
    }
}

$stmp = sprintf("%.2f", 100 - $stat{idle});
if ( $stmp >= $vcrit ) { $terr = 2; }
elsif ( $stmp >= $vwarn ) { $terr = 1; }

print $aerr[$terr]." - ".$stmp."% usage|";
print "'user'=".$stat{user}."%;;;; 'nice'=".$stat{nice}."%;;;; 'system'=";
print $stat{system}."%;;;; 'idle'=".$stat{idle}."%;;;; 'iowait'=".$stat{iowait}."%;;;; \n";

exit $ERRORS{$aerr[$terr]};

