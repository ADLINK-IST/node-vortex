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

setupReaderSocket = (worker, url, eid) ->
  socket = new WebSocket(url)

  console.log("Created Websocket for DR at #{url}")
  socketMap[eid] = socket
  urlMap[eid] = url

  socket.onopen = (evt) =>
    console.log("DR Websocket is open")
    worker.emit('postMessage', drt.OnConnectedDataReader(url, eid))

  socket.onclose = (evt) =>
    console.log("DR Websocket is closed")
    delete socketMap[eid]
    delete urlMap[eid]
    worker.emit('postMessage', drt.OnDisconnectedDataReader(url, eid))

  socket.onmessage = (evt) =>
    evt = drt.OnDataAvailable(evt.data, eid)
    worker.emit('postMessage', drt.OnDataAvailable(evt.data, eid))


disconnect = (worker) ->
  if (connected)
    connected = false
    for eid,s of socketMap
      s.close()
      worker.emit('postMessage', OnDisconnectedDataReader(urlMap[eid], eid))
    socketMap = {}
    urlMap = {}


class ReadLinkWorker

  constructor: () ->
    EventEmitter.call(this)

  util.inherits(ReadLinkWorker, EventEmitter)

  postMessage: (cmd) ->
    switch
      when z_.match(cmd.h, drt.ConnectDataReaderCmd)
        console.log("Setting-up Socket for : " + cmd.eid + ", at " + cmd.url)
        setupReaderSocket(this, cmd.url, cmd.eid)

      #when z_.match(cmd.h, drt.Connect)
      #  connect(this)

      when z_.match(cmd.h, drt.Disconnect)
        disconnect(this)

      else
        console.log("Reader Worker Received Unknown Command!")

module.exports = ReadLinkWorker