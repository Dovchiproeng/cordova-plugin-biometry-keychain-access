//
//  KeychainItem.swift
//  cordova-keychain
//
//  Created by Chi Dov on 6/12/18.
//

import Foundation
import Security
public final class KeychainItem {
    private let Class = String(kSecClass)
    private let Service = String(kSecAttrService)
    private let Account = String(kSecAttrAccount)
    private let Match = String(kSecMatchLimit)
    private let ReturnData = String(kSecReturnData)
    private let ValueData = String(kSecValueData)
    private let AccessControl = String(kSecAttrAccessControl)
    
    var keyChainItemServiceName: String
    init() {
        // Add a Netspend Specific service name to query the correct keychain item if multiple apps use this plugin
        let bundleID = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String
        keyChainItemServiceName = (bundleID ?? "") + ".TouchIDPlugin"
    }
    
    func getSecAccessControl() -> SecAccessControl? {
        // Create the access control attribute:Use the current set of Biometry (touchID or FaceID) entries saved to the keychain
        // If the set of keychain entries for Biometry changes, the app will not be able to access the keychain entry anymore.
        var error:  Unmanaged<CFError>?
        var sacCreateFlags: SecAccessControlCreateFlags
        if #available(iOS 11.3, *) {
            sacCreateFlags = .biometryCurrentSet
        } else if #available(iOS 9.0, *) {
            sacCreateFlags = .touchIDCurrentSet
        } else {
            sacCreateFlags = .userPresence
        }
        let scaObject = SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, sacCreateFlags, &error)
        
        assert(scaObject != nil && error == nil, "Can't store identifier in the KeyChain: \(String(describing: error)).")
        return scaObject
    }
    
    func deleteValueFromKeyChain(key: String) throws
    {
        var query = getBaseKeychainQuery(key: key)
        query[ReturnData] = kCFBooleanTrue
        
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw securityError(status: status)
        }
    }
    
    func getValueFromKeyChain(key: String) throws -> String?
    {
        let query = getFindOneValueKeychainQuery(key: key)
    
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw ResponseStatus.unexpectedError
            }
            guard let string = String(data: data, encoding: .utf8) else {
                print("failed to convert data to string")
                throw ResponseStatus.conversionError
            }
            return string
        case errSecItemNotFound:
            return nil
        default:
            throw securityError(status: status)
        }
    }
    
    func setValueToKeyChain(value: String, key: String) throws
    {
    
        var query = self.getFindOneValueKeychainQuery(key: key)
        
        if #available(iOS 9.0, *) {
            query[kSecUseAuthenticationUI as String] = kSecUseAuthenticationUIFail
        } else {
            query[kSecUseNoAuthenticationUI as String] = kCFBooleanTrue
        }
        
        // Create the keychain attributes for editing/inserting the entry
        var attributes = try initAttributes(key: key, value: value)
        
        // If the keychain item already exists, modify it:
        var status = SecItemCopyMatching(query as CFDictionary, nil)
        switch status {
            case errSecSuccess, errSecInteractionNotAllowed:
                ////item exists in the keychain
                let updateQuery = getBaseKeychainQuery(key: key)
        
                status = SecItemUpdate(updateQuery as CFDictionary, attributes as CFDictionary)
                if status != errSecSuccess {
                    throw securityError(status: status)
                }
    
            case errSecItemNotFound:
                ////item not exist
                //add Item Class while update doesn't need it
                attributes[Class] = kSecClassGenericPassword
                
                status = SecItemAdd(attributes as CFDictionary, nil)
                if status != errSecSuccess {
                    throw securityError(status: status)
                }
            default:
                throw securityError(status: status)
        }
    }
    
    func initAttributes(key: String, value: String) throws -> [String: Any]{
        var attributes = [String: Any]()
        attributes[Account] = key;
        attributes[Service] = keyChainItemServiceName
        // Convert the password NSString to NSData to fit the API paradigm:
        guard let password = value.data(using: .utf8) else {
            print("failed to convert string to data")
            throw ResponseStatus.conversionError
        }
        attributes[ValueData] = password
        // Add the access control object to the keychain entry
        attributes[AccessControl] = getSecAccessControl()
        return attributes
    }
    
    func getBaseKeychainQuery(key: String) -> [String: Any] {
        var query = [String: Any]()
        // Set the key (username) as the account value for the entry
        query[Account] = key
        query[Class] = kSecClassGenericPassword
        query[Service] = keyChainItemServiceName
        return query
    }
    
    func getFindOneValueKeychainQuery(key: String) -> [String: Any] {
        var query = getBaseKeychainQuery(key: key)
        query[Match] = kSecMatchLimitOne
        query[ReturnData] = kCFBooleanTrue
        return query
    }
    
    @discardableResult
    fileprivate class func securityError(status: OSStatus) -> Error {
        let error = ResponseStatus(status: status)
        print("OSStatus error:[\(error.code)] \(error.description)")
        return error
    }
    
    @discardableResult
    fileprivate func securityError(status: OSStatus) -> Error {
        return type(of: self).securityError(status: status)
    }
}

public enum ResponseStatus: OSStatus, Error {
    case success                            = 0
    case param                              = -50
    case userCanceled                       = -128
    case authFailed                         = -25293
    case noSuchKeychain                     = -25294
    case invalidKeychain                    = -25295
    case duplicateKeychain                  = -25296
    case duplicateCallback                  = -25297
    case invalidCallback                    = -25298
    case duplicateItem                      = -25299
    case itemNotFound                       = -25300
    case conversionError                    = -67594
    case unexpectedError                    = -99999
}

extension ResponseStatus: RawRepresentable, CustomStringConvertible {
    
    public init(status: OSStatus) {
        if let mappedStatus = ResponseStatus(rawValue: status) {
            self = mappedStatus
        } else {
            self = .unexpectedError
        }
    }
    
    public var code: Int {
        return Int(rawValue)
    }
    
    public var description: String {
        switch self {
        case .success:
            return "success"
        case .param:
            return "param.invalid"
        case .userCanceled:
            return "user.canceled"
        case .authFailed:
            return "auth.failed"
        case .noSuchKeychain:
            return "keychain.notfound"
        case .invalidKeychain:
            return "keychain.invalid"
        case .duplicateKeychain:
            return "keychain.duplicate"
        case .duplicateCallback:
            return "callback.duplicate"
        case .invalidCallback:
            return "callback.invalid"
        case .duplicateItem:
            return "keychain_item.duplicate"
        case .itemNotFound:
            return "keychain_item.notfound"
        case .conversionError:
            return "conversion.error"
        case .unexpectedError:
            return "server.error"
        }
    }
}
