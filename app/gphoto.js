var fs        = require('fs');
var util      = require('util');
var request   = require('request');
var minimist  = require('minimist');

var args = minimist(process.argv.slice(2), {
  string: 'id',
  string: 'name',
  '--': true
});

var id                      = args.id,
    fname                   = args.name,
    fpath                   = ['/var/dataku', process.env.WNUM, fname].join('/'),
    cookie                  = process.env.API_COOKIE,
    x_guploader_client_info = process.env.X_GUPLOADER_CLIENT_ID,
    effective_id            = process.env.EFFECTIVE_ID,
    api_log_url             = process.env.API_URL,
    api_upload_url          = process.env.API_UPLOAD_URL,
    size;

function post_user_agent() {
  return "Mozilla/5.0 (Windows NT 10.0; rv:44.0) Gecko/20100101 Firefox/44.0"
}

function post_headers() {
  return {
    "Host": "photos.google.com",
    "User-Agent": post_user_agent(),
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.5",
    "Accept-Encoding": "gzip, deflate, br",
    "DNT": "1",
    "Referer": "https://photos.google.com",
    "Cookie": (cookie).toString(),
    "Connection": "keep-alive"
  }
}

function post_headers_init() {
  return util._extend(post_headers(), {
    "X-GUploader-Client-Info": (x_guploader_client_info).toString(),
    "Content-Type"           : "application/x-www-form-urlencoded;charset=utf-8"
  });
}

function post_headers_upload() {
  return util._extend(post_headers(), {
    "X-HTTP-Method-Override": "PUT",
    "Content-Type": "application/octet-stream",
    "X-GUploader-No-308": "yes",
    "Content-Length": parseInt(size),
    "Transfer-Encoding": "chunked"
  });
}

function post_data() {
  return {
    "protocolVersion": "0.8",
    "createSessionRequest": {
      "fields": [
        {
          "external": {
            "name": "file",
            "filename": (fname).toString(),
            "put": {
            },
            "size": parseInt(size)
          }
        },
        {
          "inlined": {
            "name": "auto_create_album",
            "content": "camera_sync.active",
            "contentType": "text/plain"
          }
        },
        {
          "inlined": {
            "name": "auto_downsize",
            "content": "true",
            "contentType": "text/plain"
          }
        },
        {
          "inlined": {
            "name": "storage_policy",
            "content": "use_manual_setting",
            "contentType": "text/plain"
          }
        },
        {
          "inlined": {
            "name": "disable_asbe_notification",
            "content": "true",
            "contentType": "text/plain"
          }
        },
        {
          "inlined": {
            "name": "client",
            "content": "photosweb",
            "contentType": "text/plain"
          }
        },
        {
          "inlined": {
            "name": "effective_id",
            "content": (effective_id).toString(),
            "contentType": "text/plain"
          }
        },
        {
          "inlined": {
            "name": "owner_name",
            "content": (effective_id).toString(),
            "contentType": "text/plain"
          }
        },
        {
          "inlined": {
            "name": "timestamp_ms",
            "content": (Date.now()).toString(),
            "contentType": "text/plain"
          }
        }
      ]
    }
  }
}

function gen_upload_url() {
  request({
    method: 'POST',
    url: api_upload_url,
    headers: post_headers_init(),
    body: JSON.stringify(post_data())
  }, function(err, resp, body) {
    if (err || resp.statusCode !== 200) {
      log_http({msg: 'Failed to generate upload url', body: err});
    } else {
      var upload_url = JSON.parse(body).sessionStatus.externalFieldTransfers[0].putInfo.url;
      if (upload_url) {
        upload_file(upload_url);
      } else {
        log_http({msg: 'Response not containing valid upload url', body: body});
      }
    }
  });
}

function upload_file(upload_url) {
  request({
    method: 'POST',
    url: upload_url,
    headers: post_headers_upload(),
    body: fs.createReadStream(fpath)
  }, function(err, resp, body) {
    if (err || resp.statusCode !== 200) {
      log_http({msg: 'Failed uploading file', body: err});
    } else {
      var parsed_response = JSON.parse(body);
      if (!parsed_response.errorMessage) {
        log_http(body, true);
        fs.unlink(fpath);
      } else {
        log_http({msg: 'Error uploading file', body: body});
      }
    }
  });
}

function log_http(comment, success) {
  request.post({
    url: api_log_url,
    qs: {
      do: success ? 'uploaded' : 'error',
      id: id
    },
    form: {
      comment: comment
    }
  });
}

fs.stat(fpath, function(err, file) {
  if (err) {
    log_http({msg: 'File not found', body: err});
  } else {
    size = file.size;
    gen_upload_url();
  }
});
