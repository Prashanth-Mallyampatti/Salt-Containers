#!/usr/bin/perl
#
# Nagios-Icinga check for SAP Workprocesses
#
# Responsible: Michael Schmitz - michael.schmitz@freudenberg-it.com
#

#   subversion tag
#
#   $URL: $
#   $Rev: $
#   $Id:  $
#

################################################################################
################################################################################
# Including modules
################################################################################
################################################################################
use strict;
use warnings;
use Getopt::Long;
Getopt::Long::Configure('bundling');

################################################################################
################################################################################
# Setting inital variables, getting and checking options
################################################################################
################################################################################
#
# Declaration of global used variables
#
my $TYPE          = "";
my $WP_BUSY       = "";
my $PROC          = "";
my $TOTAL         = "";
my $FREE          = "";
my $ERROR_WARN    = "FALSE";
my $ERROR_CRIT    = "FALSE";
my $PERF_DATA     = "";
my $SHORT_TEXT    = "";
my $RC            = "";
my $TIMEOUT       = 60;
my $TIMESTAMP     = time();
my $RETURN_CODE   = 0;
my $SHORT_VALUES  = "";

my @SYS_COMMAND   = ();
my @DATA          = ();
my @LONG_TEXT     = ();
my %OPTIONS       = ();

my $WP = {};
my %WP = (
    DIA => [],
    ENQ => [],
    BTC => [],
    SPO => [],
    UPD => [],
    UP2 => [],
);

#
# Checking given parameters
#
GetOptions(\%OPTIONS,
           'VERBOSE|v=i',
           'INSTANCE|I=s',
           'SID|S=s',
		   'TIMEOUT|R=i',
           'WARNING|w=i',
           'CRITICAL|c=i');
          
&print_syntax_error("Missing -v")  unless defined $OPTIONS{'VERBOSE'};
&print_syntax_error("Missing -I")  unless defined $OPTIONS{'INSTANCE'};
&print_syntax_error("Missing -S")  unless defined $OPTIONS{'SID'};
$OPTIONS{'WARNING'}  = 0 unless defined $OPTIONS{'WARNING'};
$OPTIONS{'CRITICAL'} = 0 unless defined $OPTIONS{'CRITICAL'};
$OPTIONS{'SID'} = uc($OPTIONS{'SID'});
$OPTIONS{'USER'} = lc($OPTIONS{'SID'}).'adm';

if (defined $OPTIONS{'TIMEOUT'}){
  $TIMEOUT = $OPTIONS{'TIMEOUT'};
}

#
# Starting Alarm
#
&set_alarm();

################################################################################
################################################################################
# Main
################################################################################
################################################################################ 
  
# doing system call with new alarm (timeout)
eval {
  local $SIG{ALRM} = sub { die "Command Timeout: $!"};
  alarm(15);
  chomp ( @SYS_COMMAND = `su - $OPTIONS{'USER'} -c "sapcontrol -nr $OPTIONS{'INSTANCE'} -function ABAPGetWPTable" 2>&1` );
};

# timeout of system call reached ?
if ($@) {
  local $SIG{INT}='IGNORE';
  local $SIG{TERM}='IGNORE';
  kill 'TERM' => -$$;
  print "UNKNOWN: connection timeout (SID=$OPTIONS{'SID'} / Instance=$OPTIONS{'INSTANCE'})\n";
  exit 3;
}
else {
  $RC = $? >> 8;
  
  if ( $RC == 0 ) {
    # Parse the data and save it in %WP hash
    foreach (@SYS_COMMAND){ 
      @DATA = split(', ');
      if(defined $DATA[1]){
        # Push WP types onto array
        if(defined $WP{$DATA[1]}){
          push( @{$WP->{$DATA[1]}}, $DATA[3]);
        }
      }  
    }

    # Count busy and total and create the message.
    for $TYPE (sort keys %$WP) {
      $WP_BUSY = 0;
      foreach $PROC ( @{$WP->{$TYPE}} ){
        if($PROC ne 'Wait'){
          $WP_BUSY++;
        }
      }

      $TOTAL = scalar @{$WP->{$TYPE}};
      $FREE  = $TOTAL - $WP_BUSY;      
      
      if($TYPE eq 'DIA'){
        $SHORT_VALUES = "$WP_BUSY/$TOTAL";  
        if($FREE <= $OPTIONS{'WARNING'}){$ERROR_WARN="TRUE";}
        if($FREE <= $OPTIONS{'CRITICAL'}){$ERROR_CRIT="TRUE";}
      }
      
      push ( @LONG_TEXT , "$TYPE -> $WP_BUSY/$TOTAL" );  
      $PERF_DATA .= "$TYPE=$WP_BUSY;;;0;$TOTAL ";
    }
  }
  else {
    print "UNKNOWN: could not get work processes list via sapcontrol (SID=$OPTIONS{'SID'} / Instance=$OPTIONS{'INSTANCE'})\n";
    foreach (@SYS_COMMAND){
      print "$_\n";
    }        
    exit 3;
  }
}

