#!/usr/bin/perl
#
# Nagios-Icinga check for DB2 Databases - Availability
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
my $TIMEOUT     = 60;
my $TIMESTAMP   = time();

my @GREP        = ();
my @SYS_COMMAND = ();
my %OPTIONS     = ();

#
# Checking given parameters
#
GetOptions(\%OPTIONS,
           'SID|S=s',
           'TIMEOUT|R=i');

&print_syntax_error("Missing -S")  unless defined $OPTIONS{'SID'};

$OPTIONS{'SID'}  = uc($OPTIONS{'SID'});
$OPTIONS{'USER'} = 'db2'.lc($OPTIONS{'SID'});

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

# doing system call
eval {
  local $SIG{ALRM} = sub { die "Command Timeout: $!"};
  alarm(15);
  chomp ( @SYS_COMMAND = `su - $OPTIONS{'USER'} -c "db2" 2>&1 <<EOF
                          connect to $OPTIONS{'SID'}
						  select * from sysibmadm.env_inst_info
						  quit
						  EOF 2>&1` );
};

# timeout of system call reached ?
if ($@) {
  local $SIG{INT}='IGNORE';
  local $SIG{TERM}='IGNORE';
  kill 'TERM' => -$$;
  print "CRITICAL: $OPTIONS{'SID'} connection timeout\n";
  exit 2;
}
else {
  # set alarm (timeout) for whole script
  &set_alarm();
}

if (!grep(/1 record.* selected/, @SYS_COMMAND)){
    print "CRITICAL: No connection to $OPTIONS{'SID'} possible\n";
    exit 2;
}
else{
  print "OK: Connection to $OPTIONS{'SID'} possible\n";
  exit 0;
}

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
     -R = Runtime for script in seconds (optional, default = 60)

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
      print "CRITICAL: Script Error -> Timeout\n";
      exit 2;
    };
    $TIMEOUT = $TIMEOUT - $DURATION;
    alarm($TIMEOUT);
    $TIMESTAMP = time();
  }
  else {
    print "CRITICAL: Script Error -> Timeout\n";
    exit 2;
  }
}
