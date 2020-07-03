#!/usr/bin/env bash

# ==================================================================================================
# Required preset env vars
# ==================================================================================================
# SLACK_WEBHOOK: 
#   The Slack webhook url
#   Reference: https://slack.com/apps/A0F7XDUAZ-incoming-webhooks
#   Please use github secrets to store it
# SLACK_CHANNEL: 
#   The slack channel to send message to
#   How to get: https://stackoverflow.com/a/44883343/536807
#   Please use github secrets to store it
# STATUS: 
#   The github action job status
#   You can get this with `${{ job.status }}`
# GH_REPO: 
#   The github repository
#   You can get this with `${{ github.repository }}`
# GH_MESSAGE: 
#   The commit message of the commit to show as code block in the slack message
#   You can get this with `${{ github.event.commits[0].message }}`
# GH_ACTOR: 
#   The person to show as the responsible for the commit
#   You can get this with `${{ github.actor }}`
# GH_SHA: 
#   The sha of the commit
#   You can get this with `${{ github.sha }}``
# APP_ENVIRONMENT:
#   The application environment, usually `production` or `staging`
# DEPLOY_TARGET:
#   Where it was deployed to, usually a heroku app name
# LANGUAGE: 
#   The main programming language of the project. This is used to show the language
#   icon on the slack message. We use a bitbucket CDN to get the images. Please test
#   the image exists before setting it
#   Known working values: `ruby`, `python`, `nodejs` 

REPO_NAME=`cut -d "/" -f2 <<< "$GH_REPO"`
NOW=`date +'%s'`
FOOTER_ICON="https://d301sr5gafysq2.cloudfront.net/e0aa900cf99a/img/repo-avatars/$LANGUAGE.png"
USERNAME="Github"
TEXT="\`\`\`$GH_MESSAGE\`\`\`"
TITLE_LINK="https://github.com/$GH_REPO/commit/$GH_SHA/checks"
AUTHOR_NAME="$GH_ACTOR"
AUTHOR_ICON="http://github.com/$GH_ACTOR.png?size=32"
AUTHOR_LINK="http://github.com/$GH_ACTOR"
STATUS=`echo $STATUS | tr '[A-Z]' '[a-z]'`

if [ "$STATUS" = "success" ]
then
  ICON_EMOJI=":ivete-happy:"
  NOTIFICATION_COLOR="#5DB182"
elif [ "$STATUS" = "failure" ]
then
  ICON_EMOJI=":ivete-sad:"
  NOTIFICATION_COLOR="#EC6240"
else
  ICON_EMOJI=":ivete:"
  NOTIFICATION_COLOR="#CCCCCC"
fi

read -r -d '' body << EOF
{
  "channel": "$SLACK_CHANNEL",
  "username": "$USERNAME",
  "icon_emoji": "$ICON_EMOJI",
  "attachments": [
    {
      "color": "$NOTIFICATION_COLOR",
      "title": "[$REPO_NAME] Deploy to $APP_ENVIRONMENT",
      "text": "$TEXT",
      "title_link": "$TITLE_LINK",
      "fallback": "[$REPO_NAME] Successfully deployed to $APP_ENVIRONMENT",
      "author_name": "$AUTHOR_NAME",
      "author_icon": "$AUTHOR_ICON",
      "author_link": "$AUTHOR_LINK",
      "ts": $NOW,
      "footer_icon": "$FOOTER_ICON",
      "footer": "$REPO_NAME",
      "fields": [ 
        { "title": "Status", "value": "$STATUS", "short": true },
        { "title": "Deployed to", "value": "$DEPLOY_TARGET", "short": true }
      ]
    }
  ]
}
EOF

curl "$SLACK_WEBHOOK" \
  -X POST \
  -H "Content-type: application/json; charset=utf-8" \
  -d "$body"