#
# Evaluating short text and exit code
#
if ("$ERROR_CRIT" eq "TRUE"){
  $SHORT_TEXT = "CRITICAL: Free dialog processes under threshold -> $SHORT_VALUES";
  $RETURN_CODE = 2;
  #Create result file from error
  mkdir "/usr", unless -d "/usr";
  mkdir "/usr/local", unless -d "/usr/local";
  mkdir "/usr/local/log", unless -d "/usr/local/log";
  mkdir "/usr/local/log/wp_count", unless -d "/usr/local/log/wp_count";
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
  my $TIMESTAMP = sprintf ( "%04d.%02d.%02d_%02d:%02d:%02d", $year+1900,$mon+1,$mday,$hour,$min,$sec);
  open (FILEHANDLER, ">/usr/local/log/wp_count/".$TIMESTAMP);
  foreach (@SYS_COMMAND){
    print FILEHANDLER $_ . "\n";
  }
  close (FILEHANDLER);
}
elsif ("$ERROR_WARN" eq "TRUE"){
  $SHORT_TEXT = "WARNING: Free dialog processes under threshold -> $SHORT_VALUES";
  $RETURN_CODE = 1;
  #Create result file from warning
  mkdir "/usr", unless -d "/usr";
  mkdir "/usr/local", unless -d "/usr/local";
  mkdir "/usr/local/log", unless -d "/usr/local/log";
  mkdir "/usr/local/log/wp_count", unless -d "/usr/local/log/wp_count";
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
  my $TIMESTAMP = sprintf ( "%04d.%02d.%02d_%02d:%02d:%02d", $year+1900,$mon+1,$mday,$hour,$min,$sec);
  open (FILEHANDLER, ">/usr/local/log/wp_count/".$TIMESTAMP);
  foreach (@SYS_COMMAND){
    print FILEHANDLER $_ . "\n";
  }
  close (FILEHANDLER);
}
else {
  $SHORT_TEXT = "OK: Free dialog processes over threshold -> $SHORT_VALUES";
  $RETURN_CODE = 0;
} 

#
# Printing output in relation to verbose specification
#
if ( $OPTIONS{'VERBOSE'} == 0 ){
  print "$SHORT_TEXT\n";        
}
elsif ( $OPTIONS{'VERBOSE'} == 1 ){
  print "$SHORT_TEXT | $PERF_DATA\n";
}
elsif ( $OPTIONS{'VERBOSE'} == 2 ){
  print "$SHORT_TEXT | $PERF_DATA\n";
  foreach (@LONG_TEXT){
    print "$_\n";
  }   
}  
elsif ( $OPTIONS{'VERBOSE'} == 3 ){
  print "$SHORT_TEXT\n";
  foreach (@LONG_TEXT){
    print "$_\n";
  }   
}  
exit($RETURN_CODE);


################################################################################
################################################################################
# Functions
################################################################################
################################################################################
#
# Printing syntax error message
#
sub print_syntax_error() {
    my $FUNC_TEXT = shift;
    print <<EOU;
  
Syntax Error: $FUNC_TEXT

   Options:
     -S = SID (required)
     -I = Instance number of SAP system (required)
     -R = Runtime for script in seconds (optional, default = 60)	 
     -v = Verbose level (0-3) (required)   
        0: Short Text
        1: Short Text, Performance Data
        2: Short Text, Performance Data, Long Text
        3: Short Text, Long Text
        
     -w = Warning threshold for free dialog processes, default 0 (optional)
     -c = Critical threshold for free dialog processes, default 0 (optional)
EOU
    exit 3;
}
#
# set alarm
#
sub set_alarm() {
  #calculating runtime of script
  my $DURATION = time() - $TIMESTAMP;

  #calculating rest of given time and setting new alarm
  if ($TIMEOUT - $DURATION >= 1){
    $SIG{ALRM} = sub {
      print "UNKNOWN: Script Error -> Timeout\n";
      exit 3;
    };
    $TIMEOUT = $TIMEOUT - $DURATION;
    alarm($TIMEOUT);
    $TIMESTAMP = time();
  }
  else {
    print "UNKNOWN: Script Error -> Timeout\n";
    exit 3;
  }
}
