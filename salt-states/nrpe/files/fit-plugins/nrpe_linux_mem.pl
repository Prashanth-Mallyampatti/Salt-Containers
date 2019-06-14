#! /usr/bin/perl -w
#
#  $URL: http://fcil01v140.fci.internal/svn/Nagios-Plugins/plugins/nrpe_scripts/nrpe_linux_mem.pl $
#  $Rev: 311 $
#   $Id: nrpe_linux_mem.pl 311 2017-02-13 13:15:05Z itvolla $
#
#  File: nrpe_linux_mem.pl
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
my $vmem  = 'mem';

my @aerr = ( "OK", "WARNING", "CRITICAL", "UNKNOWN", "DEPENDENT");
my $terr = 0;
my ( $stmp, @atmp, %htmp, %stat );

###  function  #################################################################
#

##  usage message  ##
sub usage {
    print "Usage: $0 [-h] -f mem -w <warn level> -c <critical level>\n";
}

##  help message  ##
sub help {
    print "\n";
    print "Usage: $0 [-h] -f mem -w <warn level> -c <critical level>\n";
    print "\t-h,  print this help message\n";
    print "\t-f,  diverse memories ( mem = physcal(include cache+buffer) , page = swap , cache = only cached+buffers)\n";
    print "\t-w,  warning level for volume used in percentage\n";
    print "\t-c,  critical level for volume used in percentage\n";
    print "\n";
}

##  check options  ##
sub check_options {
    Getopt::Long::Configure ("bundling");
    GetOptions( 'h' => \$vhelp, 'f:s' => \$vmem, 'w:s' => \$vwarn, 'c:s' => \$vcrit );

    if ( defined( $vhelp )) { 
	help(); 
	exit $ERRORS{$aerr[3]}
    };

    if ( ! grep( /^$vmem$/,("mem", "page" , "cache"))) {
	help();
	exit $ERRORS{$aerr[3]};
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


## free -k
##              total       used       free     shared    buffers     cached
## Mem:       8196008    5707996    2488012          0     276988    2511320
## -/+ buffers/cache:    2919688    5276320
## Swap:      8393648          0    8393648

if ( -f '/usr/bin/free' ) {

    my @atmp = `/usr/bin/free -k` ;
    foreach $stmp ( @atmp ) {
	chomp $stmp;
	if ( $stmp !~ /:/ ) { 
	    next; 
	}

	my @atmp1 = split(" ", $stmp );
	if ( $atmp1[0] =~ /[Mm]em:/ ) {
	    $stat{'mem'}{'size'} = $atmp1[1];
	    $stat{'mem'}{'used'} = $atmp1[2];
	    $stat{'mem'}{'buff'} = $atmp1[5];
	    $stat{'mem'}{'cach'} = $atmp1[6];	    
	}
	if ( $atmp1[0] =~ /[Ss]wap:/ ) {
	    $stat{'swap'}{'size'} = $atmp1[1];
	    $stat{'swap'}{'used'} = $atmp1[2];
	}
    }
}

if ( $vmem =~ /page/ ) {

    $stmp = sprintf("%.2f", $stat{'swap'}{'used'} / $stat{'swap'}{'size'} * 100 );
    if ( $stmp >= $vcrit ) { $terr = 2; }
    elsif ( $stmp >= $vwarn ) { $terr = 1; }
    print $aerr[$terr]." - ".$stmp."% paging |";
    print " 'swap size'=".$stat{'swap'}{'size'}."kb;;;;";
    print " 'swap used'=".$stat{'swap'}{'used'}."kb;;;;";
    print " 'swap free'=".($stat{'swap'}{'size'} - $stat{'swap'}{'used'})."kb;;;;";
    print " 'swap used%'=".$stmp."%;;;;\n";

} elsif ( $vmem =~ /cache/ ) {

    $stmp = sprintf("%.2f", ( $stat{'mem'}{'buff'} + $stat{'mem'}{'cach'}) / $stat{'mem'}{'size'} * 100 );
    if ( $stmp >= $vcrit ) { $terr = 2; }
    elsif ( $stmp >= $vwarn ) { $terr = 1; }
    print $aerr[$terr]." - ".$stmp."% cache |";
    print " 'cache size'=".$stat{'mem'}{'size'}."kb;;;;";
    print " 'cache used'=".( $stat{'mem'}{'buff'} + $stat{'mem'}{'cach'} )."kb;;;;";
    print " 'cache free'=".($stat{'mem'}{'size'} - ( $stat{'mem'}{'buff'} + $stat{'mem'}{'cach'} ))."kb;;;;";
    print " 'cache used%'=".$stmp."%;;;;\n";

} else {

    

    $stmp = sprintf("%.2f", $stat{'mem'}{'used'} / $stat{'mem'}{'size'} * 100 );
    if ( $stmp >= $vcrit ) { $terr = 2; }
    elsif ( $stmp >= $vwarn ) { $terr = 1; }
    print $aerr[$terr]." - ".$stmp."% memory |";
    print " 'memory size'=".$stat{'mem'}{'size'}."kb;;;;";
    print " 'memory used'=".$stat{'mem'}{'used'}."kb;;;;";
    print " 'memory free'=".($stat{'mem'}{'size'} - $stat{'mem'}{'used'})."kb;;;;";
    print " 'cache used'=".$stat{'mem'}{'cach'}."kb;;;;";
    print " 'buffer used'=".$stat{'mem'}{'buff'}."kb;;;;";
    print " 'memory used%'=".$stmp."%;;;;\n";

}

exit $ERRORS{$aerr[$terr]};

