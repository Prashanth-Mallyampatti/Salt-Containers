#!/usr/bin/perl
#
# Nagios-Icinga check for Oracle Databases (dbfreechunks)
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
my $PERF_DATA   = "";
my $ERROR_CRIT  = "FALSE";
my $ERROR_WARN  = "FALSE";
my $SHORT_TEXT  = "";
my $RETURN_CODE = 0;

my $TIMEOUT     = 60;
my $TIMESTAMP   = time();

my $FOUND       = "";
my @LONG_TEXT   = ();
my @GREP        = ();
my @SYS_COMMAND = ();
my %OPTIONS     = ();

#
# Checking given parameters
#
GetOptions(\%OPTIONS,
           'SID|S=s',
           'VERBOSE|v=i',
		   'TIMEOUT|R=i');

&print_syntax_error("Missing -v")  unless defined $OPTIONS{'VERBOSE'};
&print_syntax_error("Missing -S")  unless defined $OPTIONS{'SID'};
$OPTIONS{'SID'} = uc($OPTIONS{'SID'});
$OPTIONS{'USER'} = 'ora'.lc($OPTIONS{'SID'});

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
  chomp ( @SYS_COMMAND = `su - $OPTIONS{'USER'} -c "sqlplus /nolog" 2>&1 <<EOF
                          connect / as sysdba
						  set feedback on
                          set lines 120
                          set pagesize 9999
                          select a.TABLESPACE_NAME, max_freesp_chunk, max_autoex_chunk,
                            decode(sign(max_freesp_chunk-max_autoex_chunk),1,max_freesp_chunk,max_autoex_chunk) as max_chunk,
                            max_next_extent from
                           ( select TABLESPACE_NAME, max(BYTES) as max_freesp_chunk from dba_free_space group by TABLESPACE_NAME ) a,
                           ( select TABLESPACE_NAME, max(DECODE(MAXBYTES,0,BYTES,MAXBYTES)-BYTES) as max_autoex_chunk from dba_data_files group by TABLESPACE_NAME) b,
                           ( select TABLESPACE_NAME, nvl(max(NEXT_EXTENT),0) as max_next_extent from dba_segments group by TABLESPACE_NAME) c
                          where a.TABLESPACE_NAME = b.TABLESPACE_NAME
                          and a.TABLESPACE_NAME = c.TABLESPACE_NAME
                          and MAX_NEXT_EXTENT > decode(sign(max_freesp_chunk-max_autoex_chunk),1,max_freesp_chunk,max_autoex_chunk);
                          quit
                          EOF 2>&1` );
};

# timeout of system call reached ?
if ($@) {
  local $SIG{INT}='IGNORE';
  local $SIG{TERM}='IGNORE';
  kill 'TERM' => -$$;
  print "UNKNOWN: $OPTIONS{'SID'} connection timeout\n";
  exit 3;
}
else {
  # set alarm (timeout) for whole script
  &set_alarm();
}

if (grep(/ORA-/, @SYS_COMMAND)){
  @GREP = grep(/ORA-/, @SYS_COMMAND);
  print "UNKNOWN: oracle error message \"$GREP[0]\"\n";
  exit 3;
}

if (!grep(/^no rows selected/, @SYS_COMMAND)){
  if (!grep(/^TABLESPACE_NAME/, @SYS_COMMAND)){
    @GREP = grep(/ORA-/, @SYS_COMMAND);
    print "UNKNOWN: no information for SID \"$OPTIONS{'SID'}\" in database found\n";
    exit 3;
  }

  $ERROR_CRIT = "TRUE";
  $FOUND = "FALSE";
  foreach (@SYS_COMMAND){
    if ($_ =~ /^TABLESPACE_NAME/){$FOUND = "TRUE";}
    if ($FOUND eq "TRUE"){push(@LONG_TEXT,$_);}
    if ($_ =~ /^$/){$FOUND = "FALSE";}
  }
}

#
# Evaluating short text and exit code
#
if ("$ERROR_WARN" eq "TRUE"){
  $SHORT_TEXT = "WARNING: not all dbfreechunks o.k., see long text for more information";
  $RETURN_CODE = 1;
}
elsif ("$ERROR_CRIT" eq "TRUE"){
  $SHORT_TEXT = "CRITICAL: not all dbfreechunks o.k., see long text for more information";
  $RETURN_CODE = 2;
}
else {
  $SHORT_TEXT = "OK: all dbfreechunks o.k.";
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
	 -R = Runtime for script in seconds (optional, default = 60)
     -v = Verbose level (0-3) (required)
        0: Short Text
        1: Short Text, Performance Data
        2: Short Text, Performance Data, Long Text
        3: Short Text, Long Text

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
