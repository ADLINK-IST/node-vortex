###

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

###

EventEmitter = require('events')
util = require('util')
WebSocket = require('ws')
z_ = require('./coffez.js')
drt = require('./control-commands.js')
dds = require('./dds.js')
Config = require('./config.js')

###
  Wire  Protocol Messages
###

root = {}


#connected = true

Header = (c, k, s) -> {cid: c, ek: k, sn: s}


TopicInfo = (topic) ->
  did: topic.did,
  tn: topic.tname,
  tt: topic.ttype,
  trt: topic.tregtype
  qos: topic.qos.policies

DataReaderInfo = (topic, qos) ->
  did: topic.did
  tn: topic.tname
  qos: qos.policies

DataWriterInfo = DataReaderInfo

CreateTopicMsg= (seqn, topic) ->
  h: Header(drt.CommandId.Create, drt.EntityKind.Topic, seqn),
  b: TopicInfo(topic)

CreateDataReaderMsg = (seqn, topic, qos) ->
  h: Header(drt.CommandId.Create, drt.EntityKind.DataReader, seqn)
  b: DataReaderInfo(topic, qos)

CreateDataWriterMsg = (seqn, topic, qos) ->
  h: Header(drt.CommandId.Create, drt.EntityKind.DataWriter, seqn)
  b: DataWriterInfo(topic, qos)


class ControlLink

  constructor: () ->
    EventEmitter.call(this)
    @connected = false
    @closed = false
    @socket = z_.None
    @ctrlSock = z_.None
    @server = ""
    @authToken = ""
    @sn = 0
    @drmap = {}
    @dwmap = {}
    @tmap = {}

  util.inherits(ControlLink, EventEmitter)

  connect: (url, atoken) ->
    if @connected is false
      @server = url
      @authToken = atoken

      endpoint = Config.runtime.controllerURL(@server) + '/' + @authToken
      console.log("[control-link] Connecting to: #{endpoint}")
      @ctrlSock = z_.None
      webSocket = new WebSocket(endpoint)
      pendingCtrlSock = z_.Some(webSocket)

      pendingCtrlSock.map (
        (s) =>
          s.on('open', () =>
            console.log('[control-link] Connected to: ' + @server)
            @ctrlSock = pendingCtrlSock
            @connected = true
            # We may need to re-establish dropped data connection, if this connection is following
            # a disconnection.
            #            console.log("Re-establishing dropped connection -- if needed")
            #            @establishDroppedDataConnections()
            #            @onconnect()
            evt = drt.OnConnectedRuntime(@server)
            this.emit('postMessage',evt)
          )
      )

      pendingCtrlSock.map (
        (s) => s.on('close',
          (evt) =>
            console.log("[control-link] The  #{@server} seems to have dropped the connection.")
            @connected = false
            @closed = true
            @ctrlSock = z_.None
            this.emit('postMessage', drt.OnDisconnectedRuntime(@server))
        )
      )


      pendingCtrlSock.map (
        (s) =>
          s.on('message', (msg) =>
            this.handleMessage(msg)
          )
      )
    else
      console.log("[control-link] Warning: Trying to connect an already connected Runtime")

  close: () ->
    if (not @closed)
      @closed = true
      @disconnect()

  disconnect: () ->
    if (@connected)
      @connected = false
      @ctrlSock.map((s) ->
        console.log("[control-link] closing socket")
        s.close()
      )
      @crtSock = z_._None

# Creates a remote topic
  createTopic: (topic, qos, eid) ->
    console.log("[control-link] Creating Topic for eid = " + eid)
    cmd = CreateTopicMsg(@sn, topic)
    @tmap[@sn] = eid
    @sn = @sn + 1
    scmd = JSON.stringify(cmd)
    @ctrlSock.map((s) -> s.send(scmd))


