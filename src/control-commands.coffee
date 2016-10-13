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

dds = {}


# This file defines the control commands exchanged by the web-client and the server
# in order to create remote DDS entities

CommandId =
  OK:           0
  Error:        1
  Create:       2
  Connect:      3
  Disconnect:   4
  Close:        5
  Write:        6
  Log:          7
  Dispose:      8

EventId =
  Error:         0
  Connected:     1
  Disconnected:  2
  DataAvailable: 3
  Create:        4

EntityKind =
  Topic:      0
  DataReader: 1
  DataWriter: 2
  Runtime:    3
  Worker:     4

dds.EntityKind = EntityKind
dds.CommandId = CommandId
dds.EventId = EventId

########################################################################################################################
##   Control Worker Commands
########################################################################################################################

Header = (cmd, ek) -> {cid: cmd, kind: ek}

ConnectCmd = Header(CommandId.Connect, EntityKind.Runtime)
Connect = (serverURL, at) -> { h: ConnectCmd, url: serverURL, authToken: at }

DisconnectCmd = Header(CommandId.Disconnect, EntityKind.Runtime)
Disconnect = { h: DisconnectCmd }

CloseCmd = Header(CommandId.Close, EntityKind.Runtime)
Close = { h: CloseCmd }


CreateEntity = (header) -> (t, q, id) -> { h: header,  topic: t, qos: q, eid: id}

CreateTopicCmd = Header(CommandId.Create, EntityKind.Topic)
CreateTopic = CreateEntity(CreateTopicCmd)

CreateDataReaderCmd = Header(CommandId.Create, EntityKind.DataReader)
CreateDataReader = CreateEntity(CreateDataReaderCmd)
CloseDataReaderCmd = Header(CommandId.Close, EntityKind.DataReader)
CloseDataReader = CreateEntity(CloseDataReaderCmd)

CreateDataWriterCmd = Header(CommandId.Create, EntityKind.DataWriter)
CreateDataWriter = CreateEntity(CreateDataWriterCmd)
CloseDataWriterCmd = Header(CommandId.Close, EntityKind.DataWriter)
CloseDataWriter = CreateEntity(CloseDataWriterCmd)
DisposeDataWriterCmd = Header(CommandId.Dispose, EntityKind.DataWriter);
DisposeDataWriter = CreateEntity(DisposeDataWriterCmd);

dds.ConnectCmd = ConnectCmd
dds.Connect = Connect
dds.DisconnectCmd = DisconnectCmd
dds.Disconnect = Disconnect
dds.CloseCmd = CloseCmd
dds.Close = Close
dds.CreateTopicCmd = CreateTopicCmd
dds.CreateTopic = CreateTopic
dds.CreateDataReaderCmd= CreateDataReaderCmd
dds.CreateDataReader = CreateDataReader
dds.CreateDataWriterCmd = CreateDataWriterCmd
dds.CreateDataWriter = CreateDataWriter
dds.CloseDataReaderCmd = CloseDataReaderCmd
dds.CloseDataReader = CloseDataReader
dds.CloseDataWriterCmd = CloseDataWriterCmd
dds.CloseDataWriter = CloseDataWriter

########################################################################################################################
##   Sender Worker Commands
########################################################################################################################
ConnectDataWriterCmd = Header(CommandId.Connect, EntityKind.DataWriter)
ConnectDataWriter = (addr, id) -> h:ConnectDataWriterCmd, url: addr, eid: id

WriteDataCmd = Header(CommandId.Write, EntityKind.DataWriter)
WriteData = (s, id) -> h: WriteDataCmd, data: s, eid: id

DisposeDataCmd = Header(CommandId.Dispose, EntityKind.DataWriter);
DisposeData = (s, id) -> h: DisposeDataCmd, data: s, eid: id

dds.ConnectDataWriterCmd = ConnectDataWriterCmd
dds.ConnectDataWriter = ConnectDataWriter
dds.WriteDataCmd = WriteDataCmd
dds.WriteData = WriteData
dds.DisposeDataCmd = DisposeDataCmd;
dds.DisposeData = DisposeData
########################################################################################################################
##   Receiver Worker Commands
########################################################################################################################
ConnectDataReaderCmd = Header(CommandId.Connect, EntityKind.DataWriter)
ConnectDataReader = (addr, id) -> h: ConnectDataReaderCmd, url: addr, eid: id


