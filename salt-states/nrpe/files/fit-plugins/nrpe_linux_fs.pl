#! /usr/bin/perl -w
#
#  $URL: http://fcil01v140.fci.internal/svn/Nagios-Plugins/plugins/nrpe_scripts/nrpe_linux_fs.pl $
#  $Rev: 465 $
#   $Id: nrpe_linux_fs.pl 465 2018-02-21 07:49:07Z itvolla $
#
#  File: nrpe_linux_fs.pl
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
my $vfs   = undef;

my @aerr = ( "OK", "WARNING", "CRITICAL", "UNKNOWN", "DEPENDENT");
my $terr = 0;
my ( $stmp, @atmp, %htmp, %stat );

###  function  #################################################################
#

##  usage message  ##
sub usage {
    print "Usage: $0 [-h] -f filesystem -w <warn level> -c <critical level>\n";
}

##  help message  ##
sub help {
    print "\n";
    print "Usage: $0 [-h] -f filesystem -w <warn level> -c <critical level>\n";
    print "\t-h,  print this help message\n";
    print "\t-f,  mount point of filesetem\n";
    print "\t-w,  warning level for volume used in percentage\n";
    print "\t-c,  critical level for volume used in percentage\n";
    print "\n";
}

##  check options  ##
sub check_options {
    Getopt::Long::Configure ("bundling");
    GetOptions( 'h' => \$vhelp, 'f:s' => \$vfs, 'w:s' => \$vwarn, 'c:s' => \$vcrit );

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

## /bin/df -k -t ext2 -t reiserfs
## Dateisystem          1K‐Blöcke   Benutzt Verfügbar Ben% Eingehängt auf
## /dev/mapper/rootvg-lvroot
##                         655336    256028    399308  40% /
## /dev/sda1               263453     18977    230872   8% /boot
## /dev/mapper/rootvg-lvopt
##                       14089804    304160  13785644   3% /opt
## /dev/mapper/rootvg-lvsrv
##                        1114072    915212    198860  83% /srv
## /dev/mapper/rootvg-lvtmp
##                         524268     50952    473316  10% /tmp
## /dev/mapper/rootvg-lvusr
##                        2621356   2002756    618600  77% /usr
## /dev/mapper/rootvg-lvvar
##                        1376208    986988    389220  72% /var
## /dev/mapper/rootvg-lvtivoli
##                         196596     85600    110996  44% /opt/tivoli
## /dev/mapper/rootvg-lvull
##                         262132     33580    228552  13% /usr/local/log
## /dev/mapper/sawmill_vg-lvsawmill
##                       21716324  15516488   6199836  72% /opt/sawmill
## /dev/mapper/sawmill_vg-lv_home_exp
##                       10485436     33328  10452108   1% /exports/home

if ( -f '/bin/df' ) {

#    my @atmp = `/usr/bin/sudo df -t ext2 -t ext3 -t ext4 -t reiserfs -t xfs` ;
	my @atmp = `df -t ext2 -t ext3 -t ext4 -t reiserfs -t xfs $vfs 2>&1` ;
	if ($?) {
		@atmp = `/usr/bin/sudo df -t ext2 -t ext3 -t ext4 -t reiserfs -t xfs $vfs` ;
	}
    foreach $stmp ( @atmp ) {
	chomp $stmp;
	if ( $stmp eq "" ) { next; }
	my @atmp1 = split(" ", $stmp );
	if ( $#atmp1 != 4 && $#atmp1 != 5 ) { next ; }
	$stat{$atmp1[-1]}{'size'}   = $atmp1[-5];
	$stat{$atmp1[-1]}{'used'}  = $atmp1[-4];
	$stat{$atmp1[-1]}{'free'}   = $atmp1[-3];
	$stat{$atmp1[-1]}{'pused'} = $atmp1[-2];
	$stat{$atmp1[-1]}{'pused'} =~ s/\%//g;

    }
}


if ( defined $vfs ) {
    if ( grep ( /^$vfs$/, keys( %stat ))) {
	if ( $stat{$vfs}{'pused'} >= $vcrit ) { $terr = 2; }
	elsif ( $stat{$vfs}{'pused'} >= $vwarn ) { $terr = 1; }
	print $aerr[$terr]." - ".$stat{$vfs}{'pused'}."% ".$vfs." | ";
	print "'".$vfs." size'=".$stat{$vfs}{'size'}."kb;;;;";
	print " '".$vfs." used'=".$stat{$vfs}{'used'}."kb;;;;";
	print " '".$vfs." free'=".$stat{$vfs}{'free'}."kb;;;;";
	print " '".$vfs." used%'=".$stat{$vfs}{'pused'}."%;;;;\n";
    } else {
	print $aerr[3]." filesytem '".$vfs."' not found. |\n";
	exit $ERRORS{$aerr[3]};
    }
} else {
    my $int = 1;
    foreach $stmp ( sort{ $stat{$b}{'pused'} <=> $stat{$a}{'pused'}} keys %stat ) {
	if ( $int ) {
	    $int = 0;
	    if ( $stat{$stmp}{'pused'} >= $vcrit ) { $terr = 2; }
	    elsif ( $stat{$stmp}{'pused'} >= $vwarn ) { $terr = 1; }
	    print $aerr[$terr]." - ".$stat{$stmp}{'pused'}."% ".$stmp." | ";
	    print "'".$stmp." used%=".$stat{$stmp}{'pused'}."%;;;;";
	} else {
	    print "'".$stmp." used%=".$stat{$stmp}{'pused'}."%;;;;";
	}
    }
    print "\n";
}

exit $ERRORS{$aerr[$terr]};

