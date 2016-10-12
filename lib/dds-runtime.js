
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
  var Coffez, Commands, ControlLink, DDS, ReadWorker, Runtime, WriteWorker, currentScriptPath, dds, drt, getCurrentPath, z_,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  DDS = require('./dds.js');

  Commands = require('./control-commands.js');

  ControlLink = require('./control-link.js');

  ReadWorker = require('./reader-link.js');

  WriteWorker = require('./writer-link.js');

  Coffez = require('./coffez.js');

  dds = DDS;

  dds.runtime = {};

  z_ = Coffez;


  /**
  Define the dds.runtime namespace.
  @namespace dds.runtime
   */

  drt = require('./control-commands.js');

  getCurrentPath = function() {
    var scriptFolder, scriptPath, scriptTag;
    scriptTag = document.getElementsByTagName('script');
    scriptTag = scriptTag[scriptTag.length - 1];
    scriptPath = scriptTag.src;
    scriptFolder = scriptPath.substr(0, scriptPath.lastIndexOf('/'));
    return scriptFolder;
  };

  currentScriptPath = '';

  if (typeof document !== 'undefined') {
    currentScriptPath = getCurrentPath();
  }


  /**
  Constructs a DDS Runtime object
  @constructor
  @classdesc maintains the connection with the server, re-establish the connection
  if dropped and mediates the `DataReader` and `DataWriter` communication.
   @memberof dds.runtime
   */

  Runtime = (function() {
    function Runtime() {
      this.isClosed = bind(this.isClosed, this);
      this.isConnected = bind(this.isConnected, this);
      this.close = bind(this.close, this);
      this.onRcvWorkerMessage = bind(this.onRcvWorkerMessage, this);
      this.onSendWorkerMessage = bind(this.onSendWorkerMessage, this);
      this.onCtrlWorkerMessage = bind(this.onCtrlWorkerMessage, this);
      this.disposeData = bind(this.disposeData, this);
      this.writeData = bind(this.writeData, this);
      this.sn = 0;
      this.eidCount = 0;
      this.drmap = {};
      this.dwmap = {};
      this.tmap = {};
      this.onconnect = function(evt) {
        console.log("[dds-runtime]: onconnect");
        return this.connected = true;
      };
      this.onclose = function(evt) {
        console.log("[dds-runtime]: onclose");
        this.connected = false;
        return this.closed = true;
      };
      this.ondisconnect = function(evt) {
        console.log("[dds-runtime]: ondisconnect");
        return this.connected = false;
      };
      this.connected = false;
      this.closed = false;
      this.needToReEstablishConnections = false;
      this.ctrlLink = new ControlLink();
      console.log("[dds-runtime]: ctrlLink (" + this.ctrlLink + ")");
      this.ctrlLink.on('postMessage', this.onCtrlWorkerMessage);
      this.sendWorker = new WriteWorker();
      this.rcvWorker = new ReadWorker();
      this.sendWorker.on('postMessage', this.onSendWorkerMessage);
      this.rcvWorker.on('postMessage', this.onRcvWorkerMessage);
      this.server = "disconnected";
    }

    Runtime.prototype.generateEntityId = function() {
      var id;
      id = this.eidCount;
      this.eidCount += 1;
      return id;
    };


    /**
    Connect the runtime to the server. If the runtime is already connected an exception is thrown
        @param {string} srv - Vortex Web server WebSocket URL
        @param {string} authToken - Authorization token
    @memberof! dds.runtime.Runtime#
    @function connect
     */

    Runtime.prototype.connect = function(srv, authToken) {
      var cmd;
      this.server = srv;
      console.log("[dds-runtime]: connect(" + this.server + ")");
      if (!this.connected) {
        cmd = drt.Connect(this.server, authToken);
        return this.ctrlLink.postMessage(cmd);
      } else {
        throw "Runtime already Connected";
      }
    };


    /**
     Disconnects, withouth closing, a `Runtime`. Notice that upon re-connection all existing
     subscriptions and publications will be re-restablished.
     @memberof! dds.runtime.Runtime#
     @function disconnect
     */

    Runtime.prototype.disconnect = function() {
      if (this.connected) {
        console.log("[dds-runtime]: disconnecting...");
        this.connected = false;
        this.ctrlLink.postMessage(drt.Disconnect);
        this.sendWorker.postMessage(drt.Disconnect);
        this.rcvWorker.postMessage(drt.Disconnect);
      }
      return this.ondisconnect(this.server);
    };

    Runtime.prototype.createDataWriter = function(dw) {
      var cdw;
      console.log("[dds-runtime]: Setup DataWriter: " + dw.eid);
      this.dwmap[dw.eid] = dw;
      cdw = drt.CreateDataWriter(dw.topic.tinfo, dw.qos, dw.eid);
      return this.ctrlLink.postMessage(cdw);
    };

    Runtime.prototype.createDataReader = function(dr) {
      var cdr;
      console.log("[dds-runtime]: Setting up DR with eid = " + dr.eid);
      this.drmap[dr.eid] = dr;
      cdr = drt.CreateDataReader(dr.topic.tinfo, dr.qos, dr.eid);
      return this.ctrlLink.postMessage(cdr);
    };


    /**
     Registers the provided Topic.
     @memberof! dds.runtime.Runtime#
     @function registerTopic
     @param {Topic} t - Topic to be registered
     */

    Runtime.prototype.registerTopic = function(t) {
      var ct, eid;
      console.log("[dds-runtime]: Defining topic " + t.tinfo.tname);
      eid = this.generateEntityId();
      t.eid = eid;
      this.tmap[eid] = t;
      ct = drt.CreateTopic(t.tinfo, t.qos, t.eid);
      return this.ctrlLink.postMessage(ct);
    };

    Runtime.prototype.unregisterTopic = function(t) {};

    Runtime.prototype.closeDataReader = function(dr) {
      console.log("[dds-runtime]: Cleaning up DR with eid = " + dr.eid);
      return delete this.drmap[dr.eid];
    };

    Runtime.prototype.closeDataWriter = function(dw) {
      console.log("[dds-runtime]: Cleaning up DW with eid = " + dw.eid);
      return delete this.dwmap[dw.eid];
    };

    Runtime.prototype.writeData = function(dw, s) {
      var cmd, data, sdata;
      data = Array.isArray(s) ? s : [s];
      sdata = JSON.stringify(data, function(key, value) {
        if (value !== value) {
          return 'NaN';
        }
        return value;
      });
      cmd = drt.WriteData(sdata, dw.eid);
      return this.sendWorker.postMessage(cmd);
    };

    Runtime.prototype.disposeData = function(dw, s) {
      var cmd, data, sdata;
      data = Array.isArray(s) ? s : [s];
      sdata = JSON.stringify(data, function(key, value) {
        if (value !== value) {
          return 'NaN';
        }
        return value;
      });
      cmd = drt.DisposeData(sdata, dw.eid);
      return this.sendWorker.postMessage(cmd);
    };

    Runtime.prototype.onCtrlWorkerMessage = function(evt) {
      var cmd, dr, dw, e, eid, ref, ref1;
      e = evt;
      switch (false) {
        case !z_.match(e.h, drt.ConnectedRuntimeEvt):
          this.connected = true;
          console.log("[dds-runtime]: Runtime Connected.");
          if (this.needToReEstablishConnections) {
            console.log("[dds-runtime]: Re-establishing DataReaders and DataWriters connections");
            ref = this.dwmap;
            for (eid in ref) {
              dw = ref[eid];
              this.createDataWriter(dw);
            }
            ref1 = this.drmap;
            for (eid in ref1) {
              dr = ref1[eid];
              this.createDataReader(dr);
            }
          } else {
            this.needToReEstablishConnections = true;
          }
          return this.onconnect(e);
        case !z_.match(e.h, drt.DisconnectedRuntimeEvt):
          console.log("[dds-runtime]: Runtime Disconnected.");
          return this.disconnect();
        case !z_.match(e.h, drt.CreatedTopicEvt):
          console.log("[dds-runtime]: Topic created with eid = " + e.eid);
          return this.tmap[e.eid].onregistered(e);
        case !z_.match(e.h, drt.CreatedDataReaderEvt):
          console.log("[dds-runtime]: DataReader created with eid = " + e.eid);
          cmd = drt.ConnectDataReader(e.url, e.eid);
          return this.rcvWorker.postMessage(cmd);
        case !z_.match(e.h, drt.CreatedDataWriterEvt):
          console.log("[dds-runtime]: DataWriter created with eid = " + e.eid);
          cmd = drt.ConnectDataWriter(e.url, e.eid);
          return this.sendWorker.postMessage(cmd);
        case !z_.match(e.h, drt.WriteLogCmd):
          return console.log("[dds-runtime]: " + e.kind + "]: " + e.msg);
        case !z_.match(e.h.eid, drt.EventId.Error):
          return console.log("[dds-runtime]: " + e.h.kind + "]: " + e.msg);
        default:
          return console.log("[dds-runtime]: Driver received invalid command from CtrlWorker");
      }
    };

    Runtime.prototype.onSendWorkerMessage = function(evt) {
      var e;
      e = evt;
      switch (false) {
        case !z_.match(e.h, drt.ConnectedDataWriterEvt):
          return this.dwmap[e.eid].onconnect(e);
        case !z_.match(e.h, drt.DisconnectedDataWriterEvt):
          if (this.dwmap[e.eid]) {
            return this.dwmap[e.eid].ondisconnect(e);
          }
          break;
        case !z_.match(e.h, drt.WriteLogCmd):
          return console.log("[dds-runtime]: [Log: " + e.kind + "]: " + e.msg);
        default:
          return console.log("[dds-runtime]: Driver received invalid command from SendWorker");
      }
    };

    Runtime.prototype.onRcvWorkerMessage = function(evt) {
      var e;
      e = evt;
      switch (false) {
        case !z_.match(e.h, drt.ConnectedDataReaderEvt):
          return this.drmap[e.eid].onconnect(e);
        case !z_.match(e.h, drt.DisconnectedDataReaderEvt):
          if (this.drmap[e.eid]) {
            return this.drmap[e.eid].ondisconnect(e);
          }
          break;
        case !z_.match(e.h, drt.DataAvailableEvt):
          if (this.drmap[e.eid]) {
            return this.drmap[e.eid].onDataAvailable(e.data);
          }
          break;
        case !z_.match(e.h, drt.WriteLogCmd):
          return console.log("[dds-runtime]: [Log: " + e.kind + "]: " + e.msg);
        default:
          return console.log("[dds-runtime]: Driver Received Invalid Command from ReceiveWorker");
      }
    };


    /**
     Closes the DDS runtime and as a consequence all the `DataReaders` and `DataWriters` that belong to this runtime.
     @memberof! dds.runtime.Runtime#
     @function close
     */

    Runtime.prototype.close = function() {
      console.log("[dds-runtime]: Closing runtime. Notice that this shuts down all web workers.");
      if (!this.closed) {
        this.closed = true;
        this.connected = false;
        this.ctrlLink.postMessage(drt.Disconnect);
        this.sendWorker.postMessage(drt.Disconnect);
        this.rcvWorker.postMessage(drt.Disconnect);
        this.drmap = {};
        this.dwmap = {};
        console.log("[dds-runtime]: calling close...");
        return this.onclose();
      }
    };


    /**
     Checks whether the Runtime is connected.
     @memberof! dds.runtime.Runtime#
     @function isConnected
     @return {boolean} - `true` if connected, `false` if not
     */

    Runtime.prototype.isConnected = function() {
      return this.connected;
    };


    /**
     Checks whether the Runtime is closed.
     @memberof! dds.runtime.Runtime#
     @function isClosed
     @return {boolean} - `true` if closed, `false` if not
     */

    Runtime.prototype.isClosed = function() {
      return this.closed;
    };

    return Runtime;

  })();

  dds.runtime.Runtime = Runtime;

  module.exports = dds;

}).call(this);
