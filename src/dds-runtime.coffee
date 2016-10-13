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

DDS = require('./dds.js')
Commands = require('./control-commands.js')
ControlLink = require('./control-link.js')
ReadWorker = require('./reader-link.js')
WriteWorker = require('./writer-link.js')
Coffez = require('./coffez.js')

#root = {}
dds = DDS
dds.runtime = {}

z_ = Coffez

###*
Define the dds.runtime namespace.
@namespace dds.runtime
###

drt = require('./control-commands.js')


getCurrentPath = () ->
  scriptTag = document.getElementsByTagName('script')
  scriptTag = scriptTag[scriptTag.length - 1]
  scriptPath = scriptTag.src
  scriptFolder = scriptPath.substr(0, scriptPath.lastIndexOf( '/' ))
  scriptFolder

currentScriptPath = ''
if (typeof document isnt 'undefined')
  currentScriptPath = getCurrentPath()

###*
Constructs a DDS Runtime object
@constructor
@classdesc maintains the connection with the server, re-establish the connection
if dropped and mediates the `DataReader` and `DataWriter` communication.
 @memberof dds.runtime
###
class Runtime
  constructor: () ->
    @sn = 0
    @eidCount = 0
    @drmap = {}
    @dwmap = {}
    @tmap = {}
    @onconnect = (evt) ->
      console.log("[dds-runtime]: onconnect")
      @connected = true

    @onclose = (evt) ->
      console.log("[dds-runtime]: onclose")
      @connected = false
      @closed = true

    @ondisconnect = (evt) ->
      console.log("[dds-runtime]: ondisconnect")
      @connected = false

    @connected = false
    @closed = false
    @needToReEstablishConnections = false
    @ctrlLink = new ControlLink()
    console.log("[dds-runtime]: ctrlLink (#{@ctrlLink})")
    @ctrlLink.on('postMessage', this.onCtrlWorkerMessage)
    @sendWorker = new WriteWorker()
    @rcvWorker = new ReadWorker()
    @sendWorker.on('postMessage', this.onSendWorkerMessage)
    @rcvWorker.on('postMessage', this.onRcvWorkerMessage)
    @server = "disconnected"

  generateEntityId: () ->
    id = @eidCount
    @eidCount += 1
    id

  ###*
  Connect the runtime to the server. If the runtime is already connected an exception is thrown
      @param {string} srv - Vortex Web server WebSocket URL
      @param {string} authToken - Authorization token
  @memberof! dds.runtime.Runtime#
  @function connect
  ###
  connect: (srv, authToken) ->
    @server = srv
    console.log("[dds-runtime]: connect(#{@server})")
    if (not @connected )
      cmd = drt.Connect(@server, authToken)
      @ctrlLink.postMessage(cmd)
    else
      throw "Runtime already Connected"


  ###*
   Disconnects, withouth closing, a `Runtime`. Notice that upon re-connection all existing
   subscriptions and publications will be re-restablished.
   @memberof! dds.runtime.Runtime#
   @function disconnect
  ###
  disconnect: () ->
    if (@connected)
      console.log("[dds-runtime]: disconnecting...")
      @connected = false
      @ctrlLink.postMessage(drt.Disconnect)
      @sendWorker.postMessage(drt.Disconnect)
      @rcvWorker.postMessage(drt.Disconnect)
    @ondisconnect(@server)


  createDataWriter: (dw) ->
# we need to keep a map of all the active DW
    console.log("[dds-runtime]: Setup DataWriter: #{dw.eid}")
    @dwmap[dw.eid] = dw
    cdw = drt.CreateDataWriter(dw.topic.tinfo, dw.qos, dw.eid)
    @ctrlLink.postMessage(cdw)


  createDataReader: (dr) ->
# we need to keep a map of all the active DR
    console.log("[dds-runtime]: Setting up DR with eid = #{dr.eid}")
    @drmap[dr.eid] = dr
    cdr = drt.CreateDataReader(dr.topic.tinfo, dr.qos, dr.eid)
    @ctrlLink.postMessage(cdr)

  ###*
   Registers the provided Topic.
   @memberof! dds.runtime.Runtime#
   @function registerTopic
   @param {Topic} t - Topic to be registered
  ###
  registerTopic: (t) ->
    console.log("[dds-runtime]: Defining topic #{t.tinfo.tname}")
    eid = @generateEntityId()
    t.eid = eid
    @tmap[eid] = t
    ct = drt.CreateTopic(t.tinfo, t.qos, t.eid)
    @ctrlLink.postMessage(ct)


## -- TODO: ---------------------------------------------------------------------------------
  unregisterTopic: (t) ->
## -------------------------------------------------------------------------------------------
  closeDataReader: (dr) ->
    console.log("[dds-runtime]: Cleaning up DR with eid = #{dr.eid}")
    delete @drmap[dr.eid]

  closeDataWriter: (dw) ->
    console.log("[dds-runtime]: Cleaning up DW with eid = #{dw.eid}")
    delete @dwmap[dw.eid]

