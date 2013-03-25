#!/usr/bin/perl -w
#!
#! ==========================================================================
#! Description:   Collect the files from each Mirapoint server and store
#!                them locally in a directory with the current date.
#! Author:        Ray Lauff
#! Rewritten:     2006-jul-11
#! ==========================================================================
#! Get login info from Mirapoints for summarizing.
#! ==========================================================================

use LWP::Simple;
use Mirapoint::Admin;                           # Admin Protocol
use Getopt::Long;

BEGIN {
        require '/usr/local/adm/lib/perlutils.pl';
        require '/home/mirastat/etc/gather_config.pl';
}


# ###############
# Determine the date we're running for and set all the date variables accordingly.
# ###############
my $me = short_program_name( $0 );
my ( $opt_date, $opt_output );
GetOptions(                                             # use as  "./gather.pl --date=2004-01-03  --outputdir=/tmp/log1"
        "date=s"        => \$opt_date,
        "outputdir=s"   => \$opt_output_dir
);
my $date        = ( defined $opt_date )       ? $opt_date       : yesterday();
my $output_dir  = ( defined $opt_output_dir ) ? $opt_output_dir : MIRAPOINT_DATA_DIRECTORY;        # default is '/home/mirastat/data'

die "\n===>\n===> Invalid date format: \"$date\".\n===> Must be YYYY-MM-DD.\n==>\n" if ( $date !~ /\d\d\d\d-\d\d-\d\d/ );   
							# will be 2004-09-20.
my $year_month  = substr $date, 0, 7;			# will be "2004-09".
my $dayofyear   = `/bin/date --date=$date +%Y-%j`;	# will be "2004-230".
chomp $dayofyear;
print "\n\n\n     Processing the date $date: Day of year is $dayofyear.\n";



# ###############
# For each MP host, create an array of the URLs needed
# ###############
foreach ( keys %gather_entries ) {     # this will be the tag, 'traffic_summary' or 'security_spam', etc.
	next if ( ! /mail_detailed/ );
	foreach $host ( @{$gather_entries{$_}{'hosts'}} ) {
		# store the file name (tag) and the URL; we'll split them when we need them.
		push @{$host_urls{ $host }},  $_ . ' ' . $gather_entries{$_}{'url'};       
	 	print "     Page:$_ Host:$host url:$gather_entries{$_}{'url'}\n";
	}
}




# ###############
# Create the first part of the output directory, the "/home/mirastat/data/2006-07" part.
# ###############
my $output_dir_with_date = "./";
if ( ! -e $output_dir_with_date ) {
	mkdir( $output_dir_with_date ) or die "===> Can't create directory $output_dir_with_date for output of data.  Abort.\n";
	print "     Created $output_dir_with_date.\n";
	if ( ! -e $output_dir_with_date ) {
		die "===> Odd failure; system created a directory but we can't find it.  Abort.  Directory was to be \"$output_dir_with_date\".\n";
	}
}



foreach my $mp_host ( sort keys %host_urls ) {

	$_ = $mp_host;
	next if ( ! /smtp/ );
	my $sessionid = return_session_id( $mp_host );
	%complete_urls = ();



	foreach ( @{$host_urls{$mp_host}} ) {
		###my ( $tag, $url ) = split / /, $_, 2;
		$url = 'https://--MAILHOST--/cgi-bin/mdadmin.cgi/sa/reporting_mail_detailed.html?pr_op=dump&sessionid=--SESSION_ID--&repo_yearday=2008-117&exportnow=Download&rnd=32';
		$url =~ s/--MAILHOST--/$mp_host/;
		$url =~ s/--SESSION_ID--/$sessionid/;
		print "\n\nURL: $url.\n\n";
		$complete_urls{ $tag } = $url;
	}

	

	# Go through for each host and get the data files
	print "\n\n\n\n\n\n     $mp_host: \n";
	foreach my $tag ( keys %complete_urls ) {
		print "     Processing url: \"$complete_urls{ $tag }\"\n";
		my $output_file_date_tag = $output_dir_with_date . '/' . '2008-04-26' . '_' . $tag;
		if ( ! -e $output_file_date_tag ) {
			print "     Creating directory $output_file_date_tag.\n";
			mkdir ( $output_file_date_tag ) or die "===> Can't create directory \"$output_file_date_tag\" for output of data.  Abort.\n";
		}

		my $output_full_path_and_file = $output_file_date_tag . '/' . $dayofyear . '_' . $date . '_' . $tag . '_' . $mp_host . '.txt';
		if ( -e $output_full_path_and_file ) {
			print "---> NOTE: File already exists for host $mp_host for $date; skipping...\n";
			print "         $output_full_path_and_file\n\n";
		} else {
			my $useurl = $complete_urls{$tag};
			my $cmd = "wget --no-check-certificate \"$useurl\" -O $output_full_path_and_file";
			print "     ", $cmd, "\n";
			`$cmd`;
		}
	}

	print "\n\n\n\n\n";
}




exit;
