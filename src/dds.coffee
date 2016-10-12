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

# Vortex Web is a CoffeeScript API for DDS. This API allows web-app to share data in real-time among themselves
# and with native DDS applications.

# NOTE : JSDoc comments should be surrounded by ###* <comment> ###

# TODO: Add support for default QoS on DW/DR creation
coffez = require("./coffez.js")

dds = {}
z_ = coffez

###*
Defines the core Vortex-Web-Client javascript library. It includes the JavaScript API for DDS. This API allows web
 applications to share data among them as well as with native DDS applications.
@namespace dds
###

#if (typeof exports isnt 'undefined')
#  if (typeof module isnt 'undefined' and module.exports)
#    exports = module.exports = dds
#  exports.dds = dds

dds.VERSION = "1.2.4"

########################################################################################################################
##   QoS Policies and Entities QoS
########################################################################################################################

PolicyId =
  History:            0
  Reliability:        1
  Partition:          2
  ContentFilter:      3
  TimeFilter:         4
  Durability:         5
  DestinationOrder:   6
  TransportPriority:  7
  Ownership:          8
  OwnershipStrength:  9


###
   History Policy
###
HistoryKind =
  KeepAll: 0
  KeepLast: 1

###*
History Policy
@memberof dds#
 @property KeepAll - KEEP_ALL qos policy
 @property KeepLast - KEEP_LAST qos policy
###
History =
  KeepAll:
    id: PolicyId.History
    k: HistoryKind.KeepAll

  KeepLast: (depth) ->
    result =
      id: PolicyId.History
      k: HistoryKind.KeepLast
      v: depth
    result


###
  Reliability Policy
###

ReliabilityKind =
  Reliable: 0
  BestEffort: 1

###*
  Reliability Policy
  @memberof dds#
   @property BestEffort - 'BestEffort' reliability policy
   @property Reliable - 'Reliable' reliability policy
   @example var qos = Reliability.Reliable
###
Reliability =
  BestEffort:
    id: PolicyId.Reliability
    k: ReliabilityKind.BestEffort

  Reliable:
    id: PolicyId.Reliability
    k: ReliabilityKind.Reliable

###*
  Partition Policy.
  @memberof dds#
  @function Partition
  @param {...string} p - partition names
  @returns partition - Partition object
  @example var qos = Partition('p1', 'p2')
###
Partition = (p, plist...) ->
  policy =
    id: PolicyId.Partition
    vs: plist.concat(p)
  policy


###*
 Content Filter Policy.
 @memberof dds#
 @function ContentFilter
 @param {string} expr
 @returns filter - ContentFilter object
 @example var filter = ContentFilter("x>10 AND y<50")
###
ContentFilter = (expr) ->
  contentFilter =
    id: PolicyId.ContentFilter
    v: expr
  contentFilter

###*
 Time_Based_Filter Policy.
 @memberof dds#
 @function TimeFilter
 @param {number} period - time duration (unit ?)
 @return timeFilter - TimeFilter policy object
 @example var filter = TimeFilter(100)
###
TimeFilter = (duration) ->
  timeFilter =
    id: PolicyId.TimeFilter
    v: duration
  timeFilter

###
  Durability Policy
###
DurabilityKind =
  Volatile: 0
  TransientLocal: 1
  Transient: 2
  Persistent: 3

###*
  Durability Qos Policy
  @memberof dds#
   @property Volatile - Volatile durability policy
   @property TransientLocal - TransientLocal durability policy
   @property Transient - Transient durability policy
   @property Persistent - Persistent durability policy
###
Durability =
  Volatile:
    id: PolicyId.Durability
    k: DurabilityKind.Volatile
  TransientLocal:
    id: PolicyId.Durability
    k: DurabilityKind.TransientLocal
  Transient:
    id: PolicyId.Durability
    k: DurabilityKind.Transient
  Persistent:
    id: PolicyId.Durability
    k: DurabilityKind.Persistent

###
  Destination Order Policy
