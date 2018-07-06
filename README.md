# cordova-plugin-biometry-keychain-access

**This plugin aim to provides a single and simple interface for accessing keychain from iOS devices using biometrics verification.**
 
## API Usage
### Check Biometrics Availablity 
In order to access and persist data to your keychain using biometrics verification, you will need to check whether your device is available with biometry.
```javascript
window.plugins.keychain.isAvailable(
  function(type) {alert(type)}, // success callback: biometrics type 'face' or 'touch'
  function(error) {alert(msg)} // error callback: biometrics.not_available
);
```
### Has Keychain
Check whether key existed
```javascript
window.plugins.keychain.has(
'cdov', // key
function(){alert(true)}, // success callback
function(error){alert(error)} // error callback: user.not_found
);
```

### Save data to Keychain
```javascript
window.plugins.keychain.save(
'cdov', // key
'password', // data
true, // authentication required if true will required biometrics verification to perform this operation
function(){alert(true)}, // success callback
function(error){alert(error)} // error callback: user.not_found
);
```

### Verify biometrics and retrive data from keychain
```javascript
window.plugins.keychain.verify(
'cdov', // key
'message', // authentication UI prompted message
function(data){alert(data)}, // success callback: with data return
function(error){alert(error)} // error callback
);
```

### Delete data from keychain 
```javascript
window.plugins.keychain.delete(
'cdov', // key
function(){alert(true)}, //success callback
function(error){alert(error)} //error callback
);
```
