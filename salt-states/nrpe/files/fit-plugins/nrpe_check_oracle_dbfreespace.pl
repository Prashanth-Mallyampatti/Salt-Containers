#!/usr/bin/perl
#
# Nagios-Icinga check for Oracle Databases (dbfreespace)
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

my $FOUND        = "FALSE";
my $SIZE         = "";
my $PERCENT      = "";
my $LIMIT        = "";
my $NAME         = "";
my $USAGE        = "";
my $FOUND_SPACES = "";
my @LONG_TEXT    = ();
my @GREP         = ();
my @SYS_COMMAND  = ();
my %OPTIONS      = ();

#
# Checking given parameters
#
GetOptions(\%OPTIONS,
           'SID|S=s',
           'VERBOSE|v=i',
           'TYPE|T=s',
		   'TIMEOUT|R=i');

&print_syntax_error("Missing -v")  unless defined $OPTIONS{'VERBOSE'};
&print_syntax_error("Missing -S")  unless defined $OPTIONS{'SID'};
$OPTIONS{'TYPE'} = "PROD" unless defined $OPTIONS{'TYPE'};
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
                          set lines 142
                          set pagesize 1000
                          column dummy        noprint
                          column pct_used     format 999           heading "Pct|Used"
                          column name         format a17           heading "Tablespace|Name"
                          column Kbytes       format 9,999,999,999 heading "Alloc|KBytes"
                          column used         format 9,999,999,999 heading "Alloc|Used"
                          column free         format 9,999,999,999 heading "Alloc|Free_KB"
                          column largest      format 999,999,999   heading "Largest|Chunk"
                          column max_size     format 9,999,999,999 heading "Maximum|Poss_KB"
                          column pct_max_used format 999           heading "Pct_all|used"
                          column AE_FREE_KB   format 9,999,999,999 heading "Autoext|Free_KB"
                          column ALL_FREE_KB  format 9,999,999,999 heading "Alloc+AE|Free_KB"
                          column pct_max_free format 999           heading "Pct_all|free"
                          break  on report
                          compute sum of kbytes on report
                          compute sum of free on report
                          compute sum of used on report
                          compute sum of ae_free_kb on report
                          compute sum of all_free_kb on report

                          select nvl(b.tablespace_name,
                                 nvl(a.tablespace_name,'UNKOWN')) name,
                                 kbytes_alloc kbytes,
                                 kbytes_alloc-nvl(kbytes_free,0) used,
                                 nvl(kbytes_free,0) free,
                                 ((kbytes_alloc-nvl(kbytes_free,0))/
                                                    kbytes_alloc)*100 pct_used,
                                 nvl(largest,0) largest,
                                 nvl(kbytes_max,kbytes_alloc) Max_Size,
                                 AE_Free_KB,
                                 (nvl(kbytes_free,0))+AE_Free_KB ALL_FREE_KB,
                                 (kbytes_alloc-nvl(kbytes_free,0))/(nvl(kbytes_max,kbytes_alloc))*100 pct_max_used,
                                 ((AE_Free_KB+nvl(kbytes_free,0))/kbytes_max)*100 pct_max_free
                          from ( select sum(bytes)/1024 Kbytes_free,
                                        max(bytes)/1024 largest,
                                        tablespace_name
                                 from  sys.dba_free_space
                                 group by tablespace_name
                                 union all
                                 select FREE_SPACE/1024 Kbytes_free,
                                        null,
                                        tablespace_name
                                 from  sys.dba_temp_free_space
                               ) a,
                               ( select sum(bytes)/1024 Kbytes_alloc,
                                        sum(decode(sign(BYTES+INCREMENT_BY-MAXBYTES),1,bytes,maxbytes)/1024) Kbytes_max,
                                        (sum(decode(sign(BYTES+INCREMENT_BY-MAXBYTES),1,bytes,maxbytes)/1024))-(sum(bytes)/1024) AE_Free_KB,
                                        tablespace_name
                                 from sys.dba_data_files
                                 group by tablespace_name
                                 union all
                                select sum(bytes)/1024 Kbytes_alloc,
                                       sum(decode(sign(BYTES+INCREMENT_BY-MAXBYTES),1,bytes,maxbytes)/1024) Kbytes_max,
                                       (sum(decode(sign(BYTES+INCREMENT_BY-MAXBYTES),1,bytes,maxbytes)/1024))-(sum(bytes)/1024) AE_Free_KB,
                                       tablespace_name
                                from sys.dba_temp_files
                                group by tablespace_name
                               ) b
                          where a.tablespace_name (+) = b.tablespace_name
                          order by 1;
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

