var google        = require('googleapis');
var http          = require('http');
var fs            = require('fs');
var log4js        = require('log4js');
var minimist      = require('minimist');
var url           = require('url');

var args = minimist(process.argv.slice(2), {
  string: 'id',
  string: 'name',
  '--': true
});

var id    = args.id;
var fname = args.name;
var wnum  = process.env.WNUM;
var fpath = '/var/dataku/' + wnum + '/' + fname;

log4js.configure('log.json');
var logger        = log4js.getLogger('uploaded');

var client_id     = process.env.CLIENT_ID;
var client_secret = process.env.CLIENT_SECRET;
var redirect_uri  = 'http://127.0.0.1:3000';

var oauth2        = new google.auth.OAuth2(client_id, client_secret, redirect_uri);
var refresh_token = process.env.REFRESH_TOKEN;

oauth2.setCredentials({
  refresh_token: refresh_token
});

var drive = google.drive({ version: 'v3', auth: oauth2 });
drive.files.create({
    resource: {
      name: fname,
      mimeType: "video/mp4"
    },
    media: {
      mimeType: "video/mp4",
      body: fs.createReadStream(fpath)
    }
  }, function(err, r) {
    if (!err && r && r.id) {
      logger.info(id + ' success: ' + r.id);
       var opts = {
        host: url.parse(process.env.API_URL).host,
        path: '/admin/bigo/api.json?do=uploaded&id=' + id + '&comment=' + r.id,
        headers: {
          'Connection': 'close'
        }
      };

      var req = http.get(opts, function(response) {
        response.on('end', function () {
        });
      });
      logger.info(id + ' done, deleting file');
      fs.unlink(fpath);
      req.shouldKeepAlive = false;
      req.end();

    } else {
      logger.warn(id + ' failed to upload!');
    }
});
