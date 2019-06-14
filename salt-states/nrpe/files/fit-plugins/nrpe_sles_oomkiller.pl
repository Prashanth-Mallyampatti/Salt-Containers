#!/usr/bin/perl -T
#
#
#   $URL: svn://subversion.eu.fit/nagios/plugins/nrpe/nrpe_sles_oomkiller.pl $
#   $Rev: 347 $
#    $Id: nrpe_sles_oomkiller.pl 347 2014-05-20 12:56:20Z itlangs $
#
# Check_oomkiller Nagios plugin. 
# Need nrpe_sles_oomkiller_wrapper, because the /var/log/messages is only readable for the root user
# The Logfile is parsed for oom killer entries. The diff file is located in /tmp/.check_oomkiller.previous
#
# AUFRUF: /usr/lib/nagios/plugins/nrpe_oomkiller_wrapper
#
# responsible: Joerg Lenz, Netlution GmbH
#
# Requirements: nrpe agent must be configured and running, hpasmcli
#
# itlenzj: 20140311: script erstellt

#
# John Chivian
# 4/3/2010
#
# path = $ENV{'PATH'};

$ENV{'PATH'}="/bin:/usr/bin";
delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};

my $pFile='/tmp/.check_oomkiller.previous';
my $hName=`hostname -s`;
chomp ($hName);

#--- If the previous check instance file doesn't exist then initialize one

if (! -e $pFile)
{
   unless (open PREV, ">$pFile")
   {
      print "can't open previous check instance file ($pFile) for writing\n";
      exit (3);
   }
   unless (print PREV "epoch $hName check_oomkiller: initialization\n")
   {
      print"can't write initialization entry into previous check instance file ($pFile)\n";
      exit (3);
   }
   close (PREV);
}

#--- Make sure the previous check instance file is a regular file and can be read before actually trying to do so

unless (-f $pFile && -r $pFile)
{
   print "can't read from previous check instance file ($pFile)\n";
   exit (3);
}

my $prevLine=`head -1 $pFile`;
chomp($prevLine);

#--- Check for OOM Killer activity since the previous check

#my $mFile='/tmp/test_oom_killer';
my $mFile='/var/log/messages';
my $Ubuntu=`uname -a | grep -c Ubuntu`;
if ($Ubuntu ge 1){
	$mFile='/var/log/syslog';
}


unless (open MESS, "<$mFile")
{
   print "can't open system messages file ($mFile) for reading\n";
   exit (3);
}

my $currLines=0;
my @oomLines=();

while (<MESS>)
{
   chomp($_);

   if ($_ =~ /Out of Memory: Killed process/)
   {
      $oomLines[$currLines]=$_;
      $currLines++;

      if ($_ eq $prevLine)
      {
         @oomLines=();
         $currLines=0;
      }
   }
}

close (MESS);

#--- If no assassinations since previous check then we're done

if ($currLines eq 0)
{
   print "Ok - no oom-killer activity since previous check\n";
   exit (0);
}

#--- Record the last oom-killer instance

unless (open PREV, ">$pFile")
{
   print "can't open previous check instance file ($pFile) for writing\n";
   exit (2);
}
unless (print PREV "$oomLines[$#oomLines]\n")
{
   print "can't write current entry into previous check instance file ($pFile)\n";
   exit (2);
}
close (PREV);

#--- Build the array of victims

my $vpid="";
my $vnam="";

my $loopy=0;
my $theLine="";
my @victims=();

while ($loopy <= $#oomLines)
{
   $theLine=$oomLines[$loopy];
   chomp($theLine);
   my @stringPieces=split(/process /,$theLine);
   my @substringPieces=split(/ /,$stringPieces[1]);
   $vpid=$substringPieces[0];
   $vnam=substr($substringPieces[1],1,-2);
   $victims[$loopy]="($vpid/$vnam)";
   $loopy++;
}

my $vString=join("",@victims);
print "Critical - OOM-Killer Victims: $vString\n";
exit (2);

