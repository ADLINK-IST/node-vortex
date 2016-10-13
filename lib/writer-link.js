
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
  var Config, EventEmitter, WebSocket, WriteLinkWorker, connected, disconnect, drt, setupWriterSocket, socketMap, urlMap, util, z_;

  EventEmitter = require('events');

  util = require('util');

  WebSocket = require('ws');

  z_ = require('./coffez.js');

  drt = require('./control-commands.js');

  Config = require('./config.js');

  connected = false;

  socketMap = {};

  urlMap = {};

  setupWriterSocket = function(worker, url, eid) {
    var socket;
    socket = new WebSocket(url);
    console.log("[writer-link] Created Websocket for DW at " + url);
    socketMap[eid] = socket;
    urlMap[eid] = url;
    socket.onopen = (function(_this) {
      return function(evt) {
        console.log("[writer-link] DW Writer Websocket is open");
        connected = true;
        return worker.emit('postMessage', drt.OnConnectedDataWriter(url, eid));
      };
    })(this);
    return socket.onclose = (function(_this) {
      return function(evt) {
        console.log("[writer-link] DW Websocket is closed at " + url + ", eid " + eid);
        delete socketMap[eid];
        return worker.emit('postMessage', drt.OnDisconnectedDataWriter(url, eid));
      };
    })(this);
  };

  disconnect = function() {
    var eid, s;
    if (connected) {
      connected = false;
      for (eid in socketMap) {
        s = socketMap[eid];
        s.close();
      }
      socketMap = {};
      return urlMap = {};
    }
  };

  WriteLinkWorker = (function() {
    function WriteLinkWorker() {
      EventEmitter.call(this);
    }

    util.inherits(WriteLinkWorker, EventEmitter);

    WriteLinkWorker.prototype.postMessage = function(cmd) {
      var e, s, socket;
      switch (false) {
        case !z_.match(cmd.h, drt.ConnectDataWriterCmd):
          console.log("[writer-link] Setting-up Socket for DW : " + cmd.eid + ", at " + cmd.url);
          return setupWriterSocket(this, cmd.url, cmd.eid);
        case !z_.match(cmd.h, drt.WriteDataCmd):
          socket = socketMap[cmd.eid];
          if (socket && socket.readyState === 1) {
            s = cmd.data;
            try {
              return socket.send("write/" + s);
            } catch (_error) {
              e = _error;
              console.log("[writer-link] Exception while sending data");
              return console.log(JSON.stringify(e));
            }
          }
          break;
        case !z_.match(cmd.h, drt.DisposeDataCmd):
          socket = socketMap[cmd.eid];
          if (socket && socket.readyState === 1) {
            s = cmd.data;
            try {
              return socket.send("dispose/" + s);
            } catch (_error) {
              e = _error;
              console.log("[writer-link] Exception while sending data");
              return console.log(JSON.stringify(e));
            }
          }
          break;
        case !z_.match(cmd.h, drt.Disconnect):
          return disconnect();
        default:
          return console.log("[writer-link] Reader Worker Received Unknown Command!");
      }
    };

    return WriteLinkWorker;

  })();

  module.exports = WriteLinkWorker;

}).call(this);
