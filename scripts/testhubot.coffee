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

  ###
  httpClient = robot.http('http://openapi.seoul.go.kr:8088/69757368647474613437446b50476d/json/RealtimeCityAir/1/5/')
  #httpClient = robot.http('http://127.0.0.1:8088/69757368647474613437446b50476d/json/RealtimeCityAir/1/5/')
    .header('Accept', 'application/json')
    .header('Connection', 'keep-alive')
  httpClient.get() (err, res, body) ->
    robot.logger.info res.statusCode
    robot.logger.info body
  ###

  ###
  options = {
    hostname: '127.0.0.1',
    port: 8088,
    path: '/69757368647474613437446b50476d/json/RealtimeCityAir/1/5/',
    method: 'GET',
    headers: {
      'Accept': 'application/json'
    }
  }

  req = require('http').request options, (res) ->
    console.log 'STATUS: ' + res.statusCode
    console.log 'HEADERS: ' + JSON.stringify(res.headers)
    res.setEncoding('utf8')
    res.on 'data', (chunk) ->
      console.log 'BODY: ' + chunk

  req.on 'error', (e) ->
    console.log 'problem with request: ' + e.message

  req.end()
  ###

  everyFiveMinutes = ->
    robot.logger.info 'I will nag you every 5 minutes'
    #robot.messageRoom room, 'I will nag you every 5 minutes'

  workdaysLunch = ->
    msg = '#Hubot 알림# 곧 점심 시간입니다. 챙겨야 할 것: 식권, 자기 방과 옆 방의 동료'
    #robot.logger.info msg
    robot.send user, msg

  workdaysQuit = ->
    # 미세먼지
    http = require 'http'
    msgDust = ''
    # 69757368647474613437446b50476d is API key
    path = 'http://openapi.seoul.go.kr:8088/69757368647474613437446b50476d/json/RealtimeCityAir/1/5/%EB%8F%99%EB%82%A8%EA%B6%8C'
    http.get(path, (res) ->
      body = ''
      res.on 'data', (data) ->
        body += data
      res.on 'end', () ->
        try body = JSON.parse(body) catch e then console.log 'ERROR!!!', e

        time = body.RealtimeCityAir.row[0].MSRDT
        pm10 = body.RealtimeCityAir.row[0].PM10
        pm25 = body.RealtimeCityAir.row[0].PM25
        #o3 = body.RealtimeCityAir.row[0].O3
        #no2 = body.RealtimeCityAir.row[0].NO2
        #co = body.RealtimeCityAir.row[0].CO
        #so2 = body.RealtimeCityAir.row[0].SO2
        currentAir = body.RealtimeCityAir.row[0].IDEX_NM
        currentAirValue = body.RealtimeCityAir.row[0].IDEX_MVL

        #msgDust = "현재 공기상태 > #{currentAir}, 공기상태 평점 > #{currentAirValue}, 측정시간 > #{time}, 미세먼지(㎍/㎥)(pm10)값 > #{pm10}, 초미세먼지농도(㎍/㎥)(pm25)값 > #{pm25}, 오존 > #{o3}, 이산화질소 > #{no2}, 아황산가스 > #{so2}, 일산화탄소 > #{co}"
        msgDust = "[#{time}] 현재 공기상태: #{currentAir} / 공기상태 평점: #{currentAirValue} / 미세먼지(㎍/㎥)(pm10)값: #{pm10} / 초미세먼지농도(㎍/㎥)(pm25)값: #{pm25}"

        getWeather(msgDust);
    ).on 'error', (e) ->
      console.log 'Got error: ' + e.message

    getWeather = (msgDust) ->
      robot.http('http://weather.service.msn.com/data.aspx?weadegreetype=C&culture=ko-KR&weasearchstr=%EC%88%98%EB%82%B4')
        .header('Accept', 'application/xml')
        .get() (err, res, body) ->
          parseString = require('xml2js').parseString
          parseString body, (err, result) ->
            weather = result.weatherdata.weather[0]
            current = weather.current[0].$
            tomorrow = weather.forecast[1].$
            # The latter type of string interpolation only works when you use double quotes.
            msg = "#Hubot 알림# 하루 업무를 마무리할 시간이네요.\n" +
                "[현재날씨] #{current.skytext} (#{current.temperature}°)\n" +
                "[내일날씨] #{tomorrow.skytextday} (#{tomorrow.high}° #{tomorrow.low}°)\n" +
                "[미세먼지] #{msgDust}"

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

  #robot.hear /장소 : (.*) 회의실/i, (msg) ->
  #  msg.send "#Hubot 캠페인# 회의는 간결하게, 회의 시간에는 적극적이고 겸손하게 자신의 의견을 얘기해 주세요~"

  # "#회의"라는 단어가 포함되어 있으면 해당 메시지에서 시간("yyyy.mm.dd hour:min" 포맷만 인식)을 추출해 알람으로 등록
  robot.hear /#회의(.*)/i, (msg) ->
    fullMsg = msg.message.rawText
    beforeMin = 30
    console.log fullMsg
    time = fullMsg.match(/(\d{4}).(\d{1,2}).(\d{1,2})\s+\d{2}:\d{2}/)[0]
    return "" if time is null or time is ""
    cronDate = new Date(time)
    cronDate.setMinutes cronDate.getMinutes() - beforeMin
    CronJob = require("cron").CronJob
    job = new CronJob(cronDate, ->
      cronMsg = "#Hubot 알림# 회의 30분 전입니다.\n" + fullMsg
      robot.send user, cronMsg
      @stop()
    , null, true, tz)
    #msg.send "회의 알람이 등록되었습니다."

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
