# Description:
#   Example scripts for you to examine and try out.
#
# Commands:
#   hubot air - Reply with city air information and guide
#   hubot weather - Reply with weather information about today and tomorrow
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

  workdaysLunch = ->
    msg = '#Hubot 알림# 곧 점심 시간입니다. 챙겨야 할 것: 식권, 자기 방과 옆 방의 동료, 비더레^^'
    #robot.logger.info msg
    robot.send user, msg

  getCityAir = (callback) ->
    # 미세먼지
    http = require 'http'
    text = ''
    # 69757368647474613437446b50476d is API key
    #path = 'http://openapi.seoul.go.kr:8088/69757368647474613437446b50476d/json/RealtimeCityAir/1/5/%EB%8F%99%EB%82%A8%EA%B6%8C'
    #path = 'http://115.84.165.45:8088/69757368647474613437446b50476d/json/RealtimeCityAir/1/5/%EB%8F%99%EB%82%A8%EA%B6%8C'
    options = {
      #agent: agent,
      host: 'openapi.seoul.go.kr',
      hostname: 'openapi.seoul.go.kr',
      port: 8088,
      path: '/69757368647474613437446b50476d/json/RealtimeCityAir/1/5/%EB%8F%99%EB%82%A8%EA%B6%8C',
      method: 'GET',
      headers: {
        'Accept': 'application/json'
      }
    }

    http.get(options, (res) ->
      body = ''
      res.on 'data', (data) ->
        body += data
      res.on 'end', () ->
        try body = JSON.parse(body) catch e then console.log 'Got error when parsing: ' + e.message

        time = body.RealtimeCityAir.row[0].MSRDT
        pm10 = body.RealtimeCityAir.row[0].PM10
        pm25 = body.RealtimeCityAir.row[0].PM25
        #o3 = body.RealtimeCityAir.row[0].O3
        #no2 = body.RealtimeCityAir.row[0].NO2
        #co = body.RealtimeCityAir.row[0].CO
        #so2 = body.RealtimeCityAir.row[0].SO2
        currentAir = body.RealtimeCityAir.row[0].IDEX_NM
        currentAirValue = body.RealtimeCityAir.row[0].IDEX_MVL

        #text = "현재 공기상태 > #{currentAir}, 공기상태 평점 > #{currentAirValue}, 측정시간 > #{time}, 미세먼지(㎍/㎥)(pm10)값 > #{pm10}, 초미세먼지농도(㎍/㎥)(pm25)값 > #{pm25}, 오존 > #{o3}, 이산화질소 > #{no2}, 아황산가스 > #{so2}, 일산화탄소 > #{co}"
        text = "현재 공기상태: #{currentAir} / 공기상태 평점: #{currentAirValue} / 미세먼지(㎍/㎥)(pm10)값: #{pm10} / 초미세먼지농도(㎍/㎥)(pm25)값: #{pm25}"

        callback(text)
    ).on 'error', (e) ->
      console.log 'Got error: ' + e.message, options
      callback(e.message)

  workdaysQuit = ->
    getCityAir (cityAir) ->
      getWeatherByPlanet cityAir, (text) ->
        msg = "#Hubot 알림# 하루 업무를 마무리할 시간이네요.\n" + text
        robot.send user, msg

  getVerboseWeatherByPlanet = (cityAir, callback) ->
    console.log 'getVerboseWeatherByPlanet'
    options = {
      agent: agent
    }
    robot.http('http://apis.skplanetx.com/weather/forecast/3days?version=1&lat=37.3713180&lon=127.1223530&foretxt=Y', options)
    #robot.http('http://apis.skplanetx.com/weather/forecast/3days?version=1&city=경기&county=성남시 분당구&village=수내&foretxt=Y')
      .header('appKey', '4bc92446-d191-39a5-936b-0e73f2c64fa5')
      .header('Accept', 'application/json')
      .get() (err, res, body) ->
        if err
          res.send "Encountered an error :( #{err}"
          return

        msg = ""
        parseString = JSON.parse(body)
        console.log parseString
        try
          if parseString.result.code is 9200
            weather = parseString.weather.forecast3days[0]
            current = weather.fcstext.text1
            tomorrow = weather.fcstext.text2
            msg = msg +
                "[기상개황(오늘)]\n#{current}\n\n" +
                "[기상개황(내일)]\n#{tomorrow}\n"
        finally
          callback msg

  getWeatherByPlanet = (cityAir, callback) ->
    lat = 37.3713180
    lon = 127.1223530
    robot.http("http://apis.skplanetx.com/weather/current/hourly?version=1&lat=#{lat}&lon=#{lon}")
      .header('appKey', '4bc92446-d191-39a5-936b-0e73f2c64fa5')
      .header('Accept', 'application/json')
      .get() (err, res, body) ->
        msg = ""
        currentString = JSON.parse(body)
        if currentString.result.code is 9200
          current = currentString.weather.hourly[0]
          # 단기 예보
          robot.http("http://apis.skplanetx.com/weather/forecast/3days?version=1&lat=#{lat}&lon=#{lon}")
            .header('appKey', '4bc92446-d191-39a5-936b-0e73f2c64fa5')
            .header('Accept', 'application/json')
            .get() (err, res, body) ->
              forecastString = JSON.parse(body)
              try
                if forecastString.result.code is 9200
                  forecast3days = forecastString.weather.forecast3days[0]
                  tomorrow =
                    high: forecast3days.fcstdaily.temperature.tmax2day
                    low: forecast3days.fcstdaily.temperature.tmin2day
                    sky:
                      name: forecast3days.fcst3hour.sky.name16hour
                  msg = msg +
                    "[현재날씨] #{current.sky.name} (#{current.temperature.tc}°)\n" +
                    "[내일날씨] 오전 9시 기준 #{tomorrow.sky.name} (#{tomorrow.high}° #{tomorrow.low}°) (자세한 날씨는 /dm @wsdkbot weather)\n"
              finally
                msg = msg +
                    "[미세먼지] #{cityAir}"
              callback msg

  workdaysScrum = (place) ->
    msg = "#Hubot 알림# 10분 뒤 Daily Scrum 시작(#{place})입니다. 각자 현황판 업데이트 후 정시에 체크인해 주세요."
    robot.send user, msg

  robot.logger.info "Initializing CronJob... #{user.room}"
  require('time')

  #ProxyAgent = require('proxy-agent')
  #proxy = process.env.http_proxy || 'http://168.219.61.252:8080';
  #robot.logger.info "Setting proxy...", proxy
  #agent = new ProxyAgent(proxy)
  agent = null

  CronJob = require('cron').CronJob
  tz = 'Asia/Seoul'
  new CronJob('0 15 11 * * 1-5', workdaysLunch, null, true, tz)
  new CronJob('0 0 18 * * 1-5', workdaysQuit, null, true, tz)
  new CronJob('0 20 10 * * 1', ->
    workdaysScrum('월요일 1113호')
  , null, true, tz)
  new CronJob('0 20 10 * * 2-4', ->
    workdaysScrum('화-목요일 11-2 회의실')
  , null, true, tz)
  new CronJob('0 50 12 * * 5', ->
    workdaysScrum('금요일 11-2 회의실')
  , null, true, tz)

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

  robot.respond /(^|\s)air|미세먼지(?=\s|$)/i, (msg) ->
    #help send message
    getCityAir (cityAir) ->
      msg.send "[미세먼지] #{cityAir}\n" +
                "[Air quality index]\n" +
                " 0 - 50  좋음  대기오염 관련 질환자군에서도 영향이 유발되지 않을 수준\n" +
                " 51 -100 보통  환자군에게 만성 노출시 경미한 영향이 유발될 수 있는 수준\n" +
                " 101-150 민감군영향   환자군 및 민감군에게 유해한 영향이 유발될 수 있는 수준\n" +
                " 151-200 나쁨  환자군 및 민감군(어린이, 노약자 등)에게 유해한 영향 유발, 일반인도 건강상 불쾌감을 경험할 수 있는 수준\n" +
                " 201-300 매우나쁨    환자군 및 민감군에게 급성 노출시 심각한 영향 유발, 일반인도 약한 영향이 유발될 수 있는 수준\n" +
                " 300+    위험  환자군 및 민감군에게 응급 조치가 발생되거나, 일반인에게 유해한 영향이 유발될 수 있는 수준"
    return

  robot.respond /(^|\s)weather(?=\s|$)/i, (msg) ->
    getVerboseWeatherByPlanet '', (text) ->
      msg.send text
    return

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
