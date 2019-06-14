#! /usr/bin/perl -w
#
#  $URL: svn://subversion.eu.fit/nagios/plugins/nrpe/nrpe_linux_sapfs.pl $
#  $Rev: 219 $
#   $Id: nrpe_linux_sapfs.pl 219 2014-02-26 07:19:10Z itlangs $
#
#  File: nrpe_linux_sapfs.pl
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
my $vopts = 'all';
my $ret   = '' ;

my %opts = ( 'binary' => '_V1', 'sapdata' => '_V2', 'COMM' => '_V3',
	     'origlog' => '_V4', 'mirrlog' => '_V5', 'oraarch' => '_V6' );

my @aerr = ( "OK", "WARNING", "CRITICAL", "UNKNOWN", "DEPENDENT");
my $terr = 3;
my ( $stmp, @atmp, %htmp, %stat );

###  function  #################################################################
#

##  usage message  ##
sub usage {
    print "Usage: $0 [-f <all|binary|sapdata|COMM|origlog|mirrlog|oraarch>] -w <warn level> -c <crit level>\n";
}

##  help message  ##
sub help {
    print "\n";
    print "Usage: $0 [-f <all|binary|sapdata|COMM|origlog|mirrlog|oraarch>] -w <warn level> -c <crit level>\n";
    print "\t-h,  print this help message\n";
    print "\t-f,  filesystems all|binary|sapdata|COMM|origlog|mirrlog|oraarch default = all\n";
    print "\t-w,  warning level for volume used in percent\n";
    print "\t-c,  critical level for volume used in percent\n";
    print "\n";
}

##  check options  ##
sub check_options {
    Getopt::Long::Configure ("bundling");
    GetOptions( 'h' => \$vhelp, 'f:s' => \$vopts, 'w:s' => \$vwarn, 'c:s' => \$vcrit );

    if ( defined( $vhelp )) { 
	help(); 
	exit $ERRORS{$aerr[3]};
    }
    
    if ( ! grep( /^$vopts$/, keys( %opts )) && $vopts ne 'all' ) {
	usage();
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

##  string compare return count of equal chear  ##
sub str_comp {

  my $str1 = shift;
  my $str2 = shift;

  my ( $max, $int, $stmp1, $stmp2 );

  if ( length( $str1 ) > length( $str2 ) ) {
    $max =length( $str1 );
  } else {
    $max =length( $str2 );
  }

  for ( $int = 1; $int <= $max ; $int++  ) {
    if ( substr( $str1, 0, $int ) ne  substr( $str2, 0, $int )) {
      return $int -1;
    }
  }
}


###   main   ###################################################################
#

check_options();

if ( -f '/bin/df' ) {

    my @atmp = `df -k -t nfs` ;

    foreach $stmp ( @atmp ) {
        chomp $stmp;
        if ( $stmp !~ /\/vol\// ) { next; }
        my @atmp1 = split(" ", $stmp );
        if ( $#atmp1 != 5 ) { next ; }

	foreach my $stmp1 ( keys %opts ) {
	    if ( $atmp1[0] =~ /$opts{$stmp1}/ ) {
		if ( defined $stat{$stmp1}{'rmp'} ) {
		    $stat{$stmp1}{'rmp'} = substr( $stat{$stmp1}{'rmp'}, 0, &str_comp( $stat{$stmp1}{'rmp'}  , $atmp1[0]));
		} else {
		    $stat{$stmp1}{'rmp'} = $atmp1[0];
		}
		$stat{$stmp1}{'size'}  = $atmp1[1];
		$stat{$stmp1}{'used'}  = $atmp1[2];
		$stat{$stmp1}{'free'}  = $atmp1[3];
		$stat{$stmp1}{'pused'} = $atmp1[4];
		$stat{$stmp1}{'pused'} =~ s/\%//g;
	    }
	}
    }
}

if ( $vopts =~ /all/ ) {
    my $int = 1;
    foreach $stmp ( sort{ $stat{$b}{'pused'} <=> $stat{$a}{'pused'}} keys %stat ) {
	if ( $int ) {
	    $int = 0;
	    if ( $stat{$stmp}{'pused'} >= $vcrit ) { $terr = 2;} 
	    elsif ( $stat{$stmp}{'pused'} >= $vwarn ) { $terr = 1;}
	    else { $terr = 0; }
	    print $aerr[$terr]." - ".$stat{$stmp}{'pused'}."% ".$stmp." | ";
	    print "'".$stmp." size'=".$stat{$stmp}{'size'}."kb;;;;";
	    print "'".$stmp." used'=".$stat{$stmp}{'used'}."kb;;;;";
	    print "'".$stmp." free'=".$stat{$stmp}{'free'}."kb;;;;";
	} else {
	    print "'".$stmp." size'=".$stat{$stmp}{'size'}."kb;;;;";
	    print "'".$stmp." used'=".$stat{$stmp}{'used'}."kb;;;;";
	    print "'".$stmp." free'=".$stat{$stmp}{'free'}."kb;;;;";
	}
	print "\n";
    }
} elsif ( defined $stat{$vopts} ) {
    if ( $stat{$vopts}{'pused'} >= $vcrit ) { $terr = 2;} 
    elsif ( $stat{$vopts}{'pused'} >= $vwarn ) { $terr = 1;}
    else { $terr = 0; }
    print $aerr[$terr]." - ".$stat{$vopts}{'pused'}."% ".$vopts." | ";
    print "'".$vopts." size'=".$stat{$vopts}{'size'}."kb;;;;";
    print "'".$vopts." used'=".$stat{$vopts}{'used'}."kb;;;;";
    print "'".$vopts." free'=".$stat{$vopts}{'free'}."kb;;;;\n";
}

exit $ERRORS{$aerr[$terr]};
