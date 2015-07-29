# Notifies about server build errors
#
# URLS:
#   POST /hubot/server-notify?room=<room>
# 
# Authors:
#   Kim Kangho
#   Kim Sangjin

url = require('url')
querystring = require('querystring')

module.exports = (robot) ->

  console.log "Initializing server-notifier..."
  robot.router.post "/hubot/server-notify", (req, res) ->

    query = querystring.parse(url.parse(req.url).query)

    res.end('')

    envelope = {}
    envelope.room = query.room if query.room

    try
      data = req.body
      console.log data
      robot.send envelope, req.body

    catch error
      console.log "server-notify error: #{error}. Data: #{req.body}"
      console.log error.stack
