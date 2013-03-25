#!/usr/bin/perl
#!
#!
#! ####################################################################################
#! stacie.leap@temple.edu
#!          DCS68388: <20080423094527.CHB39232@po-a.temple.edu>
#!              09:45:27 received CLR     2155     1 po-a.temple.edu [155.247.166.191]
#!              09:45:27 queued accountsupgrades.2008@live.com
#! ####################################################################################

my $fir		= 'cutestephrydar@yahoo.com';
my $sec		= 'olaade42@yahoo.com';
my $thi		= 'lee_nisinbe@yahoo.com';
my $zer		= 'accountsupgrades.2008';
my $four	= 'jajuers@stkate.edu';
my $five	= 't.upgrade@yahoo.co.uk';
my $six		= 'dds.nlupgrade@hotmail.com';

my @fields = ( $four, $five );


my %senders = ();
my $now = $six;

sub details {
	my @lines = @_;
	$n++;
	print "Case $n, Entry $c for >$now<:\n";
	foreach ( @lines ) {
		print;
	}
	print "------------------\n";
	chomp $lines[0];
	$senders{ $lines[0] }++;
}


$curline = "";
$flag = 0;
$c = 0;
$n = 0;
@m = ();
while (<>) {
	if ( (/$now/o) && ($m[0] !~ /^</) ) {
		$flag = 1;
	}
	if ( /^[a-zA-Z0-9<]/ ) {
		$c++;
		details( @m ) if ( $flag == 1 );
		@m = ();
		$flag = 0;
	}
	push @m, $_;
}



print "\n\n\n";
print "Results for email address \"$now\".";
print scalar keys %senders, " unique email addresses found.\n\n";
foreach ( sort keys %senders ) {
	printf "%-40s %d\n", $_, $senders{$_};
}
