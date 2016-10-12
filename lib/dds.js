
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
  var ContentFilter, DSCommandId, DSEntityKind, DataCache, DataReader, DataWriter, DestinationOrder, DestinationOrderKind, Durability, DurabilityKind, EntityQos, History, HistoryKind, JSONTopicType, JSONTopicTypeName, JSONTopicTypeSupport, KeyValueTopicType, KeyValueTopicTypeName, Partition, PolicyId, Reliability, ReliabilityKind, SampleInfo, TimeFilter, Topic, TopicInfo, UserDefinedTopicTypeSupport, coffez, createCommand, createHeader, createTopicInfo, dds, isBuiltinTopicType, isJSONTopicType, isKeyValueTopicType, typesSupport, z_,
    slice = [].slice,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  coffez = require("./coffez.js");

  dds = {};

  z_ = coffez;


  /**
  Defines the core Vortex-Web-Client javascript library. It includes the JavaScript API for DDS. This API allows web
   applications to share data among them as well as with native DDS applications.
  @namespace dds
   */

  dds.VERSION = "1.2.4";

  PolicyId = {
    History: 0,
    Reliability: 1,
    Partition: 2,
    ContentFilter: 3,
    TimeFilter: 4,
    Durability: 5,
    DestinationOrder: 6,
    TransportPriority: 7,
    Ownership: 8,
    OwnershipStrength: 9
  };


  /*
     History Policy
   */

  HistoryKind = {
    KeepAll: 0,
    KeepLast: 1
  };


  /**
  History Policy
  @memberof dds#
   @property KeepAll - KEEP_ALL qos policy
   @property KeepLast - KEEP_LAST qos policy
   */

  History = {
    KeepAll: {
      id: PolicyId.History,
      k: HistoryKind.KeepAll
    },
    KeepLast: function(depth) {
      var result;
      result = {
        id: PolicyId.History,
        k: HistoryKind.KeepLast,
        v: depth
      };
      return result;
    }
  };


  /*
    Reliability Policy
   */

  ReliabilityKind = {
    Reliable: 0,
    BestEffort: 1
  };


  /**
    Reliability Policy
    @memberof dds#
     @property BestEffort - 'BestEffort' reliability policy
     @property Reliable - 'Reliable' reliability policy
     @example var qos = Reliability.Reliable
   */

  Reliability = {
    BestEffort: {
      id: PolicyId.Reliability,
      k: ReliabilityKind.BestEffort
    },
    Reliable: {
      id: PolicyId.Reliability,
      k: ReliabilityKind.Reliable
    }
  };


  /**
    Partition Policy.
    @memberof dds#
    @function Partition
    @param {...string} p - partition names
    @returns partition - Partition object
    @example var qos = Partition('p1', 'p2')
   */

  Partition = function() {
    var p, plist, policy;
    p = arguments[0], plist = 2 <= arguments.length ? slice.call(arguments, 1) : [];
    policy = {
      id: PolicyId.Partition,
      vs: plist.concat(p)
    };
    return policy;
  };


  /**
   Content Filter Policy.
   @memberof dds#
   @function ContentFilter
   @param {string} expr
   @returns filter - ContentFilter object
   @example var filter = ContentFilter("x>10 AND y<50")
   */

  ContentFilter = function(expr) {
    var contentFilter;
    contentFilter = {
      id: PolicyId.ContentFilter,
      v: expr
    };
    return contentFilter;
  };


  /**
   Time_Based_Filter Policy.
   @memberof dds#
   @function TimeFilter
   @param {number} period - time duration (unit ?)
   @return timeFilter - TimeFilter policy object
   @example var filter = TimeFilter(100)
   */

  TimeFilter = function(duration) {
    var timeFilter;
    timeFilter = {
      id: PolicyId.TimeFilter,
      v: duration
    };
    return timeFilter;
  };


  /*
    Durability Policy
   */

  DurabilityKind = {
    Volatile: 0,
    TransientLocal: 1,
    Transient: 2,
    Persistent: 3
  };


  /**
    Durability Qos Policy
    @memberof dds#
     @property Volatile - Volatile durability policy
     @property TransientLocal - TransientLocal durability policy
     @property Transient - Transient durability policy
     @property Persistent - Persistent durability policy
   */

  Durability = {
    Volatile: {
      id: PolicyId.Durability,
      k: DurabilityKind.Volatile
    },
    TransientLocal: {
      id: PolicyId.Durability,
      k: DurabilityKind.TransientLocal
    },
    Transient: {
      id: PolicyId.Durability,
      k: DurabilityKind.Transient
    },
    Persistent: {
      id: PolicyId.Durability,
      k: DurabilityKind.Persistent
    }
  };


  /*
    Destination Order Policy
   */

  DestinationOrderKind = {
    ByReceptionTimestamp: 0,
    BySourceTimestamp: 1
  };


  /**
    DestinationOrder QoS Policy.
    @memberof dds#
      @property ByReceptionTimestamp - data is ordered based on the reception time at each Subscriber
      @property BySourceTimestamp - data is ordered based on a time stamp placed at the source (by the Service or by the application)
      @example var qos = DestinationOrder.ByReceptionTimestamp
   */

  DestinationOrder = {
    ByReceptionTimestamp: {
      id: PolicyId.DestinationOrder,
      k: DestinationOrderKind.ByReceptionTimestamp
    },
    BySourceTimestamp: {
      id: PolicyId.DestinationOrder,
      k: DestinationOrderKind.BySourceTimestamp
    }
  };


  /**
    Creates any of the DDS entities quality of service, including DataReaderQos and DataWriterQos.
    @constructor
      @param {...policy} p - Qos policies
  
    @classdesc The Entity QoS is represented as a list of Policies.
    @memberof dds
   */

  EntityQos = (function() {
    function EntityQos() {
      var p, ps;
      p = arguments[0], ps = 2 <= arguments.length ? slice.call(arguments, 1) : [];
      this.policies = arguments.length === 0 ? [] : p ? ps.concat(p) : ps;
    }

    EntityQos.prototype.add = function() {
      var p;
      p = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      return new EntityQos(this.policies.concat(p));
    };

    return EntityQos;

  })();


  /*
    Policy and QoS Exports
   */

  dds.HistoryKind = HistoryKind;

  dds.History = History;

  dds.ReliabilityKind = ReliabilityKind;

  dds.Reliability = Reliability;

  dds.Partition = Partition;

  dds.DurabilityKind = DurabilityKind;

  dds.Durability = Durability;

  dds.TimeFilter = TimeFilter;

  dds.ContentFilter = ContentFilter;

  dds.DestinationOrderKind = DestinationOrderKind;

  dds.DestinationOrder = DestinationOrder;


  /**
    Topic quality of service object
    @memberof dds#
    @name TopicQos
    @type {EntityQos}
    @see dds.EntityQos
   */

  dds.TopicQos = EntityQos;


  /**
    DataReader quality of service object
    @memberof dds#
    @name DataReaderQos
    @type {EntityQos}
    @see dds.EntityQos
   */

  dds.DataReaderQos = EntityQos;


  /**
    DataWriter quality of service object
    @memberof dds#
    @name DataWriterQos
    @type {EntityQos}
    @see dds.EntityQos
   */

  dds.DataWriterQos = EntityQos;


  /**
    SampleInfo is accessed in data samples via the `$info` property and provides instance lifecycle information
    @memberof dds#
     @property {Enum} SampleState - A value of `1` is Read, a value of `2` is NotRead
     @property {Enum} ViewState - A value of `1` is New, a value of `2` is NotNew
     @property {Enum} InstanceState - A value of `1` is Alive, a value of `2` is NotAliveDisposed, a value of `4`
     is NotAliveNoWriters
   */

  SampleInfo = {
    SampleState: {
      Read: 1,
      NotRead: 2
    },
    ViewState: {
      New: 1,
      NotNew: 2
    },
    InstanceState: {
      Alive: 1,
      NotAliveDisposed: 2,
      NotAliveNoWriters: 4
    }
  };

  dds.SampleInfo = SampleInfo;

  JSONTopicTypeName = "org.omg.dds.types.JSONTopicType";

  JSONTopicType = (function() {
    function JSONTopicType(value1) {
      this.value = value1;
    }

    return JSONTopicType;

  })();

  KeyValueTopicType = (function() {
    function KeyValueTopicType(key1, value1) {
      this.key = key1;
      this.value = value1;
    }

    return KeyValueTopicType;

  })();

  KeyValueTopicTypeName = "org.omg.dds.types.KeyValueTopicType";

  isJSONTopicType = function(t) {
    return t.tname === JSONTopicType;
  };

  isKeyValueTopicType = function(t) {
    return t.name === KeyValueTopicType;
  };

  isBuiltinTopicType = function(t) {
    return isJSONTopicType(t) || isKeyValueTopicType(t);
  };

  JSONTopicTypeSupport = {
    id: 0,
    injectType: function(s) {
      var v;
      v = new JSONTopicType(JSON.stringify(s, function(key, value) {
        if (value !== value) {
          return 'NaN';
        }
        return value;
      }));
      console.log("InjectedType = " + (JSON.stringify(v)));
      return v;
    },
    extractType: function(s) {
      var error, m, v;
      m = s.value;
      try {
        v = JSON.parse(m);
      } catch (_error) {
        error = _error;
        m = m(replace(/([:,]|:\[)NaN/g, function(matched) {
          return matched.replace('NaN', '"NaN"');
        }));
        v = JSON.parse(m, function(key, value) {
          if (value === 'NaN') {
            return NaN;
          }
          return value;
        });
      }
      console.log("Extracted Type = " + v);
      return v;
    }
  };

  UserDefinedTopicTypeSupport = {
    id: 1,
    injectType: function(s) {
      return s;
    },
    extractType: function(s) {
      return s;
    }
  };

  typesSupport = [JSONTopicTypeSupport, UserDefinedTopicTypeSupport];

  TopicInfo = (function() {
    function TopicInfo(did1, tname1, qos1, ttype1, tregtype1) {
      this.did = did1;
      this.tname = tname1;
      this.qos = qos1;
      this.ttype = ttype1;
      this.tregtype = tregtype1;
    }

    return TopicInfo;

  })();


  /**
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
   */

  Topic = (function() {
    function Topic(did, tname, qos, ttype, tregtype) {
      var idid, ns;
      if (arguments.length < 2) {
        throw "IllegalArgumentException - You need to provide at least did and topic name";
      }
      idid = parseInt(did);
      if (idid === NaN) {
        throw "IllegalArgumentException - did must be an integer";
      }
      this.onregistered = function() {};
      this.onunregistered = function() {};
      switch (arguments.length) {
        case 2:
        case 3:
          ttype = JSONTopicTypeName;
          ns = ttype.split('.');
          tregtype = ns.reduce(function(x, y) {
            return x + "::" + y;
          });
          this.typeSupportId = JSONTopicTypeSupport.id;
          qos = qos === void 0 ? new dds.TopicQos(Reliability.BestEffort) : qos;
          this.tinfo = new TopicInfo(idid, tname, qos, ttype, tregtype);
          break;
        case 4:
          this.typeSupportId = UserDefinedTopicTypeSupport.id;
          ns = ttype.split('.');
          tregtype = ns.reduce(function(x, y) {
            return x + "::" + y;
          });
          this.tinfo = new TopicInfo(idid, tname, qos, ttype, tregtype);
          break;
        default:
          this.typeSupportId = UserDefinedTopicTypeSupport.id;
          this.tinfo = new TopicInfo(idid, tname, qos, ttype, tregtype);
      }
    }

    return Topic;

  })();


  /**
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
   */

  DataReader = (function() {
    function DataReader(runtime, topic1, qos1) {
      this.runtime = runtime;
      this.topic = topic1;
      this.qos = qos1;
      this.close = bind(this.close, this);
      this.onDataAvailable = bind(this.onDataAvailable, this);
      this.removeListener = bind(this.removeListener, this);
      this.resetStats = bind(this.resetStats, this);
      this.handlers = [];
      this.onclose = function() {};
      this.closed = false;
      this.onconnect = function() {};
      this.ondisconnect = function() {};
      this.connected = false;
      this.eid = this.runtime.generateEntityId();
      this.runtime.createDataReader(this);
      this.receivedSamples = 0;
      this.typeSupport = typesSupport[this.topic.typeSupportId];
    }

    DataReader.prototype.resetStats = function() {
      return this.receivedSamples = 0;
    };


    /**
      Attaches the  listener `l` to this data reader and returns
      the id associated to the listener.
         @param {function} l - listener code
         @returns {handle} - listener handle
         @memberof! dds.DataReader#
         @function addListener
     */

    DataReader.prototype.addListener = function(l) {
      var idx;
      idx = this.handlers.length;
      this.handlers = this.handlers.concat(l);
      return idx;
    };


    /**
      removes a listener from this data reader.
      @param {number} idx - listener id
      @memberof! dds.DataReader#
      @function removeListener
     */

    DataReader.prototype.removeListener = function(idx) {
      var h;
      h = this.handlers;
      return this.handlers = h.slice(0, idx).concat(h.slice(idx + 1, h.length));
    };

    DataReader.prototype.onDataAvailable = function(m) {
      var d, error, parsedm;
      this.receivedSamples += 1;
      try {
        parsedm = JSON.parse(m);
      } catch (_error) {
        error = _error;
        m = m.replace(/([:,]|:\[)NaN/g, function(matched) {
          return matched.replace('NaN', '"NaN"');
        });
        parsedm = JSON.parse(m, function(key, value) {
          if (value === 'NaN') {
            return NaN;
          }
          return value;
        });
      }
      d = this.typeSupport.extractType(parsedm);
      return this.handlers.forEach(function(h) {
        return h(d);
      });
    };


    /**
      closes the DataReader.
      @memberof! dds.DataReader#
      @function close
     */

    DataReader.prototype.close = function() {
      console.log("Closing DR " + this);
      this.closed = true;
      this.runtime.closeDataReader(this);
      return this.onclose();
    };

    return DataReader;

  })();


  /**
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
   */

  DataWriter = (function() {
    function DataWriter(runtime, topic1, qos1) {
      this.runtime = runtime;
      this.topic = topic1;
      this.qos = qos1;
      this.dispose = bind(this.dispose, this);
      this.write = bind(this.write, this);
      this.onclose = function() {};
      this.closed = false;
      this.onconnect = function() {};
      this.ondisconnect = function() {};
      this.connected = false;
      this.eid = this.runtime.generateEntityId();
      this.runtime.createDataWriter(this);
      this.typeSupport = typesSupport[this.topic.typeSupportId];
      this.sentSamples = 0;
    }


    /**
      Writes one or more samples.
      The returned samples contained the SampleInfo
      accessible from the `info` property
      @param {...data-type} ds - data samples
      @memberof! dds.DataWriter#
      @function write
     */

    DataWriter.prototype.write = function() {
      var ds, xs;
      ds = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      xs = ds.map((function(_this) {
        return function(s) {
          return _this.typeSupport.injectType(s);
        };
      })(this));
      this.runtime.writeData(this, xs);
      return this.sentSamples += xs.length;
    };


    /**
      Dispose one or more instances.
      @param {...data-type} ds - data samples, each containing
      the key of the instance to be disposed
      @memberof! dds.DataWriter#
      @function dispose
     */

    DataWriter.prototype.dispose = function() {
      var ds, xs;
      ds = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      xs = ds.map((function(_this) {
        return function(s) {
          return _this.typeSupport.injectType(s);
        };
      })(this));
      this.runtime.disposeData(this, xs);
      return this.sentSamples += xs.length;
    };

    DataWriter.prototype.resetStats = function() {
      return this.sentSamples = 0;
    };


    /**
      Closes the DataWriter.
      @memberof! dds.DataWriter#
      @function close
     */

    DataWriter.prototype.close = function() {
      this.closed = true;
      this.socket = new z_.Fail("Invalid State Exception: Can't write on a closed DataWriter");
      this.runtime.closeDataWriter(this);
      return this.onclose();
    };

    return DataWriter;

  })();

  dds.Topic = Topic;

  dds.DataReader = DataReader;

  dds.DataWriter = DataWriter;


  /**
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
   */

  DataCache = (function() {
    function DataCache(depth1, cache1) {
      this.depth = depth1;
      this.cache = cache1;
      this.clear = bind(this.clear, this);
      this.fold = bind(this.fold, this);
      if ((this.cache != null) === false) {
        this.cache = {};
      }
      this.listeners = [];
    }


    /**
      Register a listener to be notified whenever data which matches a predicate is written into the cache.
      If no predicate is provided then the listeners is always notified upon data inserion.
      @memberof! dds.DataCache#
      @function addListener
      @param {function} l - listener function
      @param {function} p - predicate
     */

    DataCache.prototype.addListener = function(l, p) {
      var entry, predicate;
      if (predicate === void 0) {
        predicate = function(x) {
          return true;
        };
      }
      entry = {
        predicate: p,
        listener: l
      };
      return this.listeners = this.listeners.concat(entry);
    };


    /**
      Write the element `data` with key `k` into the cache.
      @memberof! dds.DataCache#
      @param {*} k - data key
      @param {*} data - data value
      @returns {*} - the written data value
      @function  write
     */

    DataCache.prototype.write = function(k, data) {
      var v;
      v = this.cache[k];
      if ((v != null) === false) {
        v = [data];
      } else {
        v = v.length < this.depth ? v.concat(data) : v.slice(1, v.lenght).concat(data);
      }
      this.cache[k] = v;
      return this.listeners.forEach(function(e) {
        if (e.predicate(data) === true) {
          return e.listener(data);
        }
      });
    };


    /**
      Same as forEach but applied, for each key, only to the first `n` samples of the cache
      @memberof! dds.DataCache#
      @function forEachN
      @param {function} f - the function to be applied
      @param {integer} n - samples set size
      @returns {Array} - results of the function execution
      @see dds.DataCache#forEach
     */

    DataCache.prototype.forEachN = function(f, n) {
      var k, ref, results, v;
      ref = this.cache;
      results = [];
      for (k in ref) {
        v = ref[k];
        results.push(v.slice(0, +(n - 1) + 1 || 9e9).forEach(f));
      }
      return results;
    };


    /**
      Execute the function `f` for each element of the cache.
      @memberof! dds.DataCache#
      @param {function} f - the function to be applied
      @returns {Array} - results of the function execution
      @function forEach
     */

    DataCache.prototype.forEach = function(f) {
      var k, ref, results, v;
      ref = this.cache;
      results = [];
      for (k in ref) {
        v = ref[k];
        results.push(v.forEach(f));
      }
      return results;
    };


    /**
     Returns a cache that is the result of applying `f` to each element of the cache.
     @memberof! dds.DataCache#
     @param {function} f - the function to be applied
     @returns {DataCache} - A cache holding the results of the function execution
     @function map
     */

    DataCache.prototype.map = function(f) {
      var k, ref, result, v;
      result = {};
      ref = this.cache;
      for (k in ref) {
        v = ref[k];
        result[k] = v.map(f);
      }
      return new DataCache(this.depth, result);
    };


    /**
     Returns the list of elements in the cache that satisfy the predicate `f`.
     @memberof! dds.DataCache#
     @function filter
     @param {function} f - the predicate to be applied to filter the cache values
     @returns {Array} - An array holding the filtered values
     */

    DataCache.prototype.filter = function(f) {
      var fv, i, k, len, ref, result, rv, v;
      result = {};
      ref = this.cache;
      for (k in ref) {
        v = ref[k];
        for (i = 0, len = v.length; i < len; i++) {
          fv = v[i];
          if (f(v)) {
            rv = fv;
          }
        }
        if (rv.length !== 0) {
          result[k] = rv;
        }
      }
      return result;
    };


    /**
      Returns the list of elements in the cache that doesn't satisfy the predicate `f`.
      @memberof! dds.DataCache#
      @function filterNot
      @returns {Array} - An array holding the filtered values
      @see dds.DataCache#filter
     */

    DataCache.prototype.filterNot = function(f) {
      return filter(function(s) {
        return !f(s);
      });
    };


    /**
     Returns the values included in the cache as an array.
     @memberof! dds.DataCache#
     @function read
     @return {Array} - All the cache values
     */

    DataCache.prototype.read = function() {
      var k, ref, result, v;
      result = [];
      ref = this.cache;
      for (k in ref) {
        v = ref[k];
        result = result.concat(v);
      }
      return result;
    };


    /**
     Returns the last value of the cache in an array.
     @memberof! dds.DataCache#
     @function readLast
     @return {Array} - the last value of the cache
     */

    DataCache.prototype.readLast = function() {
      var k, ref, result, v;
      result = [];
      ref = this.cache;
      for (k in ref) {
        v = ref[k];
        result.add(v[v.length(-1)]);
      }
      return result;
    };


    /**
     Returns all the values included in the cache as an array and empties the cache.
     @memberof! dds.DataCache#
     @function takeAll
     @return {Array} - All the cache values
     */

    DataCache.prototype.takeAll = function() {
      var k, result, tmpCache, v;
      tmpCache = this.cache;
      this.cache = [];
      result = [];
      for (k in tmpCache) {
        v = tmpCache[k];
        result = result.concat(v);
      }
      return result;
    };


    /**
     Returns the `K`ith value of the cache as Monad, ie: `coffez.Some` if it exists, `coffez.None` if not.
     @memberof! dds.DataCache#
     @function take
     @see coffez.Some
     @see coffez.None
     */

    DataCache.prototype.take = function(k) {
      var v;
      v = this.cache[k];
      this.cache[k] = [];
      if (v === void 0) {
        return z_.None;
      } else {
        return new z_.Some(v);
      }
    };


    /**
     Takes elements from the cache up to when the predicate `f` is satisfied
     @memberof! dds.DataCache#
     @function takeWithFilter
     @param {function} f - the predicate
     @return {Array} - taken cache values
     */

    DataCache.prototype.takeWithFilter = function(f) {
      var e, i, j, k, len, len1, ref, result, rv, tv, v;
      result = [];
      ref = this.cache;
      for (k in ref) {
        v = ref[k];
        for (i = 0, len = v.length; i < len; i++) {
          e = v[i];
          if (f(e)) {
            tv = e;
          }
        }
        for (j = 0, len1 = v.length; j < len1; j++) {
          e = v[j];
          if (!f(e)) {
            rv = e;
          }
        }
        result = result.concat(tv);
        this.cache[k] = rv;
      }
      return result;
    };


    /**
      Return `coffez.Some(v)` if there is an element in the cache corresponding to the
      key `k` otherwise it returns `coffez.None`.
       @memberof! dds.DataCache#
       @function get
       @param {*} k - key
       @see coffez.Some
       @see coffez.None
     */

    DataCache.prototype.get = function(k) {
      var v;
      v = this.cache[k];
      if (v === void 0) {
        return z_.None;
      } else {
        return new z_.Some(v);
      }
    };


    /**
     Return `coffez.Some(v)` if there is an element in the cache corresponding to the
     key `k` otherwise executes `f` and returns its result.
     @memberof! dds.DataCache#
     @function getOrElse
     @param {*} k - key
     @param {function} f - the function to apply
     */

    DataCache.prototype.getOrElse = function(k, f) {
      var v;
      v = this.cache[k];
      if (v === void 0) {
        return f();
      } else {
        return new z_.Some(v);
      }
    };


    /**
       folds the element of the cache using `z` as the `zero` element and
       `f` as the binary operator.
       @memberof! dds.DataCache#
       @function fold
       @param z - initial value
       @param {function} f - reduce function
     */

    DataCache.prototype.fold = function(z) {
      return (function(_this) {
        return function(f) {
          var k, r, ref, v;
          r = z;
          ref = _this.cache;
          for (k in ref) {
            v = ref[k];
            r = r + v.reduceRight(f);
          }
          return r;
        };
      })(this);
    };


    /**
    clears the data cache.
    @memberof! dds.DataCache#
    @function clear
     */

    DataCache.prototype.clear = function() {
      return this.cache = {};
    };

    return DataCache;

  })();


  /**
  Binds a reader to a cache. Notice that this is a curried function,
   whose first parameter `getkey` provides the key to be used with the
   data provided by the DataReader
   @memberof dds#
   @function bind
   @param {function} getKey - a function returning the topic key
   @returns {function} - a function f(reader, cache) used to bind a DataReader
   to a DataCache so that the received data is written into that cache
   */

  dds.bind = function(key) {
    return function(reader, cache) {
      return reader.addListener(function(d) {
        if (Array.isArray(d)) {
          return d.forEach(function(s) {
            return cache.write(key(s), s);
          });
        } else {
          return cache.write(key(d), d);
        }
      });
    };
  };


  /**
  Similar to the 'bind' function, but applies a given 'once' function on the cache before
  being fed by the received data.
   @memberof dds#
   @function bindWithOnce
   @param {function} getKey - a function returning the topic key
   @returns {function} - a function f(reader, cache, once) used to bind a DataReader
   to a DataCache
   */

  dds.bindWithOnce = function(key) {
    return function(reader, cache, once) {
      var executedOnce;
      executedOnce = false;
      return reader.addListener(function(d) {
        if (executedOnce === false) {
          once(cache);
          executedOnce = true;
        }
        if (Array.isArray(d)) {
          return d.forEach(function(s) {
            return cache.write(key(s), s);
          });
        } else {
          return cache.write(key(d), d);
        }
      });
    };
  };

  dds.DataCache = DataCache;


  /*
    Protocol
   */

  DSEntityKind = {
    Topic: 0,
    DataReader: 1,
    DataWriter: 2
  };

  DSCommandId = {
    OK: 0,
    Error: 1,
    Create: 2,
    Delegate: 3,
    Unregister: 4
  };

  createHeader = function(c, k, s) {
    var h;
    h = {
      cid: c,
      ek: k,
      sn: s
    };
    return h;
  };

  createTopicInfo = function(domainId, topic, qos) {
    var ti;
    ti = {
      did: domainId,
      tn: topic.tname,
      tt: topic.ttype,
      qos: qos.policies
    };
    return ti;
  };

  createCommand = function(cmdId, kind) {
    return function(seqn, topic, qos) {
      var cmd, tb, th;
      th = createHeader(cmdId, kind, seqn);
      tb = createTopicInfo(topic.did, topic, qos);
      cmd = {
        h: th,
        b: tb
      };
      return cmd;
    };
  };

  dds.DSEntityKind = DSEntityKind;

  dds.DSCommandId = DSCommandId;

  dds.createDataReaderCommand = createCommand(DSCommandId.Create, DSEntityKind.DataReader);

  dds.createDataWriterCommand = createCommand(DSCommandId.Create, DSEntityKind.DataWriter);

  module.exports = dds;

}).call(this);
