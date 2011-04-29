var EventDispatcher = exports = module.exports = function(triggerCallback, bindCallback) {
  this._triggerCallback = triggerCallback || function() {};
  this._bindCallback = bindCallback || function() { return true; };
  this.trigger = _.onServer ? function() {} : this._trigger;
  this._names = {};
}
EventDispatcher.prototype = {
  bind: function(name, listener) {
    if (!this._bindCallback(name, listener)) return;
    var names = this._names,
        key = _.isDefined(listener) ? JSON.stringify(listener) : 'null',
        obj = names[name] || {};
    obj[key] = true;
    names[name] = obj;
  },
  unbind: function(name, listener) {
    var names = this._names,
        key = JSON.stringify(listener);
    delete names[name][key];
  },
  _trigger: function(name, value, options) {
    var listeners = this._names[name],
        callback = this._triggerCallback;
    if (!listeners) return;
    Object.keys(listeners).forEach(function(key) {
      var listener = JSON.parse(key);
      if (!callback(listener, value, options)) {
        delete listeners[key];
      }
    });
  },
  get: function() {
    // The output of this function will be encoded in JSON and sent to the
    // browser. Therefore, this function transforms the event data from a key
    // value lookup into an array, which is a much more compact respresentation.
    // In addition, it swaps quote types to reduce the need for escaping
    var names = this._names,
        out = {};
    Object.keys(names).forEach(function(name) {
      out[name] = Object.keys(names[name]).map(swapQuotes);
    });
    return out;
  },
  set: function(n) {
    // Undo the transforms done in the get function and add the new events
    var names = this._names;
    Object.keys(n).forEach(function(name) {
      var obj = names[name] = {},
          listeners = n[name];
      listeners.forEach(function(listener) {
        obj[swapQuotes(listener)] = true;
      });
    });
  }
}

function swapQuotes(s) {
  return s.replace(/['"]/g, function(match) {
    return match === '"' ? "'" : '"';
  });
}

// Exported for testing purposes
var _ = exports._ = require('./utils');