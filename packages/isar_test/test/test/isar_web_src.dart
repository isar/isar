// ignore_for_file: unnecessary_string_escapes
const isarWebSrc = '''
/******/ (() => { // webpackBootstrap
/******/ 	"use strict";
/******/ 	var __webpack_modules__ = ({

/***/ "./node_modules/broadcast-channel/dist/esbrowser/broadcast-channel.js":
/*!****************************************************************************!*\
  !*** ./node_modules/broadcast-channel/dist/esbrowser/broadcast-channel.js ***!
  \****************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "OPEN_BROADCAST_CHANNELS": () => (/* binding */ OPEN_BROADCAST_CHANNELS),
/* harmony export */   "BroadcastChannel": () => (/* binding */ BroadcastChannel),
/* harmony export */   "clearNodeFolder": () => (/* binding */ clearNodeFolder),
/* harmony export */   "enforceOptions": () => (/* binding */ enforceOptions)
/* harmony export */ });
/* harmony import */ var _util_js__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ./util.js */ "./node_modules/broadcast-channel/dist/esbrowser/util.js");
/* harmony import */ var _method_chooser_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./method-chooser.js */ "./node_modules/broadcast-channel/dist/esbrowser/method-chooser.js");
/* harmony import */ var _options_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./options.js */ "./node_modules/broadcast-channel/dist/esbrowser/options.js");



/**
 * Contains all open channels,
 * used in tests to ensure everything is closed.
 */

var OPEN_BROADCAST_CHANNELS = new Set();
var lastId = 0;
var BroadcastChannel = function BroadcastChannel(name, options) {
  // identifier of the channel to debug stuff
  this.id = lastId++;
  OPEN_BROADCAST_CHANNELS.add(this);
  this.name = name;

  if (ENFORCED_OPTIONS) {
    options = ENFORCED_OPTIONS;
  }

  this.options = (0,_options_js__WEBPACK_IMPORTED_MODULE_0__.fillOptionsWithDefaults)(options);
  this.method = (0,_method_chooser_js__WEBPACK_IMPORTED_MODULE_1__.chooseMethod)(this.options); // isListening

  this._iL = false;
  /**
   * _onMessageListener
   * setting onmessage twice,
   * will overwrite the first listener
   */

  this._onML = null;
  /**
   * _addEventListeners
   */

  this._addEL = {
    message: [],
    internal: []
  };
  /**
   * Unsend message promises
   * where the sending is still in progress
   * @type {Set<Promise>}
   */

  this._uMP = new Set();
  /**
   * _beforeClose
   * array of promises that will be awaited
   * before the channel is closed
   */

  this._befC = [];
  /**
   * _preparePromise
   */

  this._prepP = null;

  _prepareChannel(this);
}; // STATICS

/**
 * used to identify if someone overwrites
 * window.BroadcastChannel with this
 * See methods/native.js
 */

BroadcastChannel._pubkey = true;
/**
 * clears the tmp-folder if is node
 * @return {Promise<boolean>} true if has run, false if not node
 */

function clearNodeFolder(options) {
  options = (0,_options_js__WEBPACK_IMPORTED_MODULE_0__.fillOptionsWithDefaults)(options);
  var method = (0,_method_chooser_js__WEBPACK_IMPORTED_MODULE_1__.chooseMethod)(options);

  if (method.type === 'node') {
    return method.clearNodeFolder().then(function () {
      return true;
    });
  } else {
    return _util_js__WEBPACK_IMPORTED_MODULE_2__.PROMISE_RESOLVED_FALSE;
  }
}
/**
 * if set, this method is enforced,
 * no mather what the options are
 */

var ENFORCED_OPTIONS;
function enforceOptions(options) {
  ENFORCED_OPTIONS = options;
} // PROTOTYPE

BroadcastChannel.prototype = {
  postMessage: function postMessage(msg) {
    if (this.closed) {
      throw new Error('BroadcastChannel.postMessage(): ' + 'Cannot post message after channel has closed ' +
      /**
       * In the past when this error appeared, it was realy hard to debug.
       * So now we log the msg together with the error so it at least
       * gives some clue about where in your application this happens.
       */
      JSON.stringify(msg));
    }

    return _post(this, 'message', msg);
  },
  postInternal: function postInternal(msg) {
    return _post(this, 'internal', msg);
  },

  set onmessage(fn) {
    var time = this.method.microSeconds();
    var listenObj = {
      time: time,
      fn: fn
    };

    _removeListenerObject(this, 'message', this._onML);

    if (fn && typeof fn === 'function') {
      this._onML = listenObj;

      _addListenerObject(this, 'message', listenObj);
    } else {
      this._onML = null;
    }
  },

  addEventListener: function addEventListener(type, fn) {
    var time = this.method.microSeconds();
    var listenObj = {
      time: time,
      fn: fn
    };

    _addListenerObject(this, type, listenObj);
  },
  removeEventListener: function removeEventListener(type, fn) {
    var obj = this._addEL[type].find(function (obj) {
      return obj.fn === fn;
    });

    _removeListenerObject(this, type, obj);
  },
  close: function close() {
    var _this = this;

    if (this.closed) {
      return;
    }

    OPEN_BROADCAST_CHANNELS["delete"](this);
    this.closed = true;
    var awaitPrepare = this._prepP ? this._prepP : _util_js__WEBPACK_IMPORTED_MODULE_2__.PROMISE_RESOLVED_VOID;
    this._onML = null;
    this._addEL.message = [];
    return awaitPrepare // wait until all current sending are processed
    .then(function () {
      return Promise.all(Array.from(_this._uMP));
    }) // run before-close hooks
    .then(function () {
      return Promise.all(_this._befC.map(function (fn) {
        return fn();
      }));
    }) // close the channel
    .then(function () {
      return _this.method.close(_this._state);
    });
  },

  get type() {
    return this.method.type;
  },

  get isClosed() {
    return this.closed;
  }

};
/**
 * Post a message over the channel
 * @returns {Promise} that resolved when the message sending is done
 */

function _post(broadcastChannel, type, msg) {
  var time = broadcastChannel.method.microSeconds();
  var msgObj = {
    time: time,
    type: type,
    data: msg
  };
  var awaitPrepare = broadcastChannel._prepP ? broadcastChannel._prepP : _util_js__WEBPACK_IMPORTED_MODULE_2__.PROMISE_RESOLVED_VOID;
  return awaitPrepare.then(function () {
    var sendPromise = broadcastChannel.method.postMessage(broadcastChannel._state, msgObj); // add/remove to unsend messages list

    broadcastChannel._uMP.add(sendPromise);

    sendPromise["catch"]().then(function () {
      return broadcastChannel._uMP["delete"](sendPromise);
    });
    return sendPromise;
  });
}

function _prepareChannel(channel) {
  var maybePromise = channel.method.create(channel.name, channel.options);

  if ((0,_util_js__WEBPACK_IMPORTED_MODULE_2__.isPromise)(maybePromise)) {
    channel._prepP = maybePromise;
    maybePromise.then(function (s) {
      // used in tests to simulate slow runtime

      /*if (channel.options.prepareDelay) {
           await new Promise(res => setTimeout(res, this.options.prepareDelay));
      }*/
      channel._state = s;
    });
  } else {
    channel._state = maybePromise;
  }
}

function _hasMessageListeners(channel) {
  if (channel._addEL.message.length > 0) return true;
  if (channel._addEL.internal.length > 0) return true;
  return false;
}

function _addListenerObject(channel, type, obj) {
  channel._addEL[type].push(obj);

  _startListening(channel);
}

function _removeListenerObject(channel, type, obj) {
  channel._addEL[type] = channel._addEL[type].filter(function (o) {
    return o !== obj;
  });

  _stopListening(channel);
}

function _startListening(channel) {
  if (!channel._iL && _hasMessageListeners(channel)) {
    // someone is listening, start subscribing
    var listenerFn = function listenerFn(msgObj) {
      channel._addEL[msgObj.type].forEach(function (listenerObject) {
        /**
         * Getting the current time in JavaScript has no good precision.
         * So instead of only listening to events that happend 'after' the listener
         * was added, we also listen to events that happended 100ms before it.
         * This ensures that when another process, like a WebWorker, sends events
         * we do not miss them out because their timestamp is a bit off compared to the main process.
         * Not doing this would make messages missing when we send data directly after subscribing and awaiting a response.
         * @link https://johnresig.com/blog/accuracy-of-javascript-time/
         */
        var hundredMsInMicro = 100 * 1000;
        var minMessageTime = listenerObject.time - hundredMsInMicro;

        if (msgObj.time >= minMessageTime) {
          listenerObject.fn(msgObj.data);
        }
      });
    };

    var time = channel.method.microSeconds();

    if (channel._prepP) {
      channel._prepP.then(function () {
        channel._iL = true;
        channel.method.onMessage(channel._state, listenerFn, time);
      });
    } else {
      channel._iL = true;
      channel.method.onMessage(channel._state, listenerFn, time);
    }
  }
}

function _stopListening(channel) {
  if (channel._iL && !_hasMessageListeners(channel)) {
    // noone is listening, stop subscribing
    channel._iL = false;
    var time = channel.method.microSeconds();
    channel.method.onMessage(channel._state, null, time);
  }
}

/***/ }),

/***/ "./node_modules/broadcast-channel/dist/esbrowser/method-chooser.js":
/*!*************************************************************************!*\
  !*** ./node_modules/broadcast-channel/dist/esbrowser/method-chooser.js ***!
  \*************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "chooseMethod": () => (/* binding */ chooseMethod)
/* harmony export */ });
/* harmony import */ var _methods_native_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./methods/native.js */ "./node_modules/broadcast-channel/dist/esbrowser/methods/native.js");
/* harmony import */ var _methods_indexed_db_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./methods/indexed-db.js */ "./node_modules/broadcast-channel/dist/esbrowser/methods/indexed-db.js");
/* harmony import */ var _methods_localstorage_js__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ./methods/localstorage.js */ "./node_modules/broadcast-channel/dist/esbrowser/methods/localstorage.js");
/* harmony import */ var _methods_simulate_js__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(/*! ./methods/simulate.js */ "./node_modules/broadcast-channel/dist/esbrowser/methods/simulate.js");
/* harmony import */ var _util__WEBPACK_IMPORTED_MODULE_4__ = __webpack_require__(/*! ./util */ "./node_modules/broadcast-channel/dist/esbrowser/util.js");



 // the line below will be removed from es5/browser builds


 // order is important

var METHODS = [_methods_native_js__WEBPACK_IMPORTED_MODULE_0__["default"], // fastest
_methods_indexed_db_js__WEBPACK_IMPORTED_MODULE_1__["default"], _methods_localstorage_js__WEBPACK_IMPORTED_MODULE_2__["default"]];
function chooseMethod(options) {
  var chooseMethods = [].concat(options.methods, METHODS).filter(Boolean); // the line below will be removed from es5/browser builds



  if (options.type) {
    if (options.type === 'simulate') {
      // only use simulate-method if directly chosen
      return _methods_simulate_js__WEBPACK_IMPORTED_MODULE_3__["default"];
    }

    var ret = chooseMethods.find(function (m) {
      return m.type === options.type;
    });
    if (!ret) throw new Error('method-type ' + options.type + ' not found');else return ret;
  }
  /**
   * if no webworker support is needed,
   * remove idb from the list so that localstorage is been chosen
   */


  if (!options.webWorkerSupport && !_util__WEBPACK_IMPORTED_MODULE_4__.isNode) {
    chooseMethods = chooseMethods.filter(function (m) {
      return m.type !== 'idb';
    });
  }

  var useMethod = chooseMethods.find(function (method) {
    return method.canBeUsed();
  });
  if (!useMethod) throw new Error("No useable method found in " + JSON.stringify(METHODS.map(function (m) {
    return m.type;
  })));else return useMethod;
}

/***/ }),

/***/ "./node_modules/broadcast-channel/dist/esbrowser/methods/indexed-db.js":
/*!*****************************************************************************!*\
  !*** ./node_modules/broadcast-channel/dist/esbrowser/methods/indexed-db.js ***!
  \*****************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "microSeconds": () => (/* binding */ microSeconds),
/* harmony export */   "TRANSACTION_SETTINGS": () => (/* binding */ TRANSACTION_SETTINGS),
/* harmony export */   "type": () => (/* binding */ type),
/* harmony export */   "getIdb": () => (/* binding */ getIdb),
/* harmony export */   "commitIndexedDBTransaction": () => (/* binding */ commitIndexedDBTransaction),
/* harmony export */   "createDatabase": () => (/* binding */ createDatabase),
/* harmony export */   "writeMessage": () => (/* binding */ writeMessage),
/* harmony export */   "getAllMessages": () => (/* binding */ getAllMessages),
/* harmony export */   "getMessagesHigherThan": () => (/* binding */ getMessagesHigherThan),
/* harmony export */   "removeMessagesById": () => (/* binding */ removeMessagesById),
/* harmony export */   "getOldMessages": () => (/* binding */ getOldMessages),
/* harmony export */   "cleanOldMessages": () => (/* binding */ cleanOldMessages),
/* harmony export */   "create": () => (/* binding */ create),
/* harmony export */   "close": () => (/* binding */ close),
/* harmony export */   "postMessage": () => (/* binding */ postMessage),
/* harmony export */   "onMessage": () => (/* binding */ onMessage),
/* harmony export */   "canBeUsed": () => (/* binding */ canBeUsed),
/* harmony export */   "averageResponseTime": () => (/* binding */ averageResponseTime),
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var _util_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ../util.js */ "./node_modules/broadcast-channel/dist/esbrowser/util.js");
/* harmony import */ var oblivious_set__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! oblivious-set */ "./node_modules/oblivious-set/dist/es/index.js");
/* harmony import */ var _options__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ../options */ "./node_modules/broadcast-channel/dist/esbrowser/options.js");
/**
 * this method uses indexeddb to store the messages
 * There is currently no observerAPI for idb
 * @link https://github.com/w3c/IndexedDB/issues/51
 * 
 * When working on this, ensure to use these performance optimizations:
 * @link https://rxdb.info/slow-indexeddb.html
 */

var microSeconds = _util_js__WEBPACK_IMPORTED_MODULE_0__.microSeconds;


var DB_PREFIX = 'pubkey.broadcast-channel-0-';
var OBJECT_STORE_ID = 'messages';
/**
 * Use relaxed durability for faster performance on all transactions.
 * @link https://nolanlawson.com/2021/08/22/speeding-up-indexeddb-reads-and-writes/
 */

var TRANSACTION_SETTINGS = {
  durability: 'relaxed'
};
var type = 'idb';
function getIdb() {
  if (typeof indexedDB !== 'undefined') return indexedDB;

  if (typeof window !== 'undefined') {
    if (typeof window.mozIndexedDB !== 'undefined') return window.mozIndexedDB;
    if (typeof window.webkitIndexedDB !== 'undefined') return window.webkitIndexedDB;
    if (typeof window.msIndexedDB !== 'undefined') return window.msIndexedDB;
  }

  return false;
}
/**
 * If possible, we should explicitly commit IndexedDB transactions
 * for better performance.
 * @link https://nolanlawson.com/2021/08/22/speeding-up-indexeddb-reads-and-writes/
 */

function commitIndexedDBTransaction(tx) {
  if (tx.commit) {
    tx.commit();
  }
}
function createDatabase(channelName) {
  var IndexedDB = getIdb(); // create table

  var dbName = DB_PREFIX + channelName;
  /**
   * All IndexedDB databases are opened without version
   * because it is a bit faster, especially on firefox
   * @link http://nparashuram.com/IndexedDB/perf/#Open%20Database%20with%20version
   */

  var openRequest = IndexedDB.open(dbName);

  openRequest.onupgradeneeded = function (ev) {
    var db = ev.target.result;
    db.createObjectStore(OBJECT_STORE_ID, {
      keyPath: 'id',
      autoIncrement: true
    });
  };

  var dbPromise = new Promise(function (res, rej) {
    openRequest.onerror = function (ev) {
      return rej(ev);
    };

    openRequest.onsuccess = function () {
      res(openRequest.result);
    };
  });
  return dbPromise;
}
/**
 * writes the new message to the database
 * so other readers can find it
 */

function writeMessage(db, readerUuid, messageJson) {
  var time = new Date().getTime();
  var writeObject = {
    uuid: readerUuid,
    time: time,
    data: messageJson
  };
  var tx = db.transaction([OBJECT_STORE_ID], 'readwrite', TRANSACTION_SETTINGS);
  return new Promise(function (res, rej) {
    tx.oncomplete = function () {
      return res();
    };

    tx.onerror = function (ev) {
      return rej(ev);
    };

    var objectStore = tx.objectStore(OBJECT_STORE_ID);
    objectStore.add(writeObject);
    commitIndexedDBTransaction(tx);
  });
}
function getAllMessages(db) {
  var tx = db.transaction(OBJECT_STORE_ID, 'readonly', TRANSACTION_SETTINGS);
  var objectStore = tx.objectStore(OBJECT_STORE_ID);
  var ret = [];
  return new Promise(function (res) {
    objectStore.openCursor().onsuccess = function (ev) {
      var cursor = ev.target.result;

      if (cursor) {
        ret.push(cursor.value); //alert("Name for SSN " + cursor.key + " is " + cursor.value.name);

        cursor["continue"]();
      } else {
        commitIndexedDBTransaction(tx);
        res(ret);
      }
    };
  });
}
function getMessagesHigherThan(db, lastCursorId) {
  var tx = db.transaction(OBJECT_STORE_ID, 'readonly', TRANSACTION_SETTINGS);
  var objectStore = tx.objectStore(OBJECT_STORE_ID);
  var ret = [];
  var keyRangeValue = IDBKeyRange.bound(lastCursorId + 1, Infinity);
  /**
   * Optimization shortcut,
   * if getAll() can be used, do not use a cursor.
   * @link https://rxdb.info/slow-indexeddb.html
   */

  if (objectStore.getAll) {
    var getAllRequest = objectStore.getAll(keyRangeValue);
    return new Promise(function (res, rej) {
      getAllRequest.onerror = function (err) {
        return rej(err);
      };

      getAllRequest.onsuccess = function (e) {
        res(e.target.result);
      };
    });
  }

  function openCursor() {
    // Occasionally Safari will fail on IDBKeyRange.bound, this
    // catches that error, having it open the cursor to the first
    // item. When it gets data it will advance to the desired key.
    try {
      keyRangeValue = IDBKeyRange.bound(lastCursorId + 1, Infinity);
      return objectStore.openCursor(keyRangeValue);
    } catch (e) {
      return objectStore.openCursor();
    }
  }

  return new Promise(function (res, rej) {
    var openCursorRequest = openCursor();

    openCursorRequest.onerror = function (err) {
      return rej(err);
    };

    openCursorRequest.onsuccess = function (ev) {
      var cursor = ev.target.result;

      if (cursor) {
        if (cursor.value.id < lastCursorId + 1) {
          cursor["continue"](lastCursorId + 1);
        } else {
          ret.push(cursor.value);
          cursor["continue"]();
        }
      } else {
        commitIndexedDBTransaction(tx);
        res(ret);
      }
    };
  });
}
function removeMessagesById(db, ids) {
  var tx = db.transaction([OBJECT_STORE_ID], 'readwrite', TRANSACTION_SETTINGS);
  var objectStore = tx.objectStore(OBJECT_STORE_ID);
  return Promise.all(ids.map(function (id) {
    var deleteRequest = objectStore["delete"](id);
    return new Promise(function (res) {
      deleteRequest.onsuccess = function () {
        return res();
      };
    });
  }));
}
function getOldMessages(db, ttl) {
  var olderThen = new Date().getTime() - ttl;
  var tx = db.transaction(OBJECT_STORE_ID, 'readonly', TRANSACTION_SETTINGS);
  var objectStore = tx.objectStore(OBJECT_STORE_ID);
  var ret = [];
  return new Promise(function (res) {
    objectStore.openCursor().onsuccess = function (ev) {
      var cursor = ev.target.result;

      if (cursor) {
        var msgObk = cursor.value;

        if (msgObk.time < olderThen) {
          ret.push(msgObk); //alert("Name for SSN " + cursor.key + " is " + cursor.value.name);

          cursor["continue"]();
        } else {
          // no more old messages,
          commitIndexedDBTransaction(tx);
          res(ret);
          return;
        }
      } else {
        res(ret);
      }
    };
  });
}
function cleanOldMessages(db, ttl) {
  return getOldMessages(db, ttl).then(function (tooOld) {
    return removeMessagesById(db, tooOld.map(function (msg) {
      return msg.id;
    }));
  });
}
function create(channelName, options) {
  options = (0,_options__WEBPACK_IMPORTED_MODULE_1__.fillOptionsWithDefaults)(options);
  return createDatabase(channelName).then(function (db) {
    var state = {
      closed: false,
      lastCursorId: 0,
      channelName: channelName,
      options: options,
      uuid: (0,_util_js__WEBPACK_IMPORTED_MODULE_0__.randomToken)(),

      /**
       * emittedMessagesIds
       * contains all messages that have been emitted before
       * @type {ObliviousSet}
       */
      eMIs: new oblivious_set__WEBPACK_IMPORTED_MODULE_2__.ObliviousSet(options.idb.ttl * 2),
      // ensures we do not read messages in parrallel
      writeBlockPromise: _util_js__WEBPACK_IMPORTED_MODULE_0__.PROMISE_RESOLVED_VOID,
      messagesCallback: null,
      readQueuePromises: [],
      db: db
    };
    /**
     * Handle abrupt closes that do not originate from db.close().
     * This could happen, for example, if the underlying storage is
     * removed or if the user clears the database in the browser's
     * history preferences.
     */

    db.onclose = function () {
      state.closed = true;
      if (options.idb.onclose) options.idb.onclose();
    };
    /**
     * if service-workers are used,
     * we have no 'storage'-event if they post a message,
     * therefore we also have to set an interval
     */


    _readLoop(state);

    return state;
  });
}

function _readLoop(state) {
  if (state.closed) return;
  readNewMessages(state).then(function () {
    return (0,_util_js__WEBPACK_IMPORTED_MODULE_0__.sleep)(state.options.idb.fallbackInterval);
  }).then(function () {
    return _readLoop(state);
  });
}

function _filterMessage(msgObj, state) {
  if (msgObj.uuid === state.uuid) return false; // send by own

  if (state.eMIs.has(msgObj.id)) return false; // already emitted

  if (msgObj.data.time < state.messagesCallbackTime) return false; // older then onMessageCallback

  return true;
}
/**
 * reads all new messages from the database and emits them
 */


function readNewMessages(state) {
  // channel already closed
  if (state.closed) return _util_js__WEBPACK_IMPORTED_MODULE_0__.PROMISE_RESOLVED_VOID; // if no one is listening, we do not need to scan for new messages

  if (!state.messagesCallback) return _util_js__WEBPACK_IMPORTED_MODULE_0__.PROMISE_RESOLVED_VOID;
  return getMessagesHigherThan(state.db, state.lastCursorId).then(function (newerMessages) {
    var useMessages = newerMessages
    /**
     * there is a bug in iOS where the msgObj can be undefined some times
     * so we filter them out
     * @link https://github.com/pubkey/broadcast-channel/issues/19
     */
    .filter(function (msgObj) {
      return !!msgObj;
    }).map(function (msgObj) {
      if (msgObj.id > state.lastCursorId) {
        state.lastCursorId = msgObj.id;
      }

      return msgObj;
    }).filter(function (msgObj) {
      return _filterMessage(msgObj, state);
    }).sort(function (msgObjA, msgObjB) {
      return msgObjA.time - msgObjB.time;
    }); // sort by time

    useMessages.forEach(function (msgObj) {
      if (state.messagesCallback) {
        state.eMIs.add(msgObj.id);
        state.messagesCallback(msgObj.data);
      }
    });
    return _util_js__WEBPACK_IMPORTED_MODULE_0__.PROMISE_RESOLVED_VOID;
  });
}

function close(channelState) {
  channelState.closed = true;
  channelState.db.close();
}
function postMessage(channelState, messageJson) {
  channelState.writeBlockPromise = channelState.writeBlockPromise.then(function () {
    return writeMessage(channelState.db, channelState.uuid, messageJson);
  }).then(function () {
    if ((0,_util_js__WEBPACK_IMPORTED_MODULE_0__.randomInt)(0, 10) === 0) {
      /* await (do not await) */
      cleanOldMessages(channelState.db, channelState.options.idb.ttl);
    }
  });
  return channelState.writeBlockPromise;
}
function onMessage(channelState, fn, time) {
  channelState.messagesCallbackTime = time;
  channelState.messagesCallback = fn;
  readNewMessages(channelState);
}
function canBeUsed() {
  if (_util_js__WEBPACK_IMPORTED_MODULE_0__.isNode) return false;
  var idb = getIdb();
  if (!idb) return false;
  return true;
}
function averageResponseTime(options) {
  return options.idb.fallbackInterval * 2;
}
/* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = ({
  create: create,
  close: close,
  onMessage: onMessage,
  postMessage: postMessage,
  canBeUsed: canBeUsed,
  type: type,
  averageResponseTime: averageResponseTime,
  microSeconds: microSeconds
});

/***/ }),

/***/ "./node_modules/broadcast-channel/dist/esbrowser/methods/localstorage.js":
/*!*******************************************************************************!*\
  !*** ./node_modules/broadcast-channel/dist/esbrowser/methods/localstorage.js ***!
  \*******************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "microSeconds": () => (/* binding */ microSeconds),
/* harmony export */   "type": () => (/* binding */ type),
/* harmony export */   "getLocalStorage": () => (/* binding */ getLocalStorage),
/* harmony export */   "storageKey": () => (/* binding */ storageKey),
/* harmony export */   "postMessage": () => (/* binding */ postMessage),
/* harmony export */   "addStorageEventListener": () => (/* binding */ addStorageEventListener),
/* harmony export */   "removeStorageEventListener": () => (/* binding */ removeStorageEventListener),
/* harmony export */   "create": () => (/* binding */ create),
/* harmony export */   "close": () => (/* binding */ close),
/* harmony export */   "onMessage": () => (/* binding */ onMessage),
/* harmony export */   "canBeUsed": () => (/* binding */ canBeUsed),
/* harmony export */   "averageResponseTime": () => (/* binding */ averageResponseTime),
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var oblivious_set__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! oblivious-set */ "./node_modules/oblivious-set/dist/es/index.js");
/* harmony import */ var _options__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ../options */ "./node_modules/broadcast-channel/dist/esbrowser/options.js");
/* harmony import */ var _util__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ../util */ "./node_modules/broadcast-channel/dist/esbrowser/util.js");
/**
 * A localStorage-only method which uses localstorage and its 'storage'-event
 * This does not work inside of webworkers because they have no access to locastorage
 * This is basically implemented to support IE9 or your grandmothers toaster.
 * @link https://caniuse.com/#feat=namevalue-storage
 * @link https://caniuse.com/#feat=indexeddb
 */



var microSeconds = _util__WEBPACK_IMPORTED_MODULE_0__.microSeconds;
var KEY_PREFIX = 'pubkey.broadcastChannel-';
var type = 'localstorage';
/**
 * copied from crosstab
 * @link https://github.com/tejacques/crosstab/blob/master/src/crosstab.js#L32
 */

function getLocalStorage() {
  var localStorage;
  if (typeof window === 'undefined') return null;

  try {
    localStorage = window.localStorage;
    localStorage = window['ie8-eventlistener/storage'] || window.localStorage;
  } catch (e) {// New versions of Firefox throw a Security exception
    // if cookies are disabled. See
    // https://bugzilla.mozilla.org/show_bug.cgi?id=1028153
  }

  return localStorage;
}
function storageKey(channelName) {
  return KEY_PREFIX + channelName;
}
/**
* writes the new message to the storage
* and fires the storage-event so other readers can find it
*/

function postMessage(channelState, messageJson) {
  return new Promise(function (res) {
    (0,_util__WEBPACK_IMPORTED_MODULE_0__.sleep)().then(function () {
      var key = storageKey(channelState.channelName);
      var writeObj = {
        token: (0,_util__WEBPACK_IMPORTED_MODULE_0__.randomToken)(),
        time: new Date().getTime(),
        data: messageJson,
        uuid: channelState.uuid
      };
      var value = JSON.stringify(writeObj);
      getLocalStorage().setItem(key, value);
      /**
       * StorageEvent does not fire the 'storage' event
       * in the window that changes the state of the local storage.
       * So we fire it manually
       */

      var ev = document.createEvent('Event');
      ev.initEvent('storage', true, true);
      ev.key = key;
      ev.newValue = value;
      window.dispatchEvent(ev);
      res();
    });
  });
}
function addStorageEventListener(channelName, fn) {
  var key = storageKey(channelName);

  var listener = function listener(ev) {
    if (ev.key === key) {
      fn(JSON.parse(ev.newValue));
    }
  };

  window.addEventListener('storage', listener);
  return listener;
}
function removeStorageEventListener(listener) {
  window.removeEventListener('storage', listener);
}
function create(channelName, options) {
  options = (0,_options__WEBPACK_IMPORTED_MODULE_1__.fillOptionsWithDefaults)(options);

  if (!canBeUsed()) {
    throw new Error('BroadcastChannel: localstorage cannot be used');
  }

  var uuid = (0,_util__WEBPACK_IMPORTED_MODULE_0__.randomToken)();
  /**
   * eMIs
   * contains all messages that have been emitted before
   * @type {ObliviousSet}
   */

  var eMIs = new oblivious_set__WEBPACK_IMPORTED_MODULE_2__.ObliviousSet(options.localstorage.removeTimeout);
  var state = {
    channelName: channelName,
    uuid: uuid,
    eMIs: eMIs // emittedMessagesIds

  };
  state.listener = addStorageEventListener(channelName, function (msgObj) {
    if (!state.messagesCallback) return; // no listener

    if (msgObj.uuid === uuid) return; // own message

    if (!msgObj.token || eMIs.has(msgObj.token)) return; // already emitted

    if (msgObj.data.time && msgObj.data.time < state.messagesCallbackTime) return; // too old

    eMIs.add(msgObj.token);
    state.messagesCallback(msgObj.data);
  });
  return state;
}
function close(channelState) {
  removeStorageEventListener(channelState.listener);
}
function onMessage(channelState, fn, time) {
  channelState.messagesCallbackTime = time;
  channelState.messagesCallback = fn;
}
function canBeUsed() {
  if (_util__WEBPACK_IMPORTED_MODULE_0__.isNode) return false;
  var ls = getLocalStorage();
  if (!ls) return false;

  try {
    var key = '__broadcastchannel_check';
    ls.setItem(key, 'works');
    ls.removeItem(key);
  } catch (e) {
    // Safari 10 in private mode will not allow write access to local
    // storage and fail with a QuotaExceededError. See
    // https://developer.mozilla.org/en-US/docs/Web/API/Web_Storage_API#Private_Browsing_Incognito_modes
    return false;
  }

  return true;
}
function averageResponseTime() {
  var defaultTime = 120;
  var userAgent = navigator.userAgent.toLowerCase();

  if (userAgent.includes('safari') && !userAgent.includes('chrome')) {
    // safari is much slower so this time is higher
    return defaultTime * 2;
  }

  return defaultTime;
}
/* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = ({
  create: create,
  close: close,
  onMessage: onMessage,
  postMessage: postMessage,
  canBeUsed: canBeUsed,
  type: type,
  averageResponseTime: averageResponseTime,
  microSeconds: microSeconds
});

/***/ }),

/***/ "./node_modules/broadcast-channel/dist/esbrowser/methods/native.js":
/*!*************************************************************************!*\
  !*** ./node_modules/broadcast-channel/dist/esbrowser/methods/native.js ***!
  \*************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "microSeconds": () => (/* binding */ microSeconds),
/* harmony export */   "type": () => (/* binding */ type),
/* harmony export */   "create": () => (/* binding */ create),
/* harmony export */   "close": () => (/* binding */ close),
/* harmony export */   "postMessage": () => (/* binding */ postMessage),
/* harmony export */   "onMessage": () => (/* binding */ onMessage),
/* harmony export */   "canBeUsed": () => (/* binding */ canBeUsed),
/* harmony export */   "averageResponseTime": () => (/* binding */ averageResponseTime),
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var _util__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ../util */ "./node_modules/broadcast-channel/dist/esbrowser/util.js");

var microSeconds = _util__WEBPACK_IMPORTED_MODULE_0__.microSeconds;
var type = 'native';
function create(channelName) {
  var state = {
    messagesCallback: null,
    bc: new BroadcastChannel(channelName),
    subFns: [] // subscriberFunctions

  };

  state.bc.onmessage = function (msg) {
    if (state.messagesCallback) {
      state.messagesCallback(msg.data);
    }
  };

  return state;
}
function close(channelState) {
  channelState.bc.close();
  channelState.subFns = [];
}
function postMessage(channelState, messageJson) {
  try {
    channelState.bc.postMessage(messageJson, false);
    return _util__WEBPACK_IMPORTED_MODULE_0__.PROMISE_RESOLVED_VOID;
  } catch (err) {
    return Promise.reject(err);
  }
}
function onMessage(channelState, fn) {
  channelState.messagesCallback = fn;
}
function canBeUsed() {
  /**
   * in the electron-renderer, isNode will be true even if we are in browser-context
   * so we also check if window is undefined
   */
  if (_util__WEBPACK_IMPORTED_MODULE_0__.isNode && typeof window === 'undefined') return false;

  if (typeof BroadcastChannel === 'function') {
    if (BroadcastChannel._pubkey) {
      throw new Error('BroadcastChannel: Do not overwrite window.BroadcastChannel with this module, this is not a polyfill');
    }

    return true;
  } else return false;
}
function averageResponseTime() {
  return 150;
}
/* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = ({
  create: create,
  close: close,
  onMessage: onMessage,
  postMessage: postMessage,
  canBeUsed: canBeUsed,
  type: type,
  averageResponseTime: averageResponseTime,
  microSeconds: microSeconds
});

/***/ }),

/***/ "./node_modules/broadcast-channel/dist/esbrowser/methods/simulate.js":
/*!***************************************************************************!*\
  !*** ./node_modules/broadcast-channel/dist/esbrowser/methods/simulate.js ***!
  \***************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "microSeconds": () => (/* binding */ microSeconds),
/* harmony export */   "type": () => (/* binding */ type),
/* harmony export */   "create": () => (/* binding */ create),
/* harmony export */   "close": () => (/* binding */ close),
/* harmony export */   "postMessage": () => (/* binding */ postMessage),
/* harmony export */   "onMessage": () => (/* binding */ onMessage),
/* harmony export */   "canBeUsed": () => (/* binding */ canBeUsed),
/* harmony export */   "averageResponseTime": () => (/* binding */ averageResponseTime),
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var _util__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ../util */ "./node_modules/broadcast-channel/dist/esbrowser/util.js");

var microSeconds = _util__WEBPACK_IMPORTED_MODULE_0__.microSeconds;
var type = 'simulate';
var SIMULATE_CHANNELS = new Set();
function create(channelName) {
  var state = {
    name: channelName,
    messagesCallback: null
  };
  SIMULATE_CHANNELS.add(state);
  return state;
}
function close(channelState) {
  SIMULATE_CHANNELS["delete"](channelState);
}
function postMessage(channelState, messageJson) {
  return new Promise(function (res) {
    return setTimeout(function () {
      var channelArray = Array.from(SIMULATE_CHANNELS);
      channelArray.filter(function (channel) {
        return channel.name === channelState.name;
      }).filter(function (channel) {
        return channel !== channelState;
      }).filter(function (channel) {
        return !!channel.messagesCallback;
      }).forEach(function (channel) {
        return channel.messagesCallback(messageJson);
      });
      res();
    }, 5);
  });
}
function onMessage(channelState, fn) {
  channelState.messagesCallback = fn;
}
function canBeUsed() {
  return true;
}
function averageResponseTime() {
  return 5;
}
/* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = ({
  create: create,
  close: close,
  onMessage: onMessage,
  postMessage: postMessage,
  canBeUsed: canBeUsed,
  type: type,
  averageResponseTime: averageResponseTime,
  microSeconds: microSeconds
});

/***/ }),

/***/ "./node_modules/broadcast-channel/dist/esbrowser/options.js":
/*!******************************************************************!*\
  !*** ./node_modules/broadcast-channel/dist/esbrowser/options.js ***!
  \******************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "fillOptionsWithDefaults": () => (/* binding */ fillOptionsWithDefaults)
/* harmony export */ });
function fillOptionsWithDefaults() {
  var originalOptions = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};
  var options = JSON.parse(JSON.stringify(originalOptions)); // main

  if (typeof options.webWorkerSupport === 'undefined') options.webWorkerSupport = true; // indexed-db

  if (!options.idb) options.idb = {}; //  after this time the messages get deleted

  if (!options.idb.ttl) options.idb.ttl = 1000 * 45;
  if (!options.idb.fallbackInterval) options.idb.fallbackInterval = 150; //  handles abrupt db onclose events.

  if (originalOptions.idb && typeof originalOptions.idb.onclose === 'function') options.idb.onclose = originalOptions.idb.onclose; // localstorage

  if (!options.localstorage) options.localstorage = {};
  if (!options.localstorage.removeTimeout) options.localstorage.removeTimeout = 1000 * 60; // custom methods

  if (originalOptions.methods) options.methods = originalOptions.methods; // node

  if (!options.node) options.node = {};
  if (!options.node.ttl) options.node.ttl = 1000 * 60 * 2; // 2 minutes;

  /**
   * On linux use 'ulimit -Hn' to get the limit of open files.
   * On ubuntu this was 4096 for me, so we use half of that as maxParallelWrites default.
   */

  if (!options.node.maxParallelWrites) options.node.maxParallelWrites = 2048;
  if (typeof options.node.useFastPath === 'undefined') options.node.useFastPath = true;
  return options;
}

/***/ }),

/***/ "./node_modules/broadcast-channel/dist/esbrowser/util.js":
/*!***************************************************************!*\
  !*** ./node_modules/broadcast-channel/dist/esbrowser/util.js ***!
  \***************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "isPromise": () => (/* binding */ isPromise),
/* harmony export */   "PROMISE_RESOLVED_FALSE": () => (/* binding */ PROMISE_RESOLVED_FALSE),
/* harmony export */   "PROMISE_RESOLVED_TRUE": () => (/* binding */ PROMISE_RESOLVED_TRUE),
/* harmony export */   "PROMISE_RESOLVED_VOID": () => (/* binding */ PROMISE_RESOLVED_VOID),
/* harmony export */   "sleep": () => (/* binding */ sleep),
/* harmony export */   "randomInt": () => (/* binding */ randomInt),
/* harmony export */   "randomToken": () => (/* binding */ randomToken),
/* harmony export */   "microSeconds": () => (/* binding */ microSeconds),
/* harmony export */   "isNode": () => (/* binding */ isNode)
/* harmony export */ });
/**
 * returns true if the given object is a promise
 */
function isPromise(obj) {
  if (obj && typeof obj.then === 'function') {
    return true;
  } else {
    return false;
  }
}
var PROMISE_RESOLVED_FALSE = Promise.resolve(false);
var PROMISE_RESOLVED_TRUE = Promise.resolve(true);
var PROMISE_RESOLVED_VOID = Promise.resolve();
function sleep(time, resolveWith) {
  if (!time) time = 0;
  return new Promise(function (res) {
    return setTimeout(function () {
      return res(resolveWith);
    }, time);
  });
}
function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1) + min);
}
/**
 * https://stackoverflow.com/a/8084248
 */

function randomToken() {
  return Math.random().toString(36).substring(2);
}
var lastMs = 0;
var additional = 0;
/**
 * returns the current time in micro-seconds,
 * WARNING: This is a pseudo-function
 * Performance.now is not reliable in webworkers, so we just make sure to never return the same time.
 * This is enough in browsers, and this function will not be used in nodejs.
 * The main reason for this hack is to ensure that BroadcastChannel behaves equal to production when it is used in fast-running unit tests.
 */

function microSeconds() {
  var ms = new Date().getTime();

  if (ms === lastMs) {
    additional++;
    return ms * 1000 + additional;
  } else {
    lastMs = ms;
    additional = 0;
    return ms * 1000;
  }
}
/**
 * copied from the 'detect-node' npm module
 * We cannot use the module directly because it causes problems with rollup
 * @link https://github.com/iliakan/detect-node/blob/master/index.js
 */

var isNode = Object.prototype.toString.call(typeof process !== 'undefined' ? process : 0) === '[object process]';

/***/ }),

/***/ "./node_modules/fast-deep-equal/index.js":
/*!***********************************************!*\
  !*** ./node_modules/fast-deep-equal/index.js ***!
  \***********************************************/
/***/ ((module) => {



// do not edit .js files directly - edit src/index.jst



module.exports = function equal(a, b) {
  if (a === b) return true;

  if (a && b && typeof a == 'object' && typeof b == 'object') {
    if (a.constructor !== b.constructor) return false;

    var length, i, keys;
    if (Array.isArray(a)) {
      length = a.length;
      if (length != b.length) return false;
      for (i = length; i-- !== 0;)
        if (!equal(a[i], b[i])) return false;
      return true;
    }



    if (a.constructor === RegExp) return a.source === b.source && a.flags === b.flags;
    if (a.valueOf !== Object.prototype.valueOf) return a.valueOf() === b.valueOf();
    if (a.toString !== Object.prototype.toString) return a.toString() === b.toString();

    keys = Object.keys(a);
    length = keys.length;
    if (length !== Object.keys(b).length) return false;

    for (i = length; i-- !== 0;)
      if (!Object.prototype.hasOwnProperty.call(b, keys[i])) return false;

    for (i = length; i-- !== 0;) {
      var key = keys[i];

      if (!equal(a[key], b[key])) return false;
    }

    return true;
  }

  // true if both NaN, false otherwise
  return a!==a && b!==b;
};


/***/ }),

/***/ "./node_modules/oblivious-set/dist/es/index.js":
/*!*****************************************************!*\
  !*** ./node_modules/oblivious-set/dist/es/index.js ***!
  \*****************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "ObliviousSet": () => (/* binding */ ObliviousSet),
/* harmony export */   "removeTooOldValues": () => (/* binding */ removeTooOldValues),
/* harmony export */   "now": () => (/* binding */ now)
/* harmony export */ });
/**
 * this is a set which automatically forgets
 * a given entry when a new entry is set and the ttl
 * of the old one is over
 */
var ObliviousSet = /** @class */ (function () {
    function ObliviousSet(ttl) {
        this.ttl = ttl;
        this.set = new Set();
        this.timeMap = new Map();
    }
    ObliviousSet.prototype.has = function (value) {
        return this.set.has(value);
    };
    ObliviousSet.prototype.add = function (value) {
        var _this = this;
        this.timeMap.set(value, now());
        this.set.add(value);
        /**
         * When a new value is added,
         * start the cleanup at the next tick
         * to not block the cpu for more important stuff
         * that might happen.
         */
        setTimeout(function () {
            removeTooOldValues(_this);
        }, 0);
    };
    ObliviousSet.prototype.clear = function () {
        this.set.clear();
        this.timeMap.clear();
    };
    return ObliviousSet;
}());

/**
 * Removes all entries from the set
 * where the TTL has expired
 */
function removeTooOldValues(obliviousSet) {
    var olderThen = now() - obliviousSet.ttl;
    var iterator = obliviousSet.set[Symbol.iterator]();
    /**
     * Because we can assume the new values are added at the bottom,
     * we start from the top and stop as soon as we reach a non-too-old value.
     */
    while (true) {
        var value = iterator.next().value;
        if (!value) {
            return; // no more elements
        }
        var time = obliviousSet.timeMap.get(value);
        if (time < olderThen) {
            obliviousSet.timeMap.delete(value);
            obliviousSet.set.delete(value);
        }
        else {
            // We reached a value that is not old enough
            return;
        }
    }
}
function now() {
    return new Date().getTime();
}
//# sourceMappingURL=index.js.map

/***/ }),

/***/ "./src/bulk-delete.ts":
/*!****************************!*\
  !*** ./src/bulk-delete.ts ***!
  \****************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "bulkDelete": () => (/* binding */ bulkDelete),
/* harmony export */   "bulkDeleteByIndex": () => (/* binding */ bulkDeleteByIndex)
/* harmony export */ });
function bulkDelete(txn, storeName, keys) {
    return new Promise((resolve, reject) => {
        const len = keys.length;
        const lastItem = len - 1;
        if (len === 0)
            return resolve();
        const store = txn.txn.objectStore(storeName);
        for (let i = 0; i < keys.length; i++) {
            const req = store.delete(keys[i]);
            req.onerror = () => {
                txn.abort();
                reject(req.error);
            };
            if (i === lastItem) {
                req.onsuccess = () => {
                    resolve();
                };
            }
        }
    });
}
function bulkDeleteByIndex(txn, storeName, indexName, keys) {
    if (keys.length === 0)
        return Promise.resolve([]);
    return new Promise((resolve, reject) => {
        const store = txn.txn.objectStore(storeName);
        const index = store.index(indexName);
        const primaryKeys = [];
        for (var i = 0; i < keys.length; i++) {
            const indexReq = index.getAllKeys(keys[i]);
            const isLast = i === keys.length - 1;
            indexReq.onsuccess = () => {
                primaryKeys.push(...indexReq.result);
                if (isLast) {
                    bulkDelete(txn, storeName, primaryKeys).then(() => resolve(primaryKeys), reject);
                }
            };
            indexReq.onerror = () => {
                txn.abort();
                reject(indexReq.error);
            };
        }
    });
}


/***/ }),

/***/ "./src/collection.ts":
/*!***************************!*\
  !*** ./src/collection.ts ***!
  \***************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "IsarCollection": () => (/* binding */ IsarCollection)
/* harmony export */ });
/* harmony import */ var _bulk_delete__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./bulk-delete */ "./src/bulk-delete.ts");
/* harmony import */ var _helper__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./helper */ "./src/helper.ts");
/* harmony import */ var _link__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ./link */ "./src/link.ts");
/* harmony import */ var _schema__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(/*! ./schema */ "./src/schema.ts");
/* harmony import */ var _watcher__WEBPACK_IMPORTED_MODULE_4__ = __webpack_require__(/*! ./watcher */ "./src/watcher.ts");





class IsarCollection extends _watcher__WEBPACK_IMPORTED_MODULE_4__.IsarWatchable {
    constructor(isar, schema, backlinkStoreNames) {
        super();
        this.indexKeyPaths = new Map();
        this.isar = isar;
        this.name = schema.name;
        this.idName = schema.idName;
        this.boolValues = schema.properties
            .filter(p => p.type == _schema__WEBPACK_IMPORTED_MODULE_3__.IsarType.Bool || p.type == _schema__WEBPACK_IMPORTED_MODULE_3__.IsarType.BoolList)
            .map(p => p.name);
        this.uniqueIndexes = schema.indexes
            .filter(i => i.unique)
            .map(i => ({
            name: i.name,
            accessors: i.properties.map(p => p.name),
        }));
        this.links = schema.links.map(l => new _link__WEBPACK_IMPORTED_MODULE_2__.IsarLink(isar, l.name, schema.name, l.target));
        this.backlinkStoreNames = backlinkStoreNames;
        this.multiEntryIndexes = schema.indexes
            .filter(i => _schema__WEBPACK_IMPORTED_MODULE_3__.IndexSchema.isIndexMultiEntry(schema, i))
            .map(i => i.name);
        this.indexKeyPaths = new Map(schema.indexes.map(i => [i.name, i.properties.map(p => p.name)]));
    }
    getLink(name) {
        return this.links.find(l => l.name === name);
    }
    toObject(obj) {
        return (0,_helper__WEBPACK_IMPORTED_MODULE_1__.idb2Obj)(obj, this.boolValues);
    }
    getId(obj) {
        return obj[this.idName];
    }
    getIndexKeyPath(indexName) {
        return this.indexKeyPaths.get(indexName);
    }
    isMultiEntryIndex(indexName) {
        return this.multiEntryIndexes.includes(indexName);
    }
    prepareKey(key) {
        if (Array.isArray(key)) {
            if (key.length == 1) {
                return (0,_helper__WEBPACK_IMPORTED_MODULE_1__.val2Idb)(key[0]);
            }
            else {
                return key.map(_helper__WEBPACK_IMPORTED_MODULE_1__.val2Idb);
            }
        }
        else {
            return (0,_helper__WEBPACK_IMPORTED_MODULE_1__.val2Idb)(key);
        }
    }
    get(txn, key) {
        let store = txn.txn.objectStore(this.name);
        return new Promise((resolve, reject) => {
            let req = store.get(key);
            req.onsuccess = () => {
                const object = req.result ? this.toObject(req.result) : undefined;
                resolve(object);
            };
            req.onerror = () => {
                reject(req.error);
            };
        });
    }
    getAllInternal(txn, keys, includeUndefined, indexName) {
        return new Promise((resolve, reject) => {
            const store = txn.txn.objectStore(this.name);
            const source = indexName ? store.index(indexName) : store;
            const results = [];
            for (let i = 0; i < keys.length; i++) {
                let req = source.get(keys[i]);
                req.onsuccess = () => {
                    const result = req.result;
                    if (result) {
                        results.push(this.toObject(result));
                    }
                    else if (includeUndefined) {
                        results.push(undefined);
                    }
                    if (results.length == keys.length) {
                        resolve(results);
                    }
                };
                req.onerror = () => {
                    reject(req.error);
                };
            }
        });
    }
    getAll(txn, ids) {
        return this.getAllInternal(txn, ids, true);
    }
    getAllByIndex(txn, indexName, keys) {
        const idbKeys = keys.map(this.prepareKey);
        return this.getAllInternal(txn, idbKeys, true, indexName);
    }
    putAll(txn, objects) {
        let store = txn.txn.objectStore(this.name);
        return new Promise((resolve, reject) => {
            const ids = [];
            const changeSet = txn.getChangeSet(this.name);
            for (let i = 0; i < objects.length; i++) {
                let object = (0,_helper__WEBPACK_IMPORTED_MODULE_1__.obj2Idb)(objects[i], this.idName);
                const req = store.put(object);
                const id = this.getId(object);
                ids.push(id);
                if (!id) {
                    req.onsuccess = () => {
                        const id = req.result;
                        ids[i] = id;
                        changeSet.registerChange(id, object);
                        if (i === objects.length - 1) {
                            resolve(ids);
                        }
                    };
                }
                else {
                    changeSet.registerChange(id, object);
                    if (i === objects.length - 1) {
                        req.onsuccess = () => {
                            resolve(ids);
                        };
                    }
                }
                req.onerror = () => {
                    txn.abort();
                    reject(req.error);
                };
            }
        });
    }
    deleteLinks(txn, keys) {
        if (this.links.length === 0 && this.backlinkStoreNames.length === 0) {
            return Promise.resolve();
        }
        const linkPromises = this.links.map(l => {
            return (0,_bulk_delete__WEBPACK_IMPORTED_MODULE_0__.bulkDelete)(txn, l.storeName, keys.map(_link__WEBPACK_IMPORTED_MODULE_2__.IsarLink.getLinkKeyRange));
        });
        const backlinkPromises = this.backlinkStoreNames.map(storeName => {
            return (0,_bulk_delete__WEBPACK_IMPORTED_MODULE_0__.bulkDeleteByIndex)(txn, storeName, _link__WEBPACK_IMPORTED_MODULE_2__.IsarLink.BacklinkIndex, keys);
        });
        return Promise.all([...linkPromises, ...backlinkPromises]).then(() => { });
    }
    deleteAll(txn, ids) {
        return (0,_bulk_delete__WEBPACK_IMPORTED_MODULE_0__.bulkDelete)(txn, this.name, ids).then(() => {
            const changeSet = txn.getChangeSet(this.name);
            for (let id of ids) {
                changeSet.registerChange(id);
            }
            return this.deleteLinks(txn, ids);
        });
    }
    deleteAllByIndex(txn, indexName, keys) {
        const idbKeys = keys.map(this.prepareKey);
        return (0,_bulk_delete__WEBPACK_IMPORTED_MODULE_0__.bulkDeleteByIndex)(txn, this.name, indexName, idbKeys).then(ids => {
            const changeSet = txn.getChangeSet(this.name);
            for (let id of ids) {
                changeSet.registerChange(id);
            }
            return this.deleteLinks(txn, ids).then(() => ids.length);
        });
    }
    clear(txn) {
        return new Promise((resolve, reject) => {
            const storeNames = [
                this.name,
                ...this.backlinkStoreNames,
                ...this.links.map(l => l.storeName),
            ];
            for (let i = 0; i < storeNames.length; i++) {
                const store = txn.txn.objectStore(this.name);
                const req = store.clear();
                req.onerror = () => {
                    reject(req.error);
                };
                if (i === storeNames.length - 1) {
                    req.onsuccess = () => {
                        txn.getChangeSet(this.name).registerCleared();
                        resolve();
                    };
                }
            }
        });
    }
}


/***/ }),

/***/ "./src/cursor.ts":
/*!***********************!*\
  !*** ./src/cursor.ts ***!
  \***********************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "useCursor": () => (/* binding */ useCursor)
/* harmony export */ });
function useCursor(params) {
    return new Promise((resolve, reject) => {
        const store = params.txn.txn.objectStore(params.storeName);
        const source = params.indexName != null ? store.index(params.indexName) : store;
        const multiEntry = params.indexName && source.multiEntry;
        const cursorReq = source.openCursor(params.range, params.direction);
        cursorReq.onsuccess = () => {
            const cursor = cursorReq.result;
            if (cursor) {
                if (params.offset) {
                    cursor.advance(params.offset);
                    params.offset = undefined;
                }
                else {
                    if (multiEntry) {
                        const isArray = Array.isArray(cursor.value[source.keyPath]);
                        if (!isArray) {
                            cursor.continue();
                            return;
                        }
                    }
                    params.callback(cursor.primaryKey, cursor.value, function () {
                        cursor.continue();
                    }, resolve, reject);
                }
            }
            else {
                resolve();
            }
        };
        cursorReq.onerror = e => {
            reject(e);
        };
    });
}


/***/ }),

/***/ "./src/helper.ts":
/*!***********************!*\
  !*** ./src/helper.ts ***!
  \***********************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "val2Idb": () => (/* binding */ val2Idb),
/* harmony export */   "obj2Idb": () => (/* binding */ obj2Idb),
/* harmony export */   "idb2Obj": () => (/* binding */ idb2Obj)
/* harmony export */ });
function val2Idb(value) {
    if (value == null || value != value) {
        return -Infinity;
    }
    else if (value === true) {
        return 1;
    }
    else if (value === false) {
        return 0;
    }
    else {
        return value;
    }
}
function obj2Idb(object, idName) {
    const result = Object.create(null, {});
    for (let key of Object.keys(object)) {
        const val = object[key];
        if (Array.isArray(val)) {
            result[key] = val.map(val2Idb);
        }
        else if (key !== idName || (val != null && val !== -Infinity)) {
            result[key] = val2Idb(val);
        }
    }
    return result;
}
function idb2Obj(object, boolValues) {
    const result = {};
    for (let key of Object.keys(object)) {
        const val = object[key];
        if (val === -Infinity) {
            result[key] = null;
        }
        else if (boolValues.indexOf(key) !== -1) {
            if (Array.isArray(val)) {
                result[key] = val.map(v => (v === -Infinity ? null : v > 0));
            }
            else {
                result[key] = val === 1;
            }
        }
        else if (Array.isArray(val)) {
            result[key] = val.map(v => (v === -Infinity ? null : v));
        }
        else {
            result[key] = val;
        }
    }
    return result;
}
// Polyfill for older browsers
if (typeof IDBTransaction.prototype.commit !== "function") {
    IDBTransaction.prototype.commit = function () { };
}


/***/ }),

/***/ "./src/instance.ts":
/*!*************************!*\
  !*** ./src/instance.ts ***!
  \*************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "IsarInstance": () => (/* binding */ IsarInstance)
/* harmony export */ });
/* harmony import */ var _collection__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./collection */ "./src/collection.ts");
/* harmony import */ var _schema__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./schema */ "./src/schema.ts");
/* harmony import */ var _txn__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ./txn */ "./src/txn.ts");
/* harmony import */ var broadcast_channel__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(/*! broadcast-channel */ "./node_modules/broadcast-channel/dist/esbrowser/broadcast-channel.js");




class IsarInstance {
    constructor(db, relaxedDurability, schemas) {
        this.collections = new Map();
        this.db = db;
        this.relaxedDurability = relaxedDurability;
        this.initializeCollections(schemas);
        this.eventHandler = (event) => {
            if (event.data &&
                event.data.type === 'change' &&
                event.data.instance == this.db.name) {
                this.notifyWatchers(event.data.changes, true);
            }
        };
        IsarInstance.bc.addEventListener('message', this.eventHandler);
    }
    initializeCollections(schemas) {
        for (let schema of schemas) {
            const backlinkStoreNames = schemas.flatMap(s => {
                if (s.name === schema.name) {
                    return [];
                }
                return s.links
                    .filter(l => l.target === schema.name)
                    .map(l => {
                    return _schema__WEBPACK_IMPORTED_MODULE_1__.LinkSchema.getStoreName(s.name, l.target, l.name);
                });
            });
            const col = new _collection__WEBPACK_IMPORTED_MODULE_0__.IsarCollection(this, schema, backlinkStoreNames);
            this.collections.set(schema.name, col);
        }
    }
    notifyWatchers(changes, external = false) {
        let txn;
        const getTxn = () => {
            if (txn == null) {
                txn = this.beginTxn(false);
            }
            return txn;
        };
        for (let [colName, changeSet] of changes.entries()) {
            const collection = this.getCollection(colName);
            collection.notify(changeSet, getTxn);
        }
        if (!external) {
            const event = {
                type: 'change',
                instance: this.db.name,
                changes,
            };
            IsarInstance.bc.postMessage(event);
        }
    }
    beginTxn(write) {
        const names = this.db.objectStoreNames;
        const mode = write ? 'readwrite' : 'readonly';
        const options = this.relaxedDurability ? { durability: 'relaxed' } : {};
        const txn = this.db.transaction(names, mode, options);
        return new _txn__WEBPACK_IMPORTED_MODULE_2__.IsarTxn(this, txn, write);
    }
    getCollection(name) {
        return this.collections.get(name);
    }
    close(deleteFromDisk = false) {
        IsarInstance.bc.removeEventListener('message', this.eventHandler);
        this.db.close();
        if (deleteFromDisk) {
            const req = indexedDB.deleteDatabase(this.db.name);
            return new Promise((resolve, reject) => {
                req.onsuccess = () => {
                    resolve();
                };
                req.onerror = () => {
                    reject(req.error);
                };
            });
        }
        else {
            return Promise.resolve();
        }
    }
}
IsarInstance.bc = new broadcast_channel__WEBPACK_IMPORTED_MODULE_3__.BroadcastChannel('ISAR_CHANNEL');


/***/ }),

/***/ "./src/link.ts":
/*!*********************!*\
  !*** ./src/link.ts ***!
  \*********************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "IsarLink": () => (/* binding */ IsarLink)
/* harmony export */ });
/* harmony import */ var _bulk_delete__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./bulk-delete */ "./src/bulk-delete.ts");
/* harmony import */ var _schema__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./schema */ "./src/schema.ts");


class IsarLink {
    constructor(isar, name, sourceName, targetName) {
        this.isar = isar;
        this.name = name;
        this.sourceName = sourceName;
        this.targetName = targetName;
        this.storeName = _schema__WEBPACK_IMPORTED_MODULE_1__.LinkSchema.getStoreName(sourceName, targetName, name);
    }
    getLinkEntry(source, target, backlink) {
        if (backlink) {
            ;
            [source, target] = [target, source];
        }
        return {
            a: source,
            b: target,
        };
    }
    static getLinkKeyRange(id) {
        return IDBKeyRange.bound([id, -Infinity], [id, Infinity]);
    }
    update(txn, backlink, id, addedTargets, deletedTargets) {
        if (addedTargets.length === 0 && deletedTargets.length === 0) {
            return Promise.resolve();
        }
        return new Promise((resolve, reject) => {
            const store = txn.txn.objectStore(this.storeName);
            const deletedEmpty = deletedTargets.length === 0;
            for (let i = 0; i < addedTargets.length; i++) {
                let target = addedTargets[i];
                const req = store.add(this.getLinkEntry(id, target, backlink));
                if (deletedEmpty && i === addedTargets.length - 1) {
                    req.onsuccess = () => {
                        resolve();
                    };
                }
                req.onerror = () => {
                    txn.abort();
                    reject(req.error);
                };
            }
            for (let i = 0; i < deletedTargets.length; i++) {
                let target = deletedTargets[i];
                const key = backlink ? [target, id] : [id, target];
                const req = store.delete(key);
                if (i === deletedTargets.length - 1) {
                    req.onsuccess = () => {
                        resolve();
                    };
                }
                req.onerror = () => {
                    txn.abort();
                    reject(req.error);
                };
            }
        });
    }
    clear(txn, id, backlink) {
        return new Promise((resolve, reject) => {
            const store = txn.txn.objectStore(this.storeName);
            if (backlink) {
                const keysRes = store.index(IsarLink.BacklinkIndex).getAllKeys(id);
                keysRes.onsuccess = () => {
                    const keys = keysRes.result;
                    if (keys.length > 0) {
                        const ids = keys.map(key => key[1]);
                        (0,_bulk_delete__WEBPACK_IMPORTED_MODULE_0__.bulkDelete)(txn, this.storeName, ids).then(resolve, reject);
                    }
                    else {
                        resolve();
                    }
                };
                keysRes.onerror = () => {
                    txn.abort();
                    reject(keysRes.error);
                };
            }
            else {
                const deleteReq = store.delete(IsarLink.getLinkKeyRange(id));
                deleteReq.onsuccess = () => {
                    resolve();
                };
                deleteReq.onerror = () => {
                    txn.abort();
                    reject(deleteReq.error);
                };
            }
        });
    }
}
IsarLink.BacklinkIndex = 'backlink';


/***/ }),

/***/ "./src/open.ts":
/*!*********************!*\
  !*** ./src/open.ts ***!
  \*********************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "openIsar": () => (/* binding */ openIsar)
/* harmony export */ });
/* harmony import */ var fast_deep_equal__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! fast-deep-equal */ "./node_modules/fast-deep-equal/index.js");
/* harmony import */ var fast_deep_equal__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(fast_deep_equal__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var _instance__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./instance */ "./src/instance.ts");
/* harmony import */ var _link__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ./link */ "./src/link.ts");
/* harmony import */ var _schema__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(/*! ./schema */ "./src/schema.ts");




function openIsar(name, schemas, relaxedDurability) {
    return openInternal(name, schemas, relaxedDurability);
}
function openInternal(name, schemas, relaxedDurability, version) {
    return new Promise((resolve, reject) => {
        const req = indexedDB.open(name, version);
        req.onsuccess = () => {
            const db = req.result;
            if (version == null) {
                const txn = db.transaction(db.objectStoreNames, 'readonly');
                if (!performUpgrade(txn, true, schemas)) {
                    const newVersion = txn.db.version + 1;
                    db.close();
                    resolve(openInternal(name, schemas, relaxedDurability, newVersion));
                    return;
                }
            }
            const instance = new _instance__WEBPACK_IMPORTED_MODULE_1__.IsarInstance(db, relaxedDurability, schemas);
            resolve(instance);
        };
        req.onupgradeneeded = () => {
            performUpgrade(req.transaction, false, schemas);
        };
        req.onerror = () => {
            reject(req.error);
        };
    });
}
function performUpgrade(txn, dryRun, schemas) {
    const schemaStoreNames = [];
    for (let schema of schemas) {
        schemaStoreNames.push(schema.name);
        const schemaIndexNames = [];
        let store;
        if (!txn.objectStoreNames.contains(schema.name)) {
            if (dryRun) {
                return false;
            }
            store = txn.db.createObjectStore(schema.name, {
                keyPath: schema.idName,
                autoIncrement: true,
            });
        }
        else {
            store = txn.objectStore(schema.name);
        }
        for (let indexSchema of schema.indexes) {
            schemaIndexNames.push(indexSchema.name);
            if (store.indexNames.contains(indexSchema.name)) {
                const index = store.index(indexSchema.name);
                if (_schema__WEBPACK_IMPORTED_MODULE_3__.IndexSchema.matchesIndex(schema, indexSchema, index)) {
                    continue;
                }
                else {
                    if (!dryRun) {
                        store.deleteIndex(indexSchema.name);
                    }
                }
            }
            if (dryRun) {
                return false;
            }
            store.createIndex(indexSchema.name, _schema__WEBPACK_IMPORTED_MODULE_3__.IndexSchema.getKeyPath(indexSchema), {
                unique: indexSchema.unique,
                multiEntry: _schema__WEBPACK_IMPORTED_MODULE_3__.IndexSchema.isIndexMultiEntry(schema, indexSchema),
            });
        }
        for (let linkSchema of schema.links) {
            const name = _schema__WEBPACK_IMPORTED_MODULE_3__.LinkSchema.getStoreName(schema.name, linkSchema.target, linkSchema.name);
            let linkStore;
            if (!txn.objectStoreNames.contains(name)) {
                if (dryRun) {
                    return false;
                }
                linkStore = txn.db.createObjectStore(name, {
                    keyPath: ['a', 'b'],
                    autoIncrement: false,
                });
            }
            else {
                linkStore = txn.objectStore(name);
            }
            schemaStoreNames.push(name);
            const indexesOk = fast_deep_equal__WEBPACK_IMPORTED_MODULE_0___default()([...linkStore.indexNames], [_link__WEBPACK_IMPORTED_MODULE_2__.IsarLink.BacklinkIndex]);
            if (!indexesOk) {
                if (dryRun) {
                    return false;
                }
                for (let indexName of linkStore.indexNames) {
                    linkStore.deleteIndex(indexName);
                }
                linkStore.createIndex(_link__WEBPACK_IMPORTED_MODULE_2__.IsarLink.BacklinkIndex, 'b');
            }
        }
        for (let indexName of store.indexNames) {
            if (schemaIndexNames.indexOf(indexName) === -1) {
                if (dryRun) {
                    return false;
                }
                store.deleteIndex(indexName);
            }
        }
    }
    for (let storeName of txn.objectStoreNames) {
        if (schemaStoreNames.indexOf(storeName) === -1) {
            if (dryRun) {
                return false;
            }
            txn.db.deleteObjectStore(storeName);
        }
    }
    return true;
}


/***/ }),

/***/ "./src/query.ts":
/*!**********************!*\
  !*** ./src/query.ts ***!
  \**********************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "IsarQuery": () => (/* binding */ IsarQuery)
/* harmony export */ });
/* harmony import */ var _cursor__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./cursor */ "./src/cursor.ts");
/* harmony import */ var _link__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./link */ "./src/link.ts");


class IsarQuery {
    constructor(collection, whereClauses, whereDistinct, whereAscending, filter, sortCmp, distinctValue, offset, limit) {
        this.collection = collection;
        this.whereClauses = whereClauses;
        this.filter = filter;
        this.sortCmp = sortCmp;
        this.distinctValue = distinctValue;
        this.offset = offset !== null && offset !== void 0 ? offset : 0;
        this.limit = limit !== null && limit !== void 0 ? limit : Infinity;
        if (whereDistinct) {
            this.whereClauseDirection = whereAscending ? 'nextunique' : 'prevunique';
        }
        else {
            this.whereClauseDirection = whereAscending ? 'next' : 'prev';
        }
        if (this.whereClauses.length === 0) {
            this.whereClauses.push({});
        }
    }
    getWhereClauseRange(whereClause) {
        var _a;
        return (_a = whereClause.range) !== null && _a !== void 0 ? _a : IDBKeyRange.lowerBound(-Infinity);
    }
    async findInternal(txn, limit) {
        const offset = this.offset;
        const unsortedLimit = !this.sortCmp ? offset + limit : Infinity;
        const unsortedDistinct = !this.sortCmp ? this.distinctValue : undefined;
        let results = [];
        const idsSet = new Set();
        const distinctSet = new Set();
        const cursorCallback = (id, object, next, resolve) => {
            if (idsSet.has(id)) {
                next();
                return;
            }
            else {
                idsSet.add(id);
            }
            if (this.filter) {
                if (!this.filter(id, object)) {
                    next();
                    return;
                }
            }
            if (unsortedDistinct) {
                const value = unsortedDistinct(object);
                if (distinctSet.has(value)) {
                    next();
                    return;
                }
                else {
                    distinctSet.add(value);
                }
            }
            results.push(object);
            if (results.length < unsortedLimit) {
                next();
            }
            else {
                resolve();
            }
        };
        for (const whereClause of this.whereClauses) {
            if (results.length >= unsortedLimit) {
                break;
            }
            if ('linkName' in whereClause) {
                const link = this.collection.isar
                    .getCollection(whereClause.linkCollection)
                    .getLink(whereClause.linkName);
                await (0,_cursor__WEBPACK_IMPORTED_MODULE_0__.useCursor)({
                    txn,
                    storeName: link.storeName,
                    indexName: whereClause.backlink ? _link__WEBPACK_IMPORTED_MODULE_1__.IsarLink.BacklinkIndex : undefined,
                    range: _link__WEBPACK_IMPORTED_MODULE_1__.IsarLink.getLinkKeyRange(whereClause.id),
                    direction: this.whereClauseDirection,
                    callback: (key, _, next, resolve, reject) => {
                        const id = key[whereClause.backlink ? 0 : 1];
                        this.collection
                            .get(txn, id)
                            .then(obj => {
                            if (obj) {
                                cursorCallback(id, obj, next, resolve);
                            }
                            else {
                                next();
                            }
                        })
                            .catch(() => reject());
                    },
                });
            }
            else {
                const range = this.getWhereClauseRange(whereClause);
                await (0,_cursor__WEBPACK_IMPORTED_MODULE_0__.useCursor)({
                    txn,
                    storeName: this.collection.name,
                    indexName: 'indexName' in whereClause ? whereClause.indexName : undefined,
                    range: range,
                    direction: this.whereClauseDirection,
                    callback: cursorCallback,
                });
            }
        }
        if (this.sortCmp) {
            results.sort(this.sortCmp);
            const distinctValue = this.distinctValue;
            if (distinctValue) {
                results = results.filter(obj => {
                    const value = distinctValue(obj);
                    if (!distinctSet.has(value)) {
                        distinctSet.add(value);
                        return true;
                    }
                    else {
                        return false;
                    }
                });
            }
        }
        return results.slice(offset, offset + limit);
    }
    findFirst(txn) {
        return this.findInternal(txn, 1).then(results => {
            return results.length > 0
                ? this.collection.toObject(results[0])
                : undefined;
        });
    }
    findAll(txn) {
        var _a;
        return this.findInternal(txn, (_a = this.limit) !== null && _a !== void 0 ? _a : Infinity).then(results => {
            return results.map(o => this.collection.toObject(o));
        });
    }
    deleteFirst(txn) {
        return this.findInternal(txn, 1).then(result => {
            if (result.length !== 0) {
                return this.collection
                    .deleteAll(txn, [this.collection.getId(result[0])])
                    .then(() => true);
            }
            else {
                return false;
            }
        });
    }
    deleteAll(txn) {
        return this.findInternal(txn, this.limit).then(result => {
            return this.collection
                .deleteAll(txn, result.map(this.collection.getId))
                .then(() => result.length);
        });
    }
    min(txn, key) {
        return this.findAll(txn).then(results => {
            let min = undefined;
            for (const obj of results) {
                const value = obj[key];
                if (value != null && (min == null || value < min)) {
                    min = value;
                }
            }
            return min;
        });
    }
    max(txn, key) {
        return this.findAll(txn).then(results => {
            let max = undefined;
            for (const obj of results) {
                const value = obj[key];
                if (value != null && (max == null || value > max)) {
                    max = value;
                }
            }
            return max;
        });
    }
    sum(txn, key) {
        return this.findAll(txn).then(results => {
            let sum = 0;
            for (const obj of results) {
                const value = obj[key];
                if (value != null) {
                    sum += value;
                }
            }
            return sum;
        });
    }
    average(txn, key) {
        return this.findAll(txn).then(results => {
            let sum = 0;
            let count = 0;
            for (const obj of results) {
                const value = obj[key];
                if (value != null) {
                    sum += value;
                    count++;
                }
            }
            return sum / count;
        });
    }
    count(txn) {
        return this.findAll(txn).then(result => result.length);
    }
    whereClauseMatches(id, idbObject) {
        for (const whereClause of this.whereClauses) {
            if ('linkName' in whereClause) {
                return true;
            }
            else if ('indexName' in whereClause) {
                if (this.collection.isMultiEntryIndex(whereClause.indexName)) {
                    const values = idbObject[this.collection.getIndexKeyPath(whereClause.indexName)[0]];
                    for (let value of values) {
                        if (this.getWhereClauseRange(whereClause).includes(value)) {
                            return true;
                        }
                    }
                }
                else {
                    let value = this.collection
                        .getIndexKeyPath(whereClause.indexName)
                        .map(p => p === this.collection.idName ? id : idbObject[p]);
                    if (value.length === 1) {
                        value = value[0];
                    }
                    if (this.getWhereClauseRange(whereClause).includes(value)) {
                        return true;
                    }
                }
            }
            else if (this.getWhereClauseRange(whereClause).includes(id)) {
                return true;
            }
        }
        return false;
    }
    whereClauseAndFilterMatch(id, idbObject) {
        if (!this.whereClauseMatches(id, idbObject)) {
            return false;
        }
        if (this.filter) {
            if (!this.filter(id, idbObject)) {
                return false;
            }
        }
        return true;
    }
}


/***/ }),

/***/ "./src/schema.ts":
/*!***********************!*\
  !*** ./src/schema.ts ***!
  \***********************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "IndexSchema": () => (/* binding */ IndexSchema),
/* harmony export */   "LinkSchema": () => (/* binding */ LinkSchema),
/* harmony export */   "IsarType": () => (/* binding */ IsarType)
/* harmony export */ });
/* harmony import */ var fast_deep_equal__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! fast-deep-equal */ "./node_modules/fast-deep-equal/index.js");
/* harmony import */ var fast_deep_equal__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(fast_deep_equal__WEBPACK_IMPORTED_MODULE_0__);

var IndexSchema;
(function (IndexSchema) {
    function isIndexMultiEntry(schema, indexSchema) {
        return indexSchema.properties.some(ip => {
            const property = schema.properties.find(p => p.name === ip.name);
            return ip.type === IndexType.Value && IsarType.isList(property.type);
        });
    }
    IndexSchema.isIndexMultiEntry = isIndexMultiEntry;
    function getKeyPath(indexSchema) {
        return indexSchema.properties.length === 1
            ? indexSchema.properties[0].name
            : indexSchema.properties.map(p => p.name);
    }
    IndexSchema.getKeyPath = getKeyPath;
    function matchesIndex(schema, indexSchema, index) {
        return (index.name === indexSchema.name &&
            index.multiEntry === isIndexMultiEntry(schema, indexSchema) &&
            index.unique === indexSchema.unique &&
            fast_deep_equal__WEBPACK_IMPORTED_MODULE_0___default()(index.keyPath, getKeyPath(indexSchema)));
    }
    IndexSchema.matchesIndex = matchesIndex;
})(IndexSchema || (IndexSchema = {}));
var LinkSchema;
(function (LinkSchema) {
    function getStoreName(sourceName, targetName, linkName) {
        return `_\${sourceName}_\${targetName}_\${linkName}`;
    }
    LinkSchema.getStoreName = getStoreName;
})(LinkSchema || (LinkSchema = {}));
var IsarType;
(function (IsarType) {
    IsarType["Bool"] = "Bool";
    IsarType["Int"] = "Int";
    IsarType["Float"] = "Float";
    IsarType["Long"] = "Long";
    IsarType["Double"] = "Double";
    IsarType["String"] = "String";
    IsarType["ByteList"] = "ByteList";
    IsarType["BoolList"] = "BoolList";
    IsarType["IntList"] = "IntList";
    IsarType["FloatList"] = "FloatList";
    IsarType["LongList"] = "LongList";
    IsarType["DoubleList"] = "DoubleList";
    IsarType["StringList"] = "StringList";
})(IsarType || (IsarType = {}));
(function (IsarType) {
    function isList(type) {
        return [
            IsarType.ByteList,
            IsarType.BoolList,
            IsarType.IntList,
            IsarType.FloatList,
            IsarType.LongList,
            IsarType.DoubleList,
            IsarType.StringList,
        ].includes(type);
    }
    IsarType.isList = isList;
})(IsarType || (IsarType = {}));
var IndexType;
(function (IndexType) {
    IndexType["Value"] = "Value";
    IndexType["Hash"] = "Hash";
    IndexType["HashElements"] = "HashElements";
})(IndexType || (IndexType = {}));


/***/ }),

/***/ "./src/txn.ts":
/*!********************!*\
  !*** ./src/txn.ts ***!
  \********************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "IsarTxn": () => (/* binding */ IsarTxn)
/* harmony export */ });
/* harmony import */ var _watcher__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./watcher */ "./src/watcher.ts");

class IsarTxn {
    constructor(isar, txn, write) {
        this.isar = isar;
        this.txn = txn;
        this.active = true;
        this.write = write;
        if (write) {
            this.changes = new Map();
        }
    }
    getChangeSet(collectionName) {
        let changeSet = this.changes.get(collectionName);
        if (changeSet == null) {
            changeSet = new _watcher__WEBPACK_IMPORTED_MODULE_0__.IsarChangeSet();
            this.changes.set(collectionName, changeSet);
        }
        return changeSet;
    }
    commit() {
        return new Promise((resolve, reject) => {
            this.active = false;
            this.txn.oncomplete = () => {
                if (this.changes) {
                    this.isar.notifyWatchers(this.changes);
                }
                resolve();
            };
            this.txn.onerror = () => {
                reject(this.txn.error);
            };
            this.txn.commit();
        });
    }
    abort() {
        if (this.active) {
            this.active = false;
            this.txn.abort();
        }
    }
}


/***/ }),

/***/ "./src/watcher.ts":
/*!************************!*\
  !*** ./src/watcher.ts ***!
  \************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "IsarChangeSet": () => (/* binding */ IsarChangeSet),
/* harmony export */   "IsarWatchable": () => (/* binding */ IsarWatchable)
/* harmony export */ });
class IsarChangeSet {
    constructor() {
        this.cleared = false;
        this.addedObjects = new Map();
        this.deletedObjectIds = new Set();
    }
    registerChange(id, idbObject) {
        if (idbObject) {
            this.addedObjects.set(id, idbObject);
            this.deletedObjectIds.delete(id);
        }
        else {
            this.deletedObjectIds.add(id);
            this.addedObjects.delete(id);
        }
    }
    registerCleared() {
        this.addedObjects.clear();
        this.deletedObjectIds.clear();
        this.cleared = true;
    }
}
class IsarWatchable {
    constructor() {
        this.collectionWatchers = new Set();
        this.objectWatchers = new Map();
        this.queryWatchers = new Set();
    }
    watchLazy(callback) {
        this.collectionWatchers.add(callback);
        return () => this.collectionWatchers.delete(callback);
    }
    watchObject(id, callback) {
        let ow = this.objectWatchers.get(id);
        if (ow == null) {
            ow = new Set();
            this.objectWatchers.set(id, ow);
        }
        ow.add(callback);
        return () => {
            if (ow.size <= 1) {
                this.objectWatchers.delete(id);
            }
            else {
                ow.delete(callback);
            }
        };
    }
    watchQueryInternal(query, lazy, callback) {
        const watcher = { callback, query, lazy };
        this.queryWatchers.add(watcher);
        return () => this.queryWatchers.delete(watcher);
    }
    watchQuery(query, callback) {
        return this.watchQueryInternal(query, false, callback);
    }
    watchQueryLazy(query, callback) {
        return this.watchQueryInternal(query, true, callback);
    }
    notify(changes, getTxn) {
        if (!changes.cleared &&
            changes.addedObjects.size === 0 &&
            changes.deletedObjectIds.size === 0) {
            return;
        }
        function notifyQuery(watcher) {
            if (watcher.lazy) {
                ;
                watcher.callback();
            }
            else {
                const txn = getTxn();
                watcher.query.findAll(txn).then(watcher.callback);
            }
        }
        for (const watcher of this.collectionWatchers) {
            watcher();
        }
        let queryWatchers;
        if (changes.cleared || changes.deletedObjectIds.size > 0) {
            for (const watcher of this.queryWatchers) {
                notifyQuery(watcher);
            }
        }
        else {
            queryWatchers = new Set(this.queryWatchers);
        }
        if (changes.cleared) {
            for (const [id, callbacks] of this.objectWatchers) {
                for (let callback of callbacks) {
                    callback(changes.addedObjects.get(id));
                }
            }
        }
        else {
            for (const id of changes.deletedObjectIds) {
                const callbacks = this.objectWatchers.get(id);
                if (callbacks != null) {
                    for (let callback of callbacks) {
                        callback(undefined);
                    }
                }
            }
            for (const [id, added] of changes.addedObjects) {
                const ow = this.objectWatchers.get(id);
                if (ow != null) {
                    for (let callback of ow) {
                        callback(added);
                    }
                }
                if (queryWatchers != null) {
                    for (const watcher of queryWatchers) {
                        if (watcher.query.whereClauseAndFilterMatch(id, added)) {
                            notifyQuery(watcher);
                            queryWatchers.delete(watcher);
                        }
                    }
                }
            }
        }
    }
}


/***/ })

/******/ 	});
/************************************************************************/
/******/ 	// The module cache
/******/ 	var __webpack_module_cache__ = {};
/******/ 	
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/ 		// Check if module is in cache
/******/ 		var cachedModule = __webpack_module_cache__[moduleId];
/******/ 		if (cachedModule !== undefined) {
/******/ 			return cachedModule.exports;
/******/ 		}
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = __webpack_module_cache__[moduleId] = {
/******/ 			// no module.id needed
/******/ 			// no module.loaded needed
/******/ 			exports: {}
/******/ 		};
/******/ 	
/******/ 		// Execute the module function
/******/ 		__webpack_modules__[moduleId](module, module.exports, __webpack_require__);
/******/ 	
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/ 	
/************************************************************************/
/******/ 	/* webpack/runtime/compat get default export */
/******/ 	(() => {
/******/ 		// getDefaultExport function for compatibility with non-harmony modules
/******/ 		__webpack_require__.n = (module) => {
/******/ 			var getter = module && module.__esModule ?
/******/ 				() => (module['default']) :
/******/ 				() => (module);
/******/ 			__webpack_require__.d(getter, { a: getter });
/******/ 			return getter;
/******/ 		};
/******/ 	})();
/******/ 	
/******/ 	/* webpack/runtime/define property getters */
/******/ 	(() => {
/******/ 		// define getter functions for harmony exports
/******/ 		__webpack_require__.d = (exports, definition) => {
/******/ 			for(var key in definition) {
/******/ 				if(__webpack_require__.o(definition, key) && !__webpack_require__.o(exports, key)) {
/******/ 					Object.defineProperty(exports, key, { enumerable: true, get: definition[key] });
/******/ 				}
/******/ 			}
/******/ 		};
/******/ 	})();
/******/ 	
/******/ 	/* webpack/runtime/hasOwnProperty shorthand */
/******/ 	(() => {
/******/ 		__webpack_require__.o = (obj, prop) => (Object.prototype.hasOwnProperty.call(obj, prop))
/******/ 	})();
/******/ 	
/******/ 	/* webpack/runtime/make namespace object */
/******/ 	(() => {
/******/ 		// define __esModule on exports
/******/ 		__webpack_require__.r = (exports) => {
/******/ 			if(typeof Symbol !== 'undefined' && Symbol.toStringTag) {
/******/ 				Object.defineProperty(exports, Symbol.toStringTag, { value: 'Module' });
/******/ 			}
/******/ 			Object.defineProperty(exports, '__esModule', { value: true });
/******/ 		};
/******/ 	})();
/******/ 	
/************************************************************************/
var __webpack_exports__ = {};
// This entry need to be wrapped in an IIFE because it need to be isolated against other modules in the chunk.
(() => {
/*!**********************!*\
  !*** ./src/index.ts ***!
  \**********************/
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _collection__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./collection */ "./src/collection.ts");
/* harmony import */ var _instance__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./instance */ "./src/instance.ts");
/* harmony import */ var _link__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ./link */ "./src/link.ts");
/* harmony import */ var _open__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(/*! ./open */ "./src/open.ts");
/* harmony import */ var _query__WEBPACK_IMPORTED_MODULE_4__ = __webpack_require__(/*! ./query */ "./src/query.ts");
/* harmony import */ var _txn__WEBPACK_IMPORTED_MODULE_5__ = __webpack_require__(/*! ./txn */ "./src/txn.ts");






window.openIsar = _open__WEBPACK_IMPORTED_MODULE_3__.openIsar;
window.IsarInstance = _instance__WEBPACK_IMPORTED_MODULE_1__.IsarInstance;
window.IsarTxn = _txn__WEBPACK_IMPORTED_MODULE_5__.IsarTxn;
window.IsarCollection = _collection__WEBPACK_IMPORTED_MODULE_0__.IsarCollection;
window.IsarQuery = _query__WEBPACK_IMPORTED_MODULE_4__.IsarQuery;
window.IsarLink = _link__WEBPACK_IMPORTED_MODULE_2__.IsarLink;

})();

/******/ })()
;
//# sourceMappingURL=index.js.map''';
