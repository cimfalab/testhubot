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
      #data = querystring.stringify(req.body)
      #data = JSON.stringify(req.body)
      data = "#{req.body.title}\n#{req.body.data}\n"
      console.log data
      robot.send envelope, data

    catch error
      console.log "server-notify error: #{error}. Data: #{req.body}"
      console.log error.stack
