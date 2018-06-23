//
//  Keychain.swift
//  cordov-keychain
//
//  Created by Chi Dov on 6/12/18.
//

import Foundation
import LocalAuthentication

@objc(BiometryKeychainAccess) class BiometryKeychainAccess : CDVPlugin {
    
    fileprivate var policy: LAPolicy!
    
    @objc func isAvailable(_ command: CDVInvokedUrlCommand){
        let authenticationContext = LAContext()
        var biometryType = "finger"
        var error:NSError?
        
        let available = authenticationContext.canEvaluatePolicy(policy, error: &error)
        
        var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: PluginError.BIOMETRICS_NOT_AVAILABLE)
        if available == true {
            if #available(iOS 11.0, *) {
                switch(authenticationContext.biometryType) {
                case .none:
                    biometryType = "none"
                case .touchID:
                    biometryType = "finger"
                case .faceID:
                    biometryType = "face"
                }
            }
            
            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: biometryType)
        }
        
        commandDelegate.send(pluginResult, callbackId:command.callbackId)
    }
    
    @objc func has(_ command: CDVInvokedUrlCommand) {
        guard let tag = command.arguments[0] as? String else {
            pluginResponse(status: CDVCommandStatus_ERROR, message: PluginError.INVALID_ARGUMENT, command: command)
            return
        }
        let hasLoginKey: Bool = UserDefaults.standard.bool(forKey: tag)
        if hasLoginKey {
            pluginResponse(status: CDVCommandStatus_OK, command: command)
        } else {
            pluginResponse(status: CDVCommandStatus_ERROR, message: PluginError.USER_NOT_FOUND, command: command)
        }
    }
    
    @objc func save(_ command: CDVInvokedUrlCommand?) {
        guard let tag = command?.arguments[0] as? String, let password = command?.arguments[1] as? String else {
            pluginResponse(status: CDVCommandStatus_ERROR, message: PluginError.INVALID_ARGUMENT, command: command)
            return
        }
        do {
            let keychainItem = KeychainItem()
            try keychainItem.setValueToKeyChain(value: password, key: tag)
            UserDefaults.standard.set(true, forKey: tag)
            UserDefaults.standard.synchronize()
            pluginResponse(status: CDVCommandStatus_OK, command: command)
        } catch let errorStatus as ResponseStatus{
            pluginResponse(status: CDVCommandStatus_ERROR, message: errorStatus.description, command: command)
        } catch {
           pluginResponse(status: CDVCommandStatus_ERROR, message: error.localizedDescription, command: command)
        }
    }
    
    @objc func delete(_ command: CDVInvokedUrlCommand?) {
        guard let tag = command?.arguments[0] as? String else {
            pluginResponse(status: CDVCommandStatus_ERROR, message: PluginError.INVALID_ARGUMENT, command: command)
            return
        }
        do {
            if UserDefaults.standard.object(forKey: tag) != nil {
                let keychainItem = KeychainItem()
                try keychainItem.deleteValueFromKeyChain(key: tag)
            }
            UserDefaults.standard.removeObject(forKey: tag)
            pluginResponse(status: CDVCommandStatus_OK, command: command)
        } catch let errorStatus as ResponseStatus {
            pluginResponse(status: CDVCommandStatus_ERROR, message: errorStatus.description, command: command)
        } catch let error {
            pluginResponse(status: CDVCommandStatus_ERROR, message: "Could not delete password from chain: " + error.localizedDescription, command: command)
        }
    }
    
    @objc func verify(_ command: CDVInvokedUrlCommand?) {
        guard let tag = command?.arguments[0] as? String else {
            pluginResponse(status: CDVCommandStatus_ERROR, message: PluginError.INVALID_ARGUMENT, command: command)
            return
        }
        let message = command?.arguments[1] as? String
        let hasLoginKey: Bool = UserDefaults.standard.bool(forKey: tag)
        if hasLoginKey {
            do {
                let keychainItem = KeychainItem()
                guard let password = try keychainItem.getValueFromKeyChain(key: tag, messagePrompt: message ?? "") else {
                    pluginResponse(status: CDVCommandStatus_ERROR, message: PluginError.KEYCHAIN_EXPIRED, command: command)
                    return
                }
                pluginResponse(status: CDVCommandStatus_OK, message: password, command: command)
            } catch let errorStatus as ResponseStatus {
                pluginResponse(status: CDVCommandStatus_ERROR, message: errorStatus.description, command: command)
            } catch let error{
                pluginResponse(status: CDVCommandStatus_ERROR, message: error.localizedDescription, command: command)
            }
        }
        else {
            pluginResponse(status: CDVCommandStatus_ERROR, message: PluginError.USER_NOT_FOUND, command: command)
        }
    }
    override func pluginInitialize() {
        super.pluginInitialize()

        guard #available(iOS 9.0, *) else {
            policy = .deviceOwnerAuthenticationWithBiometrics
            return
        }

        policy = .deviceOwnerAuthentication

    }
    
    func pluginResponse(status: CDVCommandStatus, message: String? = nil, command: CDVInvokedUrlCommand?){
        let pluginResult = CDVPluginResult(status: status, messageAs: message)
        commandDelegate.send(pluginResult, callbackId: command?.callbackId)
    }
}
public enum PluginError{
    static let BIOMETRICS_NOT_AVAILABLE = "biometrics.not_available"
    static let KEYCHAIN_EXPIRED = "security_key.expired"
    static let USER_NOT_FOUND = "user.not_found"
    static let INVALID_ARGUMENT = "argument.invalid"
}