###
DestinationOrderKind =
  ByReceptionTimestamp: 0
  BySourceTimestamp: 1


###*
  DestinationOrder QoS Policy.
  @memberof dds#
    @property ByReceptionTimestamp - data is ordered based on the reception time at each Subscriber
    @property BySourceTimestamp - data is ordered based on a time stamp placed at the source (by the Service or by the application)
    @example var qos = DestinationOrder.ByReceptionTimestamp
###
DestinationOrder =
  ByReceptionTimestamp:
    id: PolicyId.DestinationOrder
    k: DestinationOrderKind.ByReceptionTimestamp
  BySourceTimestamp:
    id: PolicyId.DestinationOrder
    k: DestinationOrderKind.BySourceTimestamp


###*
  Creates any of the DDS entities quality of service, including DataReaderQos and DataWriterQos.
  @constructor
    @param {...policy} p - Qos policies

  @classdesc The Entity QoS is represented as a list of Policies.
  @memberof dds
###
class EntityQos
  constructor: (p, ps...) ->
    @policies =
      if arguments.length == 0
        []
      else if p
        ps.concat(p)
      else
        ps

  add: (p...) -> new EntityQos(@policies.concat(p))



###
  Policy and QoS Exports
###

dds.HistoryKind = HistoryKind
dds.History = History
dds.ReliabilityKind = ReliabilityKind
dds.Reliability = Reliability
dds.Partition = Partition
dds.DurabilityKind = DurabilityKind
dds.Durability = Durability
dds.TimeFilter = TimeFilter
dds.ContentFilter = ContentFilter
dds.DestinationOrderKind = DestinationOrderKind
dds.DestinationOrder = DestinationOrder

###*
  Topic quality of service object
  @memberof dds#
  @name TopicQos
  @type {EntityQos}
  @see dds.EntityQos
###
dds.TopicQos = EntityQos

###*
  DataReader quality of service object
  @memberof dds#
  @name DataReaderQos
  @type {EntityQos}
  @see dds.EntityQos
###
dds.DataReaderQos = EntityQos

###*
  DataWriter quality of service object
  @memberof dds#
  @name DataWriterQos
  @type {EntityQos}
  @see dds.EntityQos
###
dds.DataWriterQos = EntityQos

########################################################################################################################
##   DDS Entities
########################################################################################################################

###*
  SampleInfo is accessed in data samples via the `$info` property and provides instance lifecycle information
  @memberof dds#
   @property {Enum} SampleState - A value of `1` is Read, a value of `2` is NotRead
   @property {Enum} ViewState - A value of `1` is New, a value of `2` is NotNew
   @property {Enum} InstanceState - A value of `1` is Alive, a value of `2` is NotAliveDisposed, a value of `4`
   is NotAliveNoWriters
###

SampleInfo =
  SampleState:
    Read: 1
    NotRead: 2
  ViewState:
    New: 1
    NotNew: 2
  InstanceState:
    Alive: 1
    NotAliveDisposed: 2
    NotAliveNoWriters: 4

dds.SampleInfo = SampleInfo

JSONTopicTypeName = "org.omg.dds.types.JSONTopicType"

class JSONTopicType
  constructor: (@value) ->

class KeyValueTopicType
  constructor: (@key, @value) ->

KeyValueTopicTypeName = "org.omg.dds.types.KeyValueTopicType"

isJSONTopicType = (t) -> t.tname is JSONTopicType
isKeyValueTopicType = (t) -> t.name is KeyValueTopicType
isBuiltinTopicType = (t) -> isJSONTopicType(t) or isKeyValueTopicType(t)

