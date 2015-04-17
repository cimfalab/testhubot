#!/bin/sh

PORT=5033
HUBOT_HOME="/home/sdk-cloud-2/wsdkbot"
HUBOT_SLACK_TOKEN=xoxb-4018514085-eMvHAQVAMpDxdzCCcAyvEaD5
HUBOT_URL="127.0.0.1:$PORT"
DAEMON="$HUBOT_HOME/bin/hubot"
DAEMON_OPTS=" -a slack"
proxy=`echo $http_proxy`

echo $proxy
#$DAEMON -a slack
start-stop-daemon --start -v -d $HUBOT_HOME --exec /usr/bin/env PORT=$PORT /usr/bin/env HUBOT_SLACK_TOKEN=$HUBOT_SLACK_TOKEN /usr/bin/env http_proxy=$proxy $DAEMON --$DAEMON_OPTS
