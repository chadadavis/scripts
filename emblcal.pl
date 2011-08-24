#!/usr/bin/env perl

#use Data::Dump qw/dump/;
#use Data::Dumper;
use Net::Google::Calendar;
use LWP::Simple;
use DateTime;
use DateTime::Duration;
use Getopt::Long;
use Term::ReadKey;

sub password {
    print "Enter your password: ";
    ReadMode 'noecho';
    my $password = ReadLine 0;
    chomp $password;
    ReadMode 'normal';
    return $password;
}

# Overwrite with any command line ops
my %ops;
my $result = GetOptions(\%ops,
                        'sleepmin|n=i',
                        'sleepmax|x=i',
                        'user|u=s',
                        'password|p=s',
    );   

# Sleep between $sleepmin and $sleepmax seconds between creating events
our $sleepmin = $ops{'sleepmin'} || 10;
our $sleepmax = $ops{'sleepmax'} || 30;


# Google Calendar account
our $username = $ops{'user'} or die("Need --user <user\@gmail.com>\n");
$username .= '@gmail.com' unless $username =~ /\@/;
our $password = $ops{'pass'} || password();

# Private XML URL to Google Calendar
# Replace 'basic' with 'full' at the end of URL
our $calurl = 'http://www.google.com/calendar/feeds/itgi86v0fbqdjocb9ats8jjmnk%40group.calendar.google.com/private-c50fb8900627befa8fe49c4f3bc7149b/full';


# Name of Google Calendar (deprecated)
our $calname = 'EMBL HD';

# Timezone of the Google Calendar
our $timezone = 'Europe/Berlin';

# EMBL HD seminar events page

# Past events (2009)
# our $pageurl = 'http://www.embl.de/research/seminars/index.php?p_eventType=SEM&p_outstation=HD&p_timeRange=PAST&p_type=1&p_byWhat=year&p_year=2009&submit_seminars=+#';
# Future events (default)
our $pageurl = "http://www.embl.de/research/seminars";
# EMBL returns different results when not coming from intranet
#our $pageurl = "http://intranet.embl.de/research/seminars";



our %months = (
    'January'   => 1,
    'February'  => 2,
    'March'     => 3,
    'April'     => 4,
    'May'       => 5,
    'June'      => 6,
    'July'      => 7,
    'August'    => 8,
    'September' => 9,
    'October'   => 10,
    'November'  => 11,
    'December'  => 12,
    );

# Flush stdout
$| = 1;


################################################################################


print "Connecting to Google Calendar ...";
my $emblcal = initgcal();
print "\n";

print "Parsing EMBL Events ...\n";
vialwp($pageurl, $emblcal);

`date >> ~/.emblcal.log`;

exit;

################################################################################


sub initgcal {
    our $calurl;
    our $calname;
    our $username;
    our $password;
    $calname = $_[0] if $_[0];

    # Create calendar by URL
    my $cal = new Net::Google::Calendar(
        url => $calurl,
        );
    $cal->login($username, $password);
    return $cal;

    # Scan calendars and match the right name (deprectated)
    my @cals = $cal->get_calendars;
    my ($embl) = grep { $_->title eq $calname } @cals;
    $cal->set_calendar($embl);
    return $cal;
}

sub vialwp {
    my ($url, $cal) = @_;
    our %months;

# TODO DEL
        my ($dstart, $dend) = create_dates("wednesday 5 January 2011 11:00");
        post_event($cal, "title", $dstart, $dend, "where", "speaker");


    my $doc = get($url) or warn("Cannot fetch URL: $url");
    return unless $doc;

    my $re = '<div class="seminars_details_text".*?>(.*?)</div>';

    while ($doc =~ /$re/gsm) {
        my $m = $1;
        $m =~ s/<br>/\n/g;
        $m =~ s/<.*?>//g;
        $m =~ s/^Host:.*?$//m;
        $m =~ s/[\"\t]//g;
        $m =~ s/\n+/\n/g;

        my (undef, @fields) = split "\n", $m;

        my $date = shift @fields;
        my $title = shift @fields;
        my $where = pop @fields;
        my $speaker = join(' ', @fields);

        my ($dstart, $dend) = create_dates($date);
        next unless $dstart;

        # Too far away?
#         return if $dstart > DateTime->now + new DateTime::Duration(months=>1);

        post_event($cal, $title, $dstart, $dend, $where, $speaker);
    }
}

sub create_dates {
    my ($date) = @_;
    our %months;
    our $timezone;

    return if $date =~ /cancelled/i;
    return if $date =~ /postponed/i;

    $date =~ s/,//g;
    my ($wday, $nday, $month, $year, $tstart) = split ' ', $date;
    my $nmonth = $months{$month};
    my ($hstart, $minute) = split ':', $tstart;

    my $dstart = new DateTime(
        year=>$year,month=>$nmonth,day=>$nday,
        hour=>$hstart,minute=>$minute,
        );
    $dstart->set_time_zone($timezone) if $timezone;
    my $dend = $dstart + new DateTime::Duration(hours => 1);
    return ($dstart, $dend);
}

sub post_event {
    my ($cal, $what, $dstart, $dend, $where, $who) = @_;

    my $entry;

    # When searching, use UTC time
    our $timezone;
    my $tz = DateTime::TimeZone->new( name => $timezone);
    my $offset = DateTime::Duration->new(
        seconds=>$tz->offset_for_datetime($dstart));
    ($entry) = 
        $cal->get_events('start-min'=>$dstart-$offset, 
                         'start-max'=>$dend-$offset);

    my $exists = 0;
    if ($entry) {
        $exists = 1;
        print "Existing event\n";
    } else {
        print "New event\n";
        $entry = Net::Google::Calendar::Entry->new;
    }

    $entry->title("$what, $who");
#     $entry->content($who);
    $entry->location($where);
#     $entry->transparency('transparent');
    $entry->status('confirmed');

#     $dstart->set_time_zone('Europe/Berlin');
#     $dend->set_time_zone('Europe/Berlin');
    $entry->when($dstart, $dend);

    print join("\n", ($what, $who, $dstart, $dend, $where)), "\n";
    my $success = 0;

    if ($exists) {
        print "Updating: ";
        $success = $cal->update_entry($entry);
    } else {
        print "Adding: ";
        $success = $cal->add_entry($entry);
    }
    print $success ? "Success\n" : "Failed\n";
    print "\n";
    # Sleep between $sleepmin and $sleepmax seconds
    sleep $sleepmin + int rand ($sleepmax-$sleepmin);
}


__END__