## -------------------------------------------------------------------------------------------
  writeData: (dw, s) =>
    data = if (Array.isArray(s)) then s else [s]
    sdata = JSON.stringify(data, (key, value) ->
      if (value != value)
        return 'NaN';
      value;
    )
    cmd = drt.WriteData(sdata, dw.eid)
    @sendWorker.postMessage(cmd)

  disposeData: (dw, s) =>
    data = if (Array.isArray(s)) then s else [s]
    sdata = JSON.stringify(data, (key, value) ->
      if (value != value)
        return 'NaN'
      value
    )
    cmd = drt.DisposeData(sdata, dw.eid);
    @sendWorker.postMessage(cmd)


  onCtrlWorkerMessage: (evt) =>
    e = evt
    switch
      when z_.match(e.h, drt.ConnectedRuntimeEvt)
        @connected = true;
        console.log("[dds-runtime]: Runtime Connected.")
        if (@needToReEstablishConnections)
          console.log("[dds-runtime]: Re-establishing DataReaders and DataWriters connections")
          for eid,dw of @dwmap
            @createDataWriter(dw)
          for eid,dr of @drmap
            @createDataReader(dr)
        else
          @needToReEstablishConnections= true
        this.onconnect(e)

      when z_.match(e.h, drt.DisconnectedRuntimeEvt)
        console.log("[dds-runtime]: Runtime Disconnected.")
        @disconnect()

      when z_.match(e.h, drt.CreatedTopicEvt)
        console.log("[dds-runtime]: Topic created with eid = #{e.eid}")
        @tmap[e.eid].onregistered(e)

      when z_.match(e.h, drt.CreatedDataReaderEvt)
        console.log("[dds-runtime]: DataReader created with eid = #{e.eid}")
        cmd = drt.ConnectDataReader(e.url, e.eid)
        @rcvWorker.postMessage(cmd)

      when z_.match(e.h, drt.CreatedDataWriterEvt)
        console.log("[dds-runtime]: DataWriter created with eid = #{e.eid}")
        cmd = drt.ConnectDataWriter(e.url, e.eid)
        @sendWorker.postMessage(cmd)

      when z_.match(e.h, drt.WriteLogCmd)
        console.log("[dds-runtime]: #{e.kind }]: #{e.msg}")

      when z_.match(e.h.eid, drt.EventId.Error)
        console.log("[dds-runtime]: #{e.h.kind }]: #{e.msg}")

      else
        console.log("[dds-runtime]: Driver received invalid command from CtrlWorker")



  onSendWorkerMessage: (evt) =>
    e = evt

    switch
      when z_.match(e.h, drt.ConnectedDataWriterEvt)
        @dwmap[e.eid].onconnect(e)

      when z_.match(e.h, drt.DisconnectedDataWriterEvt)
        if (@dwmap[e.eid])
          return @dwmap[e.eid].ondisconnect(e)
        break;

      when z_.match(e.h, drt.WriteLogCmd)
        console.log("[dds-runtime]: [Log: #{e.kind }]: #{e.msg}")

      else
        console.log("[dds-runtime]: Driver received invalid command from SendWorker")


  onRcvWorkerMessage: (evt) =>
    e = evt
    switch
      when z_.match(e.h, drt.ConnectedDataReaderEvt)
        @drmap[e.eid].onconnect(e)

      when z_.match(e.h, drt.DisconnectedDataReaderEvt)
        if (@drmap[e.eid])
          return @drmap[e.eid].ondisconnect(e)
        break

      when z_.match(e.h, drt.DataAvailableEvt)
        if (@drmap[e.eid])
          return @drmap[e.eid].onDataAvailable(e.data)
        break

      when z_.match(e.h, drt.WriteLogCmd)
        console.log("[dds-runtime]: [Log: #{e.kind }]: #{e.msg}")

      else
        console.log("[dds-runtime]: Driver Received Invalid Command from ReceiveWorker")


  ###*
   Closes the DDS runtime and as a consequence all the `DataReaders` and `DataWriters` that belong to this runtime.
   @memberof! dds.runtime.Runtime#
   @function close
  ###
  close: () =>
    console.log("[dds-runtime]: Closing runtime. Notice that this shuts down all web workers.")
    if (not @closed)
      @closed = true
      @connected = false
      @ctrlLink.postMessage(drt.Disconnect)
      @sendWorker.postMessage(drt.Disconnect)
      @rcvWorker.postMessage(drt.Disconnect)
      @drmap = {}
      @dwmap = {}
      console.log("[dds-runtime]: calling close...")
      @onclose()


  ###*
   Checks whether the Runtime is connected.
   @memberof! dds.runtime.Runtime#
   @function isConnected
   @return {boolean} - `true` if connected, `false` if not
  ###
  isConnected: () => @connected

  ###*
   Checks whether the Runtime is closed.
   @memberof! dds.runtime.Runtime#
   @function isClosed
   @return {boolean} - `true` if closed, `false` if not
  ###
  isClosed: () => @closed

dds.runtime.Runtime = Runtime
module.exports = dds
