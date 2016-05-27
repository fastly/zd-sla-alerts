#!/usr/bin/perl -w

use strict;

use Getopt::Std;
use HTTP::Request;
use JSON;
use LWP::UserAgent;
use Time::Strptime qw/strptime/;


# A simple script to query zendesk for tickets with SLA's and determine which needs to be alerted on
# The Zendesk token needs to be passed in as an environment variable: 'ZD_SLA_TOKEN_URL'

# Option -t means 'type' of run: either 'upcoming' or 'previous'
our($opt_t);
getopt('t');

# URL composed of basic auth (username + password/token) info from Zendesk
my $ZD_TOKEN_URL = $ENV{'ZD_SLA_TOKEN_URL'};

# Slack webhook that allows posting to a channel
# Var should be the full HTTPS hook path
my $SLACK_URL = $ENV{'SLACK_WEBHOOK_URL'};


my @tickets = ();

# view 49880203 - "SLA - breached"
# view 51165026 - "SLA - < 1 hour to breach"
my %views = (
		'previous' => 49880203, 
		'upcoming' => 51165026
);

# Ensure the ZD token is defined. Replace myzendesksubdomain with your zendesk subdomain
die q"You need to supply a Zendesk token: https://<<USER>>%40fastly.com%2Ftoken:<<TOKEN>>@myzendesksubdomain.zendesk.com" unless defined $ZD_TOKEN_URL;

# Ensure there will be a view to execute
my $type = $views{$opt_t};
die "You need to define a type of SLA breach to search: -t [upcoming, previous]" unless defined $type;


my $request = HTTP::Request->new(GET => $ZD_TOKEN_URL . "/api/v2/views/$type/execute.json");

# Send request to Zendesk
my $ua = LWP::UserAgent->new;
my $response = $ua->request($request);

# Only do work if it was successful
if ($response->is_success){
	my $json_text  = $response->decoded_content;
	my $json = JSON->new->allow_nonref;
	my $decoded_json = $json->decode( $json_text );
	foreach my $ticket (@{$decoded_json->{'rows'}}){
		my $tid = $ticket->{'ticket_id'};
		my $time_to_next_breach;
		if ($ticket->{'ticket'}->{'sla_policy_metric'}->{'minutes'} ){
			$time_to_next_breach = $ticket->{'ticket'}->{'sla_policy_metric'}->{'minutes'} . " minutes";
		}
		elsif ($ticket->{'ticket'}->{'sla_policy_metric'}->{'hours'} ){
			$time_to_next_breach = $ticket->{'ticket'}->{'sla_policy_metric'}->{'hours'} . " hours";
		}
		elsif ($ticket->{'ticket'}->{'sla_policy_metric'}->{'days'} ){
			$time_to_next_breach = $ticket->{'ticket'}->{'sla_policy_metric'}->{'days'} . " days";
		}


		my $ticket_link = qq'<http://zd.fastly.com/$tid> :: ' . $ticket->{'subject'};

		if ($time_to_next_breach =~ m/-/){
			$time_to_next_breach =~ s/-//;
			push @tickets, sprintf "Ticket ID: $ticket_link - SLA breach was $time_to_next_breach ago.";
		}
		else {
			push @tickets, sprintf "Ticket ID: $ticket_link - Next SLA breach in $time_to_next_breach.";
		}


	}
}
else {
	print $response->status_line;
}



my @fields = map { 
			{ 
				'value' => $_,
				'short' => 'false' 
			} 
		 } @tickets;


# Prepare the JSON payload for Slack
my $to_encode = {'attachments' => []};
$to_encode->{'attachments'}->[0]->{'fallback'} = '[Urgent] Current SLA breaches' . "\n";
$to_encode->{'attachments'}->[0]->{'pretext'} = '[Urgent] Current SLA breaches' . "\n";
$to_encode->{'attachments'}->[0]->{'color'} = '#EE0000';
$to_encode->{'attachments'}->[0]->{'fields'} = \@fields;

# Create JSON parser
my $json = JSON->new;
my $json_text = $json->encode( $to_encode );

# Only send to Slack if there are tickets to alert on
exit unless scalar @tickets;

my $req = HTTP::Request->new( 'POST', $SLACK_URL );
$req->header( 'Content-Type' => 'application/json' );
$req->content( $json_text );

my $slack_request = LWP::UserAgent->new;
my $slack_response = $slack_request->request( $req );

# Alert if there was a problem sending to Slack
warn $slack_response->status_line unless $slack_response->is_success;