dds.ConnectDataReaderCmd = ConnectDataReaderCmd
dds.ConnectDataReader = ConnectDataReader
########################################################################################################################
##   Runtime Events
########################################################################################################################

EventHeader = (id, ek) -> eid: id, kind: ek

## Event Raised to the runtime when the service is connected
ConnectedRuntimeEvt = EventHeader(EventId.Connected, EntityKind.Runtime)
OnConnectedRuntime = (endpoint) -> h: ConnectedRuntimeEvt, url: endpoint

DisconnectedRuntimeEvt = EventHeader(EventId.Disconnected, EntityKind.Runtime)
OnDisconnectedRuntime = (endpoint) -> h: DisconnectedRuntimeEvt , url: endpoint

CreatedDataReaderEvt = EventHeader(EventId.Create, EntityKind.DataReader)
OnCreatedDataReader = (addr, id) -> h: CreatedDataReaderEvt, url: addr, eid: id

ConnectedDataReaderEvt = EventHeader(EventId.Connected, EntityKind.DataReader)
OnConnectedDataReader = (addr, id) -> h: ConnectedDataReaderEvt, url: addr, eid: id

DisconnectedDataReaderEvt = EventHeader(EventId.Disconnected, EntityKind.DataReader)
OnDisconnectedDataReader = (addr, id) -> h: DisconnectedDataReaderEvt, url: addr, eid: id


CreatedDataWriterEvt = EventHeader(EventId.Create, EntityKind.DataWriter)

OnCreatedDataWriter = (addr, id) -> h: CreatedDataWriterEvt, url: addr, eid: id

ConnectedDataWriterEvt = EventHeader(EventId.Connected, EntityKind.DataWriter)
OnConnectedDataWriter = (addr, id) -> h: ConnectedDataWriterEvt, url: addr, eid: id

DisconnectedDataWriterEvt = EventHeader(EventId.Disconnected, EntityKind.DataWriter)
OnDisconnectedDataWriter = (addr, id) -> h: DisconnectedDataWriterEvt, url: addr, eid: id


CreatedTopicEvt = EventHeader(EventId.Create, EntityKind.Topic)
OnCreatedTopic = (id) -> h: CreatedTopicEvt, eid: id

ErrorEvt  = (ek) -> EventHeader(EventId.Error, ek)
OnError = (ek, what) -> h: ErrorEvt(ek), msg: what

DataAvailableEvt = EventHeader(EventId.DataAvailable, EntityKind.DataReader)
OnDataAvailable = (d, id) -> h: DataAvailableEvt, data: d, eid: id


dds.ConnectedRuntimeEvt = ConnectedRuntimeEvt
dds.OnConnectedRuntime = OnConnectedRuntime

dds.DisconnectedRuntimeEvt = DisconnectedRuntimeEvt
dds.OnDisconnectedRuntime = OnDisconnectedRuntime

dds.CreatedTopicEvt = CreatedTopicEvt
dds.OnCreatedTopic = OnCreatedTopic

dds.CreatedDataReaderEvt = CreatedDataReaderEvt
dds.OnCreatedDataReader = OnCreatedDataReader
dds.ConnectedDataReaderEvt = ConnectedDataReaderEvt
dds.OnConnectedDataReader = OnConnectedDataReader
dds.DisconnectedDataReaderEvt = DisconnectedDataReaderEvt
dds.OnDisconnectedDataReader = OnDisconnectedDataReader

dds.CreatedDataWriterEvt = CreatedDataWriterEvt
dds.OnCreatedDataWriter = OnCreatedDataWriter
dds.ConnectedDataWriterEvt = ConnectedDataWriterEvt
dds.OnConnectedDataWriter = OnConnectedDataWriter
dds.DisconnectedDataWriterEvt = DisconnectedDataWriterEvt
dds.OnDisconnectedDataWriter = OnDisconnectedDataWriter

dds.DataAvailableEvt = DataAvailableEvt
dds.OnDataAvailable = OnDataAvailable
dds.ErrorEvt = ErrorEvt
dds.OnError = OnError

########################################################################################################################
##   Logger Commands
########################################################################################################################
WriteLogCmd = Header(CommandId.Log, EntityKind.Worker)
WriteLog = (ek, str) -> h: WriteLogCmd, kind: ek, msg: str

dds.WriteLogCmd = WriteLogCmd
dds.WriteLog = WriteLog

module.exports = dds