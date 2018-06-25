var exec = require('cordova/exec');

var keychain = {
  isAvailable: function(successCallback, errorCallback) {
    exec(successCallback, errorCallback, 'BiometryKeychainAccess', 'isAvailable', []);
  },
  save: function(key, password, userAuthenticationRequired, successCallback, errorCallback) {
    exec(successCallback, errorCallback, 'BiometryKeychainAccess', 'save', [key, password, userAuthenticationRequired]);
  },
  verify: function(key, message, successCallback, errorCallback) {
    exec(successCallback, errorCallback, 'BiometryKeychainAccess', 'verify', [key, message]);
  },
  has: function(key, successCallback, errorCallback) {
    exec(successCallback, errorCallback, 'BiometryKeychainAccess', 'has', [key]);
  },
  delete: function(key, successCallback, errorCallback) {
    exec(successCallback, errorCallback, 'BiometryKeychainAccess', 'delete', [key]);
  }
};

module.exports = keychain;
