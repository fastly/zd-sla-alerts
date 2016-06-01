# zd-sla-alerts
For alerting CSE team when a ticket with an SLA has or would soon breach it.

Currently it executes a view in Zendesk, looks at the SLA breach times for the tickets returned and sends a message to a Slack channel with the tickets.

##Usage:


`zd-sla-to-slack.pl -t [upcoming, previous] `

It needs to run at intervals so the CSE can be aware of tickets that need to be acted upon.

So the alerts for tickets that have already breached SLA don't spam continually they should be checked for less frequently, like once or twice per day: 

`zd-sla-to-slack.pl -t previous`

The upcoming SLA breach check can be run more frequently:

`zd-sla-to-slack.pl -t upcoming`.

The the 2 values for the 'types' parameter correspond to views that were created in Zendesk: 1 that returns tickets about to breach their SLA and 1 that returns tickets that have already breached.


##Configuration

There are a few variables that need to be set before usage.
Place them in a file called 'config.yaml' which has the following format:

```
ZD_TOKEN_URL : https://<<USER>>%40<<DOMAIN>>%2Ftoken:<<TOKEN>>@<<DOMAIN>>

#Where `<<USER>` is the Zendesk user's name part of the email and `<<TOKEN>>` is the Zendesk token.

SLACK_WEBHOOK_URL : https://hooks.slack.com/services/<<ID>>


ZD_SLA_VIEWS:
  previous : <<VIEW_ID>>
  upcoming : <<VIEW_ID>>

ZD_TICKET_LINK_BASE_URL : http://<<DOMAIN>>/
```


##Required modules

Getopt::Std

HTTP::Request

IO::YAML

JSON

LWP::UserAgent
