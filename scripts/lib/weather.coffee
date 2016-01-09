# Description:
#   Example scripts for you to examine and try out.
#
# Commands:
#
# Notes:
#   They are commented out by default, because most of them are pretty silly and
#   wouldn't be useful and amusing enough for day to day huboting.
#   Uncomment the ones you want to try and experiment with.
#
#   These are from the scripting documentation: https://github.com/github/hubot/blob/master/docs/scripting.md

http = require('http')

HOST = 'apis.skplanetx.com'
APP_KEY = '4bc92446-d191-39a5-936b-0e73f2c64fa5'

agent = null

weather =
  getVerboseWeatherByPlanet: (cityAir, callback) ->
    # city=경기&county=성남시 분당구&village=수내
    options = {
      agent: agent
      hostname: HOST
      path: '/weather/forecast/3days?version=1&lat=37.3713180&lon=127.1223530&foretxt=Y'
      headers: {
        'appKey': APP_KEY
        'Accept': 'application/json'
      }
    }

    req = http.get options, (res) ->
      bodyChunks = []
      res.on('data', (chunk) ->
        bodyChunks.push chunk
        return
      ).on 'end', ->
        body = Buffer.concat(bodyChunks)
        msg = ""
        try
          parseString = JSON.parse(body)
          if parseString.result.code is 9200
            weather = parseString.weather.forecast3days[0]
            current = weather.fcstext.text1
            tomorrow = weather.fcstext.text2
            msg = msg +
                "[기상개황(오늘)]\n#{current}\n\n" +
                "[기상개황(내일)]\n#{tomorrow}\n"
        finally
          console.log msg
          callback msg
        return

    req.on 'error', (e) ->
      console.log 'ERROR: ' + e.message
      return

  getWeatherByPlanet: (cityAir, callback) ->
    lat = 37.3713180
    lon = 127.1223530
    options = {
      agent: agent
      hostname: HOST
      path: "/weather/current/hourly?version=1&lat=#{lat}&lon=#{lon}"
      headers: {
        'appKey': APP_KEY
        'Accept': 'application/json'
      }
    }

    req = http.get options, (res) ->
      bodyChunks = []
      res.on('data', (chunk) ->
        bodyChunks.push chunk
        return
      ).on 'end', ->
        body = Buffer.concat(bodyChunks)
        msg = ""
        currentString = JSON.parse(body)
        if currentString.result.code is 9200
          current = currentString.weather.hourly[0]
          # 단기 예보
          options.path = "/weather/forecast/3days?version=1&lat=#{lat}&lon=#{lon}"
          req = http.get options, (res) ->
            bodyChunks = []
            res.on('data', (chunk) ->
              bodyChunks.push chunk
              return
            ).on 'end', ->
              body = Buffer.concat(bodyChunks)
              try
                forecastString = JSON.parse(body)
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

          req.on 'error', (e) ->
            console.log 'ERROR: ' + e.message
            return

    req.on 'error', (e) ->
      console.log 'ERROR: ' + e.message
      return

module.exports = weather
