// Generated by CoffeeScript 1.9.3
(function() {
  var VERBOSE, fn, i, internalLog, len, ref, type, util;

  util = require('util');

  VERBOSE = false;

  internalLog = function(type, args) {
    if (!VERBOSE && (type === 'verbose')) {
      return;
    }
    if (type === 'syntax') {
      return console.error.apply(null, args);
    } else {
      args.unshift("[" + type + "]");
      return util.log.apply(null, args);
    }
  };

  module.exports = {};

  ref = ['verbose', 'progress', 'warning', 'error', 'syntax'];
  fn = function(type) {
    return module.exports[type] = function() {
      return internalLog.call(null, type, Array.prototype.slice.call(arguments));
    };
  };
  for (i = 0, len = ref.length; i < len; i++) {
    type = ref[i];
    fn(type);
  }

  module.exports.setVerbose = function(v) {
    VERBOSE = v;
    if (v) {
      return util.log("Verbose mode.");
    }
  };

}).call(this);