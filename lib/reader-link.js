
/*

  PrismTech licenses this file to You under the Apache License, Version 2.0
  (the "License"); you may not use this file except in compliance with the
  License and with the PrismTech Vortex product. You may obtain a copy of the
  License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
  License and README for the specific language governing permissions and
  limitations under the License.
 */

(function() {
  var Config, EventEmitter, ReadLinkWorker, WebSocket, connected, disconnect, drt, setupReaderSocket, socketMap, urlMap, util, z_;

  EventEmitter = require('events');

  util = require('util');

  WebSocket = require('ws');

  z_ = require('./coffez.js');

  drt = require('./control-commands.js');

  Config = require('./config.js');

  connected = false;

  socketMap = {};

  urlMap = {};

  setupReaderSocket = function(worker, url, eid) {
    var socket;
    socket = new WebSocket(url);
    console.log("[reader-link] Created Websocket for DR at " + url);
    socketMap[eid] = socket;
    urlMap[eid] = url;
    socket.onopen = (function(_this) {
      return function(evt) {
        console.log("[reader-link] DR Websocket is open");
        connected = true;
        return worker.emit('postMessage', drt.OnConnectedDataReader(url, eid));
      };
    })(this);
    socket.onclose = (function(_this) {
      return function(evt) {
        console.log("[reader-link] DR Websocket is closed");
        delete socketMap[eid];
        delete urlMap[eid];
        return worker.emit('postMessage', drt.OnDisconnectedDataReader(url, eid));
      };
    })(this);
    return socket.onmessage = (function(_this) {
      return function(evt) {
        evt = drt.OnDataAvailable(evt.data, eid);
        return worker.emit('postMessage', drt.OnDataAvailable(evt.data, eid));
      };
    })(this);
  };

  disconnect = function(worker) {
    var eid, s;
    if (connected) {
      connected = false;
      for (eid in socketMap) {
        s = socketMap[eid];
        s.close();
        worker.emit('postMessage', drt.OnDisconnectedDataReader(urlMap[eid], eid));
      }
      socketMap = {};
      return urlMap = {};
    }
  };

  ReadLinkWorker = (function() {
    function ReadLinkWorker() {
      EventEmitter.call(this);
    }

    util.inherits(ReadLinkWorker, EventEmitter);

    ReadLinkWorker.prototype.postMessage = function(cmd) {
      switch (false) {
        case !z_.match(cmd.h, drt.ConnectDataReaderCmd):
          console.log("[reader-link] Setting-up Socket for : " + cmd.eid + ", at " + cmd.url);
          return setupReaderSocket(this, cmd.url, cmd.eid);
        case !z_.match(cmd.h, drt.Connect):
          return connect();
        case !z_.match(cmd.h, drt.Disconnect):
          return disconnect(this);
        default:
          return console.log("[reader-link] Reader Worker Received Unknown Command!");
      }
    };

    return ReadLinkWorker;

  })();

  module.exports = ReadLinkWorker;

}).call(this);