# Creates a remote reader
  createDataReader: (topic, qos, eid) ->
    cmd = CreateDataReaderMsg(@sn, topic, qos)
    @drmap[@sn] = eid
    @sn = @sn + 1
    scmd = JSON.stringify(cmd)
    @ctrlSock.map((s) -> s.send(scmd))

# Creates a remote writer
  createDataWriter: (topic, qos, eid) ->
    cmd = CreateDataWriterMsg(@sn, topic, qos)
    @dwmap[@sn] = eid
    @sn = @sn + 1
    scmd = JSON.stringify(cmd)
    @ctrlSock.map((s) -> s.send(scmd))



# handles incoming data
  handleMessage: (s) ->
    console.log("[control-link] CtrlWorker Received message from server:" + s)
    msg = JSON.parse(s)
    switch
      when z_.match(msg.h, {cid: drt.CommandId.OK, ek: drt.EntityKind.DataReader})
        guid = msg.b.eid
        url = Config.runtime.readerPrefixURL(@server) + '/' + guid
        console.log("[control-link] sn = " + msg.h.sn + ", eid = " + @drmap[msg.h.sn])
        evt = drt.OnCreatedDataReader(url, @drmap[msg.h.sn])
        delete @drmap[msg.h.sn]
        this.emit('postMessage', evt)

      when z_.match(msg.h, {cid: drt.CommandId.OK, ek: drt.EntityKind.DataWriter})
        guid = msg.b.eid
        url = Config.runtime.writerPrefixURL(@server) + '/' + guid
        console.log("[control-link] sn = " + msg.h.sn + ", eid = " + @dwmap[msg.h.sn])
        evt = drt.OnCreatedDataWriter(url, @dwmap[msg.h.sn])
        delete @dwmap[msg.h.sn]
        this.emit('postMessage', evt)

      when z_.match(msg.h, {cid: drt.CommandId.OK, ek: drt.EntityKind.Topic})
        console.log("[control-link] Topic sn = " + msg.h.sn + "  eid = " + @tmap[msg.h.sn])
        evt = drt.OnCreatedTopic(@tmap[msg.h.sn])
        delete @tmap[msg.h.sn]
        this.emit('postMessage', evt)

      when z_.match(msg.h, {cid: drt.CommandId.Error, ek: undefined})
        evt = drt.OnError(msg.h.ek, msg.b.msg)
        this.emit('postMessage', evt)

      else
        console.log("[control-link] ControlLink received invalid message from server")

class ControlLinkWorker

  constructor: () ->
    EventEmitter.call(this)
    worker = this
    @ctrlLink = new ControlLink()
    @ctrlLink.on('postMessage', (evt) ->
      worker.emit('postMessage', evt)
    )

  util.inherits(ControlLinkWorker, EventEmitter)

  postMessage: (cmd) ->

    console.log("[control-link] CtrlWorker received cmd: " + JSON.stringify(cmd))
    switch
      when z_.match(cmd.h, drt.ConnectCmd)
        console.log("[control-link]: cmd = Connect (" + cmd.url + ")")
        @ctrlLink.connect(cmd.url, cmd.authToken)

      when z_.match(cmd.h, drt.CreateTopicCmd)
        @ctrlLink.createTopic(cmd.topic, cmd.qos, cmd.eid)

      when z_.match(cmd.h, drt.CreateDataReaderCmd)
        console.log("[control-link] CreateDataReader: " + cmd.eid)
        @ctrlLink.createDataReader(cmd.topic, cmd.qos, cmd.eid)

      when z_.match(cmd.h, drt.CreateDataWriterCmd)
        console.log("[control-link] CreateDataWriter: " + cmd.eid)
        @ctrlLink.createDataWriter(cmd.topic, cmd.qos, cmd.eid)

      when z_.match(cmd.h, drt.Disconnect)
        @ctrlLink.disconnect()

      else
        console.log("[control-link] Worker Received Unknown Command!")

module.exports = ControlLinkWorker