JSONTopicTypeSupport =
  id: 0
  injectType: (s) ->
    v = new JSONTopicType(JSON.stringify(s, (key, value) ->
      if (value != value)
        return 'NaN'
      value
    ))
    console.log("InjectedType = #{JSON.stringify(v)}")
    v

  extractType: (s) ->
    m = s.value
    try
      v = JSON.parse(m)
    catch error
      m = m(replace(/([:,]|:\[)NaN/g, (matched) ->
       matched.replace('NaN', '"NaN"')
      ))
      v = JSON.parse(m, (key, value) ->
        if (value == 'NaN')
          return NaN
        value
      )
    console.log("Extracted Type = #{v}")
    v


UserDefinedTopicTypeSupport =
  id: 1
  injectType: (s) -> s
  extractType: (s) -> s


typesSupport = [JSONTopicTypeSupport,  UserDefinedTopicTypeSupport]

class TopicInfo
  constructor: (@did, @tname, @qos, @ttype, @tregtype) ->

###*
  Creates a `Topic` in the domain `did`, named `tname`, having `qos` Qos,
  for the type `ttype` whose registered name is `tregtype`
  @constructor
    @param {number} did - DDS domain ID
    @param {string} tname - topic name
    @param {TopicQos} qos - topic Qos
    @param {string} ttype - topic type. If not specified, a generic type is used.
    @param {string} tregtype - topic registered type name. If not specified, 'ttype' is used.

  @classdesc defines a DDS Topic
  @memberof dds
###
class Topic
  constructor: (did, tname, qos, ttype, tregtype) ->
    if (arguments.length < 2)
      throw "IllegalArgumentException - You need to provide at least did and topic name"

    idid = parseInt(did)
    if (idid is NaN)
      throw "IllegalArgumentException - did must be an integer"

    @onregistered = () ->
    @onunregistered = () ->

    switch arguments.length
      when 2, 3
        ttype = JSONTopicTypeName
        # The registered type name has to use "::" as module separators
        ns = ttype.split('.')
        tregtype = ns.reduce (x, y) -> x + "::" + y
        @typeSupportId = JSONTopicTypeSupport.id
        qos = if qos is undefined then new dds.TopicQos(Reliability.BestEffort) else qos
        @tinfo = new TopicInfo(idid, tname, qos, ttype, tregtype)
      when 4
        @typeSupportId = UserDefinedTopicTypeSupport.id
        # The registered type name has to use "::" as module separators
        ns = ttype.split('.')
        tregtype = ns.reduce (x, y) -> x + "::" + y
        @tinfo = new TopicInfo(idid, tname, qos, ttype, tregtype)

      else
        @typeSupportId = UserDefinedTopicTypeSupport.id
        @tinfo = new TopicInfo(idid, tname, qos, ttype, tregtype)




###*
  Creates a `DataReader` for a given topic and a specific in a specific DDS runtime
  @constructor
      @param {Runtime} runtime - DDS Runtime
      @param {Topic} topic - DDS Topic
      @param {DataReaderQos} qos - DataReader quality of service

  @classdesc A `DataReader` allows to read data for a given topic with a specific QoS. A `DataReader`
  goes through different states, it is intially disconnected and changes to the connected state
  when the underlying transport connection is successfully established with the server. At this point
  a `DataReader` can be explicitely closed or disconnected. A disconnection can happen as the result
  of a network failure or server failure. Disconnection and reconnections are managed by the runtime.
  @memberof dds
###
class DataReader
  constructor: (@runtime, @topic, @qos) ->
    @handlers = []
    @onclose = () ->
    @closed = false
    @onconnect = () ->
    @ondisconnect = () ->
    @connected = false
    @eid = @runtime.generateEntityId()
    @runtime.createDataReader(this)
    @receivedSamples = 0
    @typeSupport = typesSupport[@topic.typeSupportId]

  resetStats: () =>
    @receivedSamples = 0



  ###*
    Attaches the  listener `l` to this data reader and returns
    the id associated to the listener.
       @param {function} l - listener code
       @returns {handle} - listener handle
       @memberof! dds.DataReader#
       @function addListener
  ###
  addListener: (l) ->
    idx = @handlers.length
    @handlers = @handlers.concat(l)
    idx

  ###*
    removes a listener from this data reader.
    @param {number} idx - listener id
    @memberof! dds.DataReader#
    @function removeListener
  ###
  removeListener: (idx) =>
    h = @handlers
    @handlers = h.slice(0, idx).concat(h.slice(idx+1, h.length))

  onDataAvailable: (m) =>
    @receivedSamples += 1
    try
      parsedm = JSON.parse(m);
    catch error
      m = m.replace(/([:,]|:\[)NaN/g, (matched) ->
        matched.replace('NaN', '"NaN"')
      )
      parsedm = JSON.parse(m, (key, value) ->
        if (value == 'NaN')
          return NaN
        value
      )
    d = @typeSupport.extractType(parsedm);
    @handlers.forEach((h) -> h(d))

  ###*
    closes the DataReader.
    @memberof! dds.DataReader#
    @function close
  ###
  close: () =>
    console.log("Closing DR #{this}")
    @closed = true
    @runtime.closeDataReader(this)
    @onclose()


###*
  Creates a `DataWriter` for a given topic and a specific in a specific DDS runtime
  @constructor
      @param {Runtime} runtime - DDS Runtime
      @param {Topic} topic - DDS Topic
      @param {DataWriterQos} qos - DataWriter quality of service

   @classdesc defines a DDS data writer. This type
   is used to write data for a specific topic with a given QoS.
   A `DataWriter` goes through different states, it is initially disconnected and changes to the connected
   state when the underlying transport connection is successfully established with the server.
   At this point a `DataWriter` can be explicitly closed or disconnected. A disconnection can happen
   as the result of a network failure or server failure. Disconnections and reconnections are managed by the
   runtime.
   @memberof dds
###
class DataWriter
  constructor: (@runtime, @topic, @qos) ->
    @onclose = () ->
    @closed = false
    @onconnect = () ->
    @ondisconnect = () ->
    @connected = false
    @eid = @runtime.generateEntityId()
    @runtime.createDataWriter(this)
    @typeSupport = typesSupport[@topic.typeSupportId]
    @sentSamples = 0

  ###*
    Writes one or more samples.
    The returned samples contained the SampleInfo
    accessible from the `info` property
    @param {...data-type} ds - data samples
    @memberof! dds.DataWriter#
    @function write
  ###
  write: (ds...) =>
    xs = ds.map((s) => @typeSupport.injectType(s))
    @runtime.writeData(this, xs)
    @sentSamples += xs.length

  ###*
    Dispose one or more instances.
    @param {...data-type} ds - data samples, each containing
    the key of the instance to be disposed
    @memberof! dds.DataWriter#
    @function dispose
  ###
  dispose: (ds...) =>
    xs = ds.map((s) => @typeSupport.injectType(s))
    @runtime.disposeData(this, xs);
    @sentSamples += xs.length

  resetStats: () ->
    @sentSamples = 0

  ###*
    Closes the DataWriter.
    @memberof! dds.DataWriter#
    @function close
  ###
  close: () ->
    @closed = true
    @socket = new z_.Fail("Invalid State Exception: Can't write on a closed DataWriter")
    @runtime.closeDataWriter(this)
    @onclose()

dds.Topic = Topic
dds.DataReader = DataReader
dds.DataWriter = DataWriter


########################################################################################################################
##   Data Cache
########################################################################################################################c

###*
  Constructs a `DataCache` with a given `depth`. If the `cache` parameter
  is present, then the current cache is initialized with this parameter.
  @constructor
      @param {number} depth - cache size
      @param {map} cache - cache data structure

  @classdesc Provides a way of storing and flexibly accessing the
  data received through a `DataReader`. A `DataCache` is organized as
  a map of queues. The depth of the queues is specified at construction
  time.
  @memberof dds
###
class DataCache
  constructor: (@depth, @cache) ->
    if (@cache? == false) then @cache = {}
    @listeners = []

  ###*
    Register a listener to be notified whenever data which matches a predicate is written into the cache.
    If no predicate is provided then the listeners is always notified upon data inserion.
    @memberof! dds.DataCache#
    @function addListener
    @param {function} l - listener function
    @param {function} p - predicate
  ###
  addListener: (l, p) ->
    if (predicate is undefined)
      predicate = (x) -> true
    entry =
      predicate: p
      listener: l
    @listeners = @listeners.concat(entry)

  ###*
    Write the element `data` with key `k` into the cache.
    @memberof! dds.DataCache#
    @param {*} k - data key
    @param {*} data - data value
    @returns {*} - the written data value
    @function  write
  ###
  write: (k, data) ->
    v = @cache[k]
    if (v? == false) then v = [data] else v = if (v.length < @depth) then v.concat(data) else v.slice(1, v.lenght).concat(data)
    @cache[k] = v

    @listeners.forEach((e) -> if (e.predicate(data) is true) then e.listener(data))

  ###*
    Same as forEach but applied, for each key, only to the first `n` samples of the cache
    @memberof! dds.DataCache#
    @function forEachN
    @param {function} f - the function to be applied
    @param {integer} n - samples set size
    @returns {Array} - results of the function execution
    @see dds.DataCache#forEach
  ###
  forEachN: (f, n) ->
    for k, v of @cache
      v[0..n-1].forEach(f)

  ###*
    Execute the function `f` for each element of the cache.
    @memberof! dds.DataCache#
    @param {function} f - the function to be applied
    @returns {Array} - results of the function execution
    @function forEach
  ###
  forEach: (f) ->
    for k, v of @cache
      v.forEach(f)

  ###*
   Returns a cache that is the result of applying `f` to each element of the cache.
   @memberof! dds.DataCache#
   @param {function} f - the function to be applied
   @returns {DataCache} - A cache holding the results of the function execution
   @function map
  ###
  map: (f) ->
    result = {}
    for k, v of @cache
      result[k] = v.map(f)
    new DataCache(@depth, result)

  ###*
   Returns the list of elements in the cache that satisfy the predicate `f`.
   @memberof! dds.DataCache#
   @function filter
   @param {function} f - the predicate to be applied to filter the cache values
   @returns {Array} - An array holding the filtered values
  ###
  filter: (f) ->
    result = {}
    for k, v of @cache
      rv = fv for fv in v when f(v)
      result[k] = rv if rv.length isnt 0
    result

  ###*
    Returns the list of elements in the cache that doesn't satisfy the predicate `f`.
    @memberof! dds.DataCache#
    @function filterNot
    @returns {Array} - An array holding the filtered values
    @see dds.DataCache#filter
  ###
  filterNot: (f) -> filter((s) -> not f(s))

  ###*
   Returns the values included in the cache as an array.
   @memberof! dds.DataCache#
   @function read
   @return {Array} - All the cache values
  ###
  read: () ->
    result = []
    for k, v of @cache
      result = result.concat(v)
    result

  ###*
   Returns the last value of the cache in an array.
   @memberof! dds.DataCache#
   @function readLast
   @return {Array} - the last value of the cache
  ###
  readLast: () ->
    result = []
    for k, v of @cache
      result.add(v[v.length -1])
    result

  ###*
   Returns all the values included in the cache as an array and empties the cache.
   @memberof! dds.DataCache#
   @function takeAll
   @return {Array} - All the cache values
  ###
  takeAll: () ->
    tmpCache = @cache
    @cache = []
    result = []
    for k, v of tmpCache
      result = result.concat(v)
    result

  ###*
   Returns the `K`ith value of the cache as Monad, ie: `coffez.Some` if it exists, `coffez.None` if not.
   @memberof! dds.DataCache#
   @function take
   @see coffez.Some
   @see coffez.None
  ###
  take: (k) ->
    v = @cache[k]
    @cache[k] = []
    if (v == undefined) then z_.None else new z_.Some(v)

  ###*
   Takes elements from the cache up to when the predicate `f` is satisfied
   @memberof! dds.DataCache#
   @function takeWithFilter
   @param {function} f - the predicate
   @return {Array} - taken cache values
  ###
  takeWithFilter: (f) ->
    result = []
    for k, v of @cache
      tv = e for e in v when f(e)
      rv = e for e in v when not f(e)
      result = result.concat(tv)
      @cache[k] = rv
    result

  ###*
    Return `coffez.Some(v)` if there is an element in the cache corresponding to the
    key `k` otherwise it returns `coffez.None`.
     @memberof! dds.DataCache#
     @function get
     @param {*} k - key
     @see coffez.Some
     @see coffez.None
  ###
  get: (k) ->
    v = @cache[k]
    if (v == undefined) then z_.None else new z_.Some(v)


  ###*
   Return `coffez.Some(v)` if there is an element in the cache corresponding to the
   key `k` otherwise executes `f` and returns its result.
   @memberof! dds.DataCache#
   @function getOrElse
   @param {*} k - key
   @param {function} f - the function to apply
  ###
  getOrElse: (k, f) ->
    v = @cache[k]
    if (v == undefined) then f() else new z_.Some(v)

  ###*
     folds the element of the cache using `z` as the `zero` element and
     `f` as the binary operator.
     @memberof! dds.DataCache#
     @function fold
     @param z - initial value
     @param {function} f - reduce function
    ###
  fold: (z) => (f) =>
    r = z
    for k, v of @cache
      r = r + v.reduceRight(f)
    r

  ###*
  clears the data cache.
  @memberof! dds.DataCache#
  @function clear
  ###
  clear: () =>
    @cache = {}




###*
Binds a reader to a cache. Notice that this is a curried function,
 whose first parameter `getkey` provides the key to be used with the
 data provided by the DataReader
 @memberof dds#
 @function bind
 @param {function} getKey - a function returning the topic key
 @returns {function} - a function f(reader, cache) used to bind a DataReader
 to a DataCache so that the received data is written into that cache
###
dds.bind = (key) -> (reader, cache) ->
  reader.addListener((d) ->
    if (Array.isArray(d))
      d.forEach((s) -> cache.write(key(s), s))
    else
      cache.write(key(d), d)
  )


###*
Similar to the 'bind' function, but applies a given 'once' function on the cache before
being fed by the received data.
 @memberof dds#
 @function bindWithOnce
 @param {function} getKey - a function returning the topic key
 @returns {function} - a function f(reader, cache, once) used to bind a DataReader
 to a DataCache
###
dds.bindWithOnce = (key) -> (reader, cache, once) ->
  executedOnce = false
  reader.addListener((d) ->
    if (executedOnce == false)
      once(cache)
      executedOnce = true

    if (Array.isArray(d))
      d.forEach((s) -> cache.write(key(s), s))
    else
      cache.write(key(d), d)
  )


dds.DataCache = DataCache

########################################################################################################################
##   Runtime
########################################################################################################################

###
  Protocol
###

DSEntityKind =
  Topic: 0
  DataReader: 1
  DataWriter: 2

DSCommandId =
  OK: 0
  Error: 1
  Create: 2
  Delegate: 3
  Unregister: 4


createHeader = (c, k, s) ->
  h =
    cid: c
    ek: k
    sn: s
  h

createTopicInfo = (domainId, topic, qos) ->
  ti =
    did: domainId
    tn:  topic.tname
    tt: topic.ttype
    qos: qos.policies
  ti

createCommand = (cmdId, kind) -> (seqn, topic, qos) ->
  th = createHeader(cmdId, kind, seqn)
  tb = createTopicInfo(topic.did, topic, qos)
  cmd =
    h: th
    b: tb
  cmd


dds.DSEntityKind = DSEntityKind
dds.DSCommandId = DSCommandId
dds.createDataReaderCommand = createCommand(DSCommandId.Create, DSEntityKind.DataReader)
dds.createDataWriterCommand = createCommand(DSCommandId.Create, DSEntityKind.DataWriter)

module.exports = dds