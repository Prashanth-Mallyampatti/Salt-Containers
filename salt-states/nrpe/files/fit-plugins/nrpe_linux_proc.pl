#! /usr/bin/perl -w
#
#  $URL: http://fcil01v140.fci.internal/svn/Nagios-Plugins/plugins/nrpe_scripts/nrpe_linux_proc.pl $
#  $Rev: 224 $
#   $Id: nrpe_linux_proc.pl 224 2014-11-25 08:57:02Z itlangs $
#
#  File: nrpe_linux_proc.pl
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
my $vopts = undef;
my %ret ;

my @aerr = ( "OK", "WARNING", "CRITICAL", "UNKNOWN", "DEPENDENT");
my $terr = 3;
my ( $stmp, @atmp, %htmp, %stat );
my @VOPTS;

###  function  #################################################################
#

##  usage message  ##
sub usage {
    print "Usage: $0 -f <proc[,proc,..]> -w <0|1> -c <0|1>\n";
}

##  help message  ##
sub help {
    print "\n";
    print "Usage: $0 -f <proc[,proc,..]> -w <0|1> -c <0|1>\n";
    print "\t-h,  print this help message\n";
    print "\t-f,  process or list of process\n";
    print "\t-w,  1 = warning process not found \n";
    print "\t-c,  1 = critical process not found \n";
    print "\n";
}

##  check options  ##
sub check_options {
    Getopt::Long::Configure ("bundling");
    GetOptions( 'h' => \$vhelp, 'f:s' => \$vopts, 'w:s' => \$vwarn, 'c:s' => \$vcrit );

    if ( defined( $vhelp )) { 
	help(); 
	exit $ERRORS{$aerr[3]}
    }

    if ( ! defined( $vopts) || $vopts eq '' ) {
	usage();
	exit $ERRORS{$aerr[3]};
    }

    if ( $vopts =~ /,/ ) {
	@VOPTS = split(',', $vopts);
    } else {
	push @VOPTS, $vopts;
    }
    
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

## ps aux
## USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
## root         1  0.0  0.0  10376   784 ?        Ss    2013   1:04 init [3]  
## root         2  0.0  0.0      0     0 ?        S     2013   0:00 [kthreadd]
## root         3  0.0  0.0      0     0 ?        S     2013   0:11 [migration/0]
## root         4  0.0  0.0      0     0 ?        S     2013   0:11 [ksoftirqd/0]
## root         5  0.0  0.0      0     0 ?        S     2013   0:14 [migration/1]
## root         6  0.0  0.0      0     0 ?        S     2013   0:04 [ksoftirqd/1]
## root         7  0.0  0.0      0     0 ?        S     2013   0:12 [migration/2]
## root         8  0.0  0.0      0     0 ?        S     2013   0:05 [ksoftirqd/2]
##

if ( -f '/bin/ps' ) {

    my @atmp = `/bin/ps -eo pid,cmd` ;
    foreach $stmp ( @atmp ) {
        chomp $stmp;
        if ( $stmp =~ /^USER/ ) { next; }

        my @atmp1 = split(" ", $stmp );
	if ( $#atmp1 > 1 ) {
	    for ( my $i = 2; $i <= $#atmp1; $i++ ) {
		$atmp1[1] .= " ".$atmp1[$i];
	    }
	}
	$stat{$atmp1[0]} = $atmp1[1];
    }
}

foreach $stmp ( @VOPTS ) { $htmp{$stmp} = 1; }

foreach $stmp ( keys %stat ) {
    if ( $stat{$stmp} =~ /$0/ ) { next; }
    foreach my $stmp1 ( @VOPTS ) {
	if ( $stat{$stmp} =~ /$stmp1/ ) {
	    delete $htmp{$stmp1} ;
	    $ret{$stmp} = $stat{$stmp};
	}
    }
}

if(  scalar(keys %htmp) == 0 ) { $terr = 0; }
if ( $terr != 0 ) {
    if ( $vcrit ) { $terr = 2; }
    elsif ( $vwarn ) { $terr = 1; }
}

print $aerr[$terr]." - ";
if ( $terr != 0 ) { 
    foreach $stmp ( keys %htmp ) {
	print $stmp." ";
    }
    print "not running \n"; 
} else { 
    print $vopts." running \n"; 
}

foreach $stmp ( keys %ret ) {
    print $stmp." ".$ret{$stmp}."\n";
}

exit $ERRORS{$aerr[$terr]};