if (!grep(/^Tablespace/, @SYS_COMMAND)){
  @GREP = grep(/ORA-/, @SYS_COMMAND);
  print "UNKNOWN: no information for SID \"$OPTIONS{'SID'}\" in database found\n";
  exit 3;
}

$FOUND = "FALSE";
foreach (@SYS_COMMAND){
  if ($_ =~ /^Tablespace/){$FOUND = "TRUE";}
  if ($FOUND eq "TRUE"){push(@LONG_TEXT,$_);}
  if ($_ =~ /^sum/){$FOUND = "FALSE";}
}


if ("$OPTIONS{'TYPE'}" eq "PROD"){
  foreach (@LONG_TEXT){
    if ($_ =~ /^PSAPTEMP( |\t)|^PSAPUNDO( |\t)|^TEMP( |\t)|^UNDO( |\t)/){
      next;
    }
    if ($_ =~ /^(\w+)\s+([0-9,]+)\s+[0-9,]+\s+[0-9,]+\s+[0-9,]+\s+[0-9,]+\s+[0-9,]+\s+[0-9,]+\s+[0-9,]+\s+([0-9,]+)\s+([0-9,]+)$/){
      $NAME    = $1;
      $SIZE    = $2;
      $USAGE   = $3;
      $PERCENT = $4;
      $SIZE    =~ s/,//g;

      if    ($SIZE <   25000000){$LIMIT = 20;}
      elsif ($SIZE <   75000000){$LIMIT = 15;}
      elsif ($SIZE <  175000000){$LIMIT = 10;}
      elsif ($SIZE <  500000000){$LIMIT = 5;}
      else                      {$LIMIT = 3;}

      if ($PERCENT < $LIMIT){
        $FOUND_SPACES .= "$NAME(Limit: $LIMIT),"; 
        $ERROR_CRIT    = "TRUE";
      }

      $PERF_DATA .= "'$NAME'=$USAGE%;;;; ";
    }
  }
}
else {
  foreach (@LONG_TEXT){
    if ($_ =~ /^PSAPTEMP( |\t)|^PSAPUNDO( |\t)|^TEMP( |\t)|^UNDO( |\t)/){
      next;
    }
    if ($_ =~ /^(\w+)\s+([0-9,]+)\s+[0-9,]+\s+[0-9,]+\s+[0-9,]+\s+[0-9,]+\s+[0-9,]+\s+[0-9,]+\s+[0-9,]+\s+([0-9,]+)\s+([0-9,]+)$/){
      $NAME    = $1;
      $SIZE    = $2;
      $USAGE   = $3;
      $PERCENT = $4;
      $SIZE    =~ s/,//g;

      if    ($SIZE <   75000000){$LIMIT = 10;}
      elsif ($SIZE <  300000000){$LIMIT = 5;}
      else                      {$LIMIT = 3;}

      if ($PERCENT < $LIMIT){
        $FOUND_SPACES .= "$NAME(Limit: $LIMIT),"; 
        $ERROR_CRIT    = "TRUE";
      }

      $PERF_DATA .= "'$NAME'=$USAGE%;;;; ";
    }
  }
}


#
# Evaluating short text and exit code
#
chop($FOUND_SPACES);
if ("$ERROR_WARN" eq "TRUE"){
  $SHORT_TEXT = "WARNING: $FOUND_SPACES freespace lower than defined threshold, see long text for more information";
  $RETURN_CODE = 1;
}
elsif ("$ERROR_CRIT" eq "TRUE"){
  $SHORT_TEXT = "CRITICAL: $FOUND_SPACES freespace lower than defined threshold, see long text for more information";
  $RETURN_CODE = 2;
}
else {
  $SHORT_TEXT = "OK: all freespace higher than defined threshold, see long text for more information";
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
     -T = PROD|TEST (optional, default = PROD)
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
