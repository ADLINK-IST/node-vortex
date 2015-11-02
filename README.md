# node-vortex
A Node.js module for PrismTech Vortex

## Compiling Coffee Script files
The source of the module is written in CoffeeScript, to compile them to JavaScript:
```bash
grunt compile
```

## To use
```javascript
var vortex = require("node-vortex");
```

### Create an instance of the Vortex client
```javascript
var client = new vortex.runtime.Runtime();
```

### Connecting Vortex client
```javascript
var vortexUrl = "ws://demo-lab.prismtech.com:9000"; // replace if using a private Vortex instance
var vortexCredentials = "uid:pwd"; // replace if using a custom access control plugin for Vortex
client.connect(vortexurl, vortexCredentials);
```

Listening for a successful connection
```javascript
client.onconnect = function() {
    // place logic for a successful connection here
    console.log("Connected");
};
```

### Creating a topic
```javascript
var domain = 0; // override with the specific domain being used
var topicName = "PhoneSensorData"; // the name of the topic subscribing to
var tQos = new vortex.TopicQos(); // can be customized for more complex scenarios

var topic = new vortex.Topic(domain, topicName, tQos);

client.registerTopic(topic);
```

To listen for the registration of a topic to complete
```javascript
topic.onregistered = function() {
    // do something when the topic is registered
};
```

### Subscribing to data updates
```javascript
var drQos = new vortex.DataReaderQos(); // can be customized for more complex scenarios
var sub = new vortex.DataReader(client, topic, drQos);

// to listen for a successful subsription
sub.onconnect = function() {
    // handle succesfful subscription
};

// to listen for data updates
sub.addListener(function(data) {
    // handle data update
});
```

### Publishing data updates
```javascript
var dwQos = new vortex.DataWriterQos(); // can be customized for more complex scenarios
var pub = new vortex.DataWriter(client, topic, drQos);

// to listen for a successful connection
pub.onconnect = function() {
    // handle succesfful connection
};
```

To actually publish data updates
```javascript
var data = {}; // data should be some JSON object
pub.send(data);
```

# Vortex Overview
PrismTech’s Vortex Intelligent Data Sharing Platform provides the leading implementations of the Object Management Group’s Data Distribution Service (DDS) for Real-time Systems standard. DDS is a middleware protocol and API standard for data-centric connectivity and is the only standard able to meet the advanced requirements of the Internet of Things (IoT). DDS provides the low-latency data connectivity, extreme reliability and scalability that business and mission-critical IoT applications need. For more information visit www.prismtech.com/vortex .

# Support
This is a proof of concept/prototype/alpha and is therefore provided as is with no formal support. If you experience an issue or have a question we'll do our best to answer it. In order to help us improve our innovations we would like your feedback and suggestions. Please submit an issue and/or provide suggestions via the GitHub issue tracker or by emailing innovation@prismtech.com.

# License
All use of this source code is subject to the Apache License, Version 2.0. http://www.apache.org/licenses/LICENSE-2.0

“This software is provided as is and for use with PrismTech products only.

DUE TO THE LIMITED NATURE OF THE LICENSE GRANTED, WHICH IS FOR THE LICENSEE’S USE OF THE SOFTWARE ONLY, THE LICENSOR DOES NOT WARRANT TO THE LICENSEE THAT THE SOFTWARE IS FREE FROM FAULTS OR DEFECTS OR THAT THE SOFTWARE WILL MEET LICENSEE’S REQUIREMENTS.  THE LICENSOR SHALL HAVE NO LIABILITY WHATSOEVER FOR ANY ERRORS OR DEFECTS THEREIN.  ACCORDINGLY, THE LICENSEE SHALL USE THE SOFTWARE AT ITS OWN RISK AND IN NO EVENT SHALL THE LICENSOR BE LIABLE TO THE LICENSEE FOR ANY LOSS OR DAMAGE OF ANY KIND (EXCEPT PERSONAL INJURY) OR INABILITY TO USE THE SOFTWARE OR FROM FAULTS OR DEFECTS IN THE SOFTWARE WHETHER CAUSED BY NEGLIGENCE OR OTHERWISE.

IN NO EVENT WHATSOEVER WILL LICENSOR BE LIABLE FOR ANY INDIRECT OR CONSEQUENTIAL LOSS (INCLUDING WITHOUT LIMITATION, LOSS OF USE; DATA; INFORMATION; BUSINESS; PRODUCTION OR GOODWILL), EXEMPLARY OR INCIDENTAL DAMAGES, LOST PROFITS OR OTHER SPECIAL OR PUNITIVE DAMAGES WHATSOEVER, WHETHER IN CONTRACT, TORT, (INCLUDING NEGLIGENCE, STRICT LIABILITY AND ALL OTHERS), WARRANTY, INDEMNITY OR UNDER STATUTE, EVEN IF LICENSOR HAS BEEN ADVISED OF THE LIKLIHOOD OF SAME.

ANY CONDITION, REPRESENTATION OR WARRANTY WHICH MIGHT OTHERWISE BE IMPLIED OR INCORPORATED WITHIN THIS LICENSE BY REASON OF STATUTE OR COMMON LAW OR OTHERWISE, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF MERCHANTABLE OR SATISFACTORY QUALITY AND FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON INFRINGEMENT ARE HEREBY EXPRESSLY EXCLUDED TO THE FULLEST EXTENT PERMITTED BY LAW. “