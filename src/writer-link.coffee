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
Config = require('./config.js')

connected = false

socketMap = {}
urlMap = {}

setupWriterSocket = (worker, url, eid) ->
  socket = new WebSocket(url)

  console.log("Created Websocket for DW at #{url}")
  socketMap[eid] = socket
  urlMap[eid] = url

  socket.onopen = (evt) =>
    console.log("DW Writer Websocket is open")
    worker.emit('postMessage', drt.OnConnectedDataWriter(url, eid))

  socket.onclose = (evt) =>
    console.log("DW Websocket is closed")
    delete socketMap[eid]
    worker.emit('postMessage', drt.OnDisconnectedDataWriter(url, eid))

disconnect = () ->
  if (connected)
    connected = false
    for eid,s of socketMap
      s.close()
      rworker.emit('postMessage', drt.OnDisconnectedDataWriter(urlMap[eid], eid))
    socketMap = {}
    urlMap = {}

class WriteLinkWorker

  constructor: () ->
    EventEmitter.call(this)


  util.inherits(WriteLinkWorker, EventEmitter)

  postMessage: (cmd) ->

    switch
      when z_.match(cmd.h, drt.ConnectDataWriterCmd)
        console.log("Setting-up Socket for DW : " + cmd.eid + ", at " + cmd.url)
        setupWriterSocket(this, cmd.url, cmd.eid)

      when z_.match(cmd.h, drt.WriteDataCmd)
        socket = socketMap[cmd.eid]
        s = cmd.data
        try
          socket.send(s)
        catch e
          console.log("Exception while sending data")
          console.log(JSON.stringify(e))

      when z_.match(cmd.h, drt.Disconnect)
        disconnect()

      else
        console.log("Reader Worker Received Unknown Command!")

module.exports = WriteLinkWorker
