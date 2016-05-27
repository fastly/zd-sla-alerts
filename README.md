# zd-sla-alerts
For alerting CSE team when a ticket with an SLA has or would soon breach it.

Currently it executes a view in Zendesk, looks at the SLA breach times for the tickets returned and sends a message to a Slack channel with the tickets.

*Usage:*

The Zendesk token info needs to set in an environment variable: $ZD_SLA_TOKEN_URL 
`https://<<USER>>%40fastly.com%2Ftoken:<<TOKEN>>@fastly.zendesk.com`

Where <<USER> is the Zendesk user's name part of the email and <<TOKEN>> is the Zendesk token.

`zd-sla-to-slack.pl -t [upcoming, previous] `

It needs to run at intervals so the CSE can be aware of tickets that need to be acted upon.

So the alerts for tickets that have already breached SLA don't spam continually they should be checked for less frequently, like once or twice per day: 

`zd-sla-to-slack.pl -t previous`

The upcoming SLA breach check can be run more frequently:

`zd-sla-to-slack.pl -t upcoming`.
