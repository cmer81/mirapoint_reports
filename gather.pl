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
	our $pgm= short_program_name($0);
}

my @outlines_LS = ();

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

out2log_die( "Invalid date format: \"$date\".\n===> Must be YYYY-MM-DD.\n==>\n" ) if ( $date !~ /\d\d\d\d-\d\d-\d\d/ );   
							# will be 2004-09-20.
my $year_month  = substr $date, 0, 7;			# will be "2004-09".
my $dayofyear   = `/bin/date --date=$date +%Y-%j`;	# will be "2004-230".
chomp $dayofyear;
out2log( "Processing the date $date: Day of year is $dayofyear.\n" );



# ###############
# For each MP host, create an array of the URLs needed
# ###############
foreach my $tag( keys %gather_entries ) {     # this will be the tag, 'traffic_summary' or 'security_spam', etc.
	foreach my $host ( @{$gather_entries{$tag}{'hosts'}} ) {
		# store the file name (tag) and the URL; we'll split them when we need them.
		push @{$host_urls{ $host }},  $tag . ' ' . $gather_entries{$tag}{'url'};       
		out2log( "Page:$tag Host:$host url:$gather_entries{$tag}{'url'}\n" );
	}
}
out2log( "\n\n" );



# ###############
# Create the first part of the output directory, the "/home/mirastat/data/2006-07" part.
# ###############
my $output_dir_with_date = $output_dir . '/' . $year_month;
if ( ! -e $output_dir_with_date ) {
	out2log( "Creating output directory $output_dir_with_date.\n" );
	mkdir( $output_dir_with_date ) or out2log_die( "===> Can't create directory $output_dir_with_date for output of data.  Abort.\n" );
	out2log( "Created $output_dir_with_date.\n" );
	if ( ! -e $output_dir_with_date ) {
		out2log_die( "===> Odd failure; system created a directory but we can't find it.  Abort.  Directory was to be \"$output_dir_with_date\".\n" );
	}
} else {
	out2log_warn( "Notice: Ouput ROOT directory $output_dir_with_date already exists.\n" );
}
print "\n\n";



foreach my $mp_host ( sort keys %host_urls ) {

	my $sessionid = return_session_id( $mp_host );
	%complete_urls = ();

	foreach ( @{$host_urls{$mp_host}} ) {
		my ( $tag, $url ) = split / /, $_, 2;
		$url =~ s/--MAILHOST--/$mp_host/;
		$url =~ s/--SESSION_ID--/$sessionid/;
		$url =~ s/--YEARDAY--/$dayofyear/;
		$complete_urls{ $tag } = $url;
	}

	

	# Go through for each host and get the data files
	out2log( "***** $mp_host:\n" );
	foreach my $tag ( reverse sort keys %complete_urls ) {
		out2log( "Processing url: \"$complete_urls{ $tag }\"\n" );
		my $output_file_date_tag = $output_dir_with_date . '/' . $date . '_' . $tag;
		if ( ! -e $output_file_date_tag ) {
			out2log( "Creating directory $output_file_date_tag.\n" );
			mkdir ( $output_file_date_tag ) or out2log_die( "===> Can't create directory \"$output_file_date_tag\" for output of data.  Abort.\n" );
		}

		my $output_full_path_and_file = $output_file_date_tag . '/' . $dayofyear . '_' . $date . '_' . $tag . '_' . $mp_host . '.txt';
		if ( -e $output_full_path_and_file ) {
			out2log_warn( "NOTE: File already exists for host $mp_host for $date; skipping...\n" );
		} else {
		      # my $useurl = $complete_urls{$tag} . "&pr_op=dump&repo_yearday=$dayofyear";
			my $useurl = $complete_urls{$tag};
			my $cmd = "wget --timeout=30  --tries=1  --no-check-certificate  \"$useurl\" -O $output_full_path_and_file";
			out2log( "CMD: $cmd\n" );
			print "\n\n";
			`$cmd`;
		}

		out2log( "The file now appears as follows:\n" );
		my $outline = qx(/bin/ls -ld $output_full_path_and_file);
		my $fmtline = sprintf "%s %s %s %s %15s %s", ( split / /,$outline, 6 );
		push @outlines_LS, $fmtline;
		out2log( "LS: $fmtline\n" );
	}

	print "\n\n\n\n\n";
}



print "LS of files retrieved:\n";
foreach ( @outlines_LS ) {
	print;
}


exit;
