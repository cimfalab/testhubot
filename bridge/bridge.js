var util = require('util');
var express = require('express');
var http = require('http');

var app = module.exports = express();

var HUBOT_URL = 'https://testhubot-5033.herokuapp.com';
var PATH_NOTIFY = '/hubot/jenkins-notify';

app.set('port', process.env.PORT || 5033);

app.post(PATH_NOTIFY, function (req, res) {
  console.log('post!');
  var request = require('request');
  var pipe = req.pipe(request.post(HUBOT_URL + PATH_NOTIFY));
  var response = [];

  pipe.on('data', function (chunk) {
    response.push(chunk);
  });

  pipe.on('end', function () {
    var res2 = Buffer.concat(response);
    //console.log(res2);
    res.end();
  });
});

http.createServer(app).listen(app.get('port'), function (){
  console.log('Express server listening on port ' + app.get('port'));
});
