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
```javascript
window.plugins.keychain.has(
'cdov',
function(result){alert(result)},
function(error){alert(error)}
);
```

### Save data to Keychain
```javascript
window.plugins.keychain.save(
'cdov',
'password',
true,
function(){alert(true)},
function(error){alert(error)}
);
```

### Verify biometrics and retrive data from keychain
```javascript
window.plugins.keychain.verify(
'cdov',
'message',
function(result){alert(result)},
function(error){alert(error)}
);
```

### Delete data from keychain 
```javascript
window.plugins.keychain.delete(
'cdov',
function(result){alert(result)},
function(error){alert(error)}
);
```
