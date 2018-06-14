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
        
        var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Not available")
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
        let tag = command.arguments[0] as? String
        let hasLoginKey: Bool = UserDefaults.standard.bool(forKey: tag!)
        if hasLoginKey {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
        } else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "No Password in chain")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
        }
    }
    
    @objc func save(_ command: CDVInvokedUrlCommand?) {
        let tag = command?.arguments[0] as? String
        let password = command?.arguments[1] as? String
        do {
            let keychainItem = KeychainItem()
            try keychainItem.setValueToKeyChain(value: password!, key: tag!)
            UserDefaults.standard.set(true, forKey: tag!)
            UserDefaults.standard.synchronize()
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
            commandDelegate.send(pluginResult, callbackId: command?.callbackId)
        } catch let errorStatus as ResponseStatus{
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: errorStatus.description)
            commandDelegate.send(pluginResult, callbackId: command?.callbackId)
        } catch {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error.localizedDescription)
            commandDelegate.send(pluginResult, callbackId: command?.callbackId)
        }
    }
    
    @objc func delete(_ command: CDVInvokedUrlCommand?) {
        let tag = command?.arguments[0] as? String
        do {
            if (tag != nil) && UserDefaults.standard.object(forKey: tag!) != nil {
                let keychainItem = KeychainItem()
                try keychainItem.deleteValueFromKeyChain(key: tag!)
            }
            UserDefaults.standard.removeObject(forKey: tag!)
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
            commandDelegate.send(pluginResult, callbackId: command?.callbackId)
        } catch let errorStatus as ResponseStatus {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: errorStatus.description)
            commandDelegate.send(pluginResult, callbackId: command?.callbackId)
        } catch let error {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Could not delete password from chain: " + error.localizedDescription)
            commandDelegate.send(pluginResult, callbackId: command?.callbackId)
        }
    }
    
    @objc func verify(_ command: CDVInvokedUrlCommand?) {
        let tag = command?.arguments[0] as? String
        let message = command?.arguments[1] as? String
        let hasLoginKey: Bool = UserDefaults.standard.bool(forKey: tag!)
        if hasLoginKey {
            do {
                let keychainItem = KeychainItem()
                let password = try keychainItem.getValueFromKeyChain(key: tag!)
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: password)
                commandDelegate.send(pluginResult, callbackId: command?.callbackId)
            } catch let errorStatus as ResponseStatus {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: errorStatus.description)
                commandDelegate.send(pluginResult, callbackId: command?.callbackId)
            } catch let error{
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error.localizedDescription)
                commandDelegate.send(pluginResult, callbackId: command?.callbackId)
            }
        }
        else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "-1")
            commandDelegate.send(pluginResult, callbackId: command?.callbackId)
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
}
