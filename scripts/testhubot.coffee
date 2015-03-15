# Description:
#   Example scripts for you to examine and try out.
#
# Notes:
#   They are commented out by default, because most of them are pretty silly and
#   wouldn't be useful and amusing enough for day to day huboting.
#   Uncomment the ones you want to try and experiment with.
#
#   These are from the scripting documentation: https://github.com/github/hubot/blob/master/docs/scripting.md

module.exports = (robot) ->

  user = {}
  user.room = process.env.HUBOT_DEPLOY_ROOM || '#general'
  #user.user = 'mariah'
  user.type = 'groupchat'

  everyFiveMinutes = ->
    robot.logger.info 'I will nag you every 5 minutes'
    #robot.messageRoom room, 'I will nag you every 5 minutes'

  workdaysLunch = ->
    msg = '#Hubot 알림# 곧 점심 시간입니다. 챙겨야 할 것: 식권, 자기 방과 옆 방의 동료'
    #robot.logger.info msg
    robot.send user, msg

  workdaysQuit = ->
    robot.http('http://weather.service.msn.com/data.aspx?weadegreetype=C&culture=ko-KR&weasearchstr=%EC%88%98%EB%82%B4')
        .header('Accept', 'application/xml')
        .get() (err, res, body) ->
          parseString = require('xml2js').parseString
          parseString body, (err, result) ->
            weather = result.weatherdata.weather[0]
            current = weather.current[0].$
            tomorrow = weather.forecast[1].$
            # The latter type of string interpolation only works when you use double quotes.
            msg = "#Hubot 알림# 하루 업무를 마무리할 시간이네요. 현재 날씨 '#{current.skytext} (#{current.temperature}°)' / 내일 날씨 '#{tomorrow.skytextday} (#{tomorrow.high}° #{tomorrow.low}°)'."
            robot.send user, msg

  robot.logger.info "Initializing CronJob... #{user.room}"
  require('time')
  CronJob = require('cron').CronJob
  tz = 'Asia/Seoul'
  #new CronJob('0 */5 * * * *', everyFiveMinutes, null, true, tz)
  new CronJob('0 10 11 * * 1-5', workdaysLunch, null, true, tz)
  new CronJob('0 0 18 * * 1-5', workdaysQuit, null, true, tz)

  robot.respond //i, (msg) ->
    msg.send "안녕하세요? Hubot입니다."

  robot.hear /회의/i, (msg) ->
    msg.send "#Hubot 캠페인# 회의는 간결하게, 회의 시간에는 적극적이고 겸손하게 자신의 의견을 얘기해 주세요~"

  # robot.hear /badger/i, (msg) ->
  #   msg.send "Badgers? BADGERS? WE DON'T NEED NO STINKIN BADGERS"
  #
  # robot.respond /open the (.*) doors/i, (msg) ->
  #   doorType = msg.match[1]
  #   if doorType is "pod bay"
  #     msg.reply "I'm afraid I can't let you do that."
  #   else
  #     msg.reply "Opening #{doorType} doors"
  #
  # robot.hear /I like pie/i, (msg) ->
  #   msg.emote "makes a freshly baked pie"
  #
  # lulz = ['lol', 'rofl', 'lmao']
  #
  # robot.respond /lulz/i, (msg) ->
  #   msg.send msg.random lulz
  #
  # robot.topic (msg) ->
  #   msg.send "#{msg.message.text}? That's a Paddlin'"
  #
  #
  # enterReplies = ['Hi', 'Target Acquired', 'Firing', 'Hello friend.', 'Gotcha', 'I see you']
  # leaveReplies = ['Are you still there?', 'Target lost', 'Searching']
  #
  # robot.enter (msg) ->
  #   msg.send msg.random enterReplies
  # robot.leave (msg) ->
  #   msg.send msg.random leaveReplies
  #
  # answer = process.env.HUBOT_ANSWER_TO_THE_ULTIMATE_QUESTION_OF_LIFE_THE_UNIVERSE_AND_EVERYTHING
  #
  # robot.respond /what is the answer to the ultimate question of life/, (msg) ->
  #   unless answer?
  #     msg.send "Missing HUBOT_ANSWER_TO_THE_ULTIMATE_QUESTION_OF_LIFE_THE_UNIVERSE_AND_EVERYTHING in environment: please set and try again"
  #     return
  #   msg.send "#{answer}, but what is the question?"
  #
  # robot.respond /you are a little slow/, (msg) ->
  #   setTimeout () ->
  #     msg.send "Who you calling 'slow'?"
  #   , 60 * 1000
  #
  # annoyIntervalId = null
  #
  # robot.respond /annoy me/, (msg) ->
  #   if annoyIntervalId
  #     msg.send "AAAAAAAAAAAEEEEEEEEEEEEEEEEEEEEEEEEIIIIIIIIHHHHHHHHHH"
  #     return
  #
  #   msg.send "Hey, want to hear the most annoying sound in the world?"
  #   annoyIntervalId = setInterval () ->
  #     msg.send "AAAAAAAAAAAEEEEEEEEEEEEEEEEEEEEEEEEIIIIIIIIHHHHHHHHHH"
  #   , 1000
  #
  # robot.respond /unannoy me/, (msg) ->
  #   if annoyIntervalId
  #     msg.send "GUYS, GUYS, GUYS!"
  #     clearInterval(annoyIntervalId)
  #     annoyIntervalId = null
  #   else
  #     msg.send "Not annoying you right now, am I?"
  #
  #
  # robot.router.post '/hubot/chatsecrets/:room', (req, res) ->
  #   room   = req.params.room
  #   data   = JSON.parse req.body.payload
  #   secret = data.secret
  #
  #   robot.messageRoom room, "I have a secret: #{secret}"
  #
  #   res.send 'OK'
  #
  # robot.error (err, msg) ->
  #   robot.logger.error "DOES NOT COMPUTE"
  #
  #   if msg?
  #     msg.reply "DOES NOT COMPUTE"
  #
  # robot.respond /have a soda/i, (msg) ->
  #   # Get number of sodas had (coerced to a number).
  #   sodasHad = robot.brain.get('totalSodas') * 1 or 0
  #
  #   if sodasHad > 4
  #     msg.reply "I'm too fizzy.."
  #
  #   else
  #     msg.reply 'Sure!'
  #
  #     robot.brain.set 'totalSodas', sodasHad+1
  #
  # robot.respond /sleep it off/i, (msg) ->
  #   robot.brain.set 'totalSodas', 0
  #   robot.respond 'zzzzz'
