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
    typealias BiometricsVerificationSuccessCallback = ()  -> Void
    
    @objc func isAvailable(_ command: CDVInvokedUrlCommand){
        let authenticationContext = LAContext()
        
        var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: PluginError.BIOMETRICS_NOT_AVAILABLE)
        
        var error:NSError?
        let available = authenticationContext.canEvaluatePolicy(policy, error: &error)
        
        if available == true {
            let biometryType = evaluateBiometricsTypeIfAvailable(laContext: authenticationContext)
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
        
        guard let tag = command?.arguments[0] as? String, let password = command?.arguments[1] as? String,
            let userAuthenticationRequired = command?.arguments[2] as? Bool else {
                pluginResponse(status: CDVCommandStatus_ERROR, message: PluginError.INVALID_ARGUMENT, command: command)
                return
        }
        if userAuthenticationRequired {
            authenticationWithBiometrics(command: command) {
                self.createNewPasswordKeychainItem(key: tag, password: password, command: command)
            }
        } else {
            createNewPasswordKeychainItem(key: tag, password: password, command: command)
        }
        
    }
    
    func createNewPasswordKeychainItem(key: String, password: String, command: CDVInvokedUrlCommand?){
        do {
            let keychainItem = KeychainItem()
            try keychainItem.deleteValueFromKeyChain(key: key)
            try keychainItem.setValueToKeyChain(value: password, key: key)
            UserDefaults.standard.set(true, forKey: key)
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
        
        // if we want to set passcode fall back for authentication
//        if #available(iOS 9.0, *) {
//            policy = .deviceOwnerAuthentication
//            return
//        }
        
        policy = .deviceOwnerAuthenticationWithBiometrics
        
    }
    
    func pluginResponse(status: CDVCommandStatus, message: String? = nil, command: CDVInvokedUrlCommand?){
        let pluginResult = CDVPluginResult(status: status, messageAs: message)
        commandDelegate.send(pluginResult, callbackId: command?.callbackId)
    }
    
    func authenticationWithBiometrics(command: CDVInvokedUrlCommand?, callback: @escaping BiometricsVerificationSuccessCallback) {
        let localAuthenticationContext = LAContext()
        //disable fallback by hide the title
        localAuthenticationContext.localizedFallbackTitle = ""
        
        var authError: NSError?
        
        if localAuthenticationContext.canEvaluatePolicy(policy, error: &authError) {
            var biometricType = evaluateBiometricsTypeIfAvailable(laContext: localAuthenticationContext)
            biometricType = biometricType == "touch" ? "fingerprint" : biometricType
            let reasonString = "Use your \(biometricType) to confirm your identity"
            localAuthenticationContext.evaluatePolicy(policy, localizedReason: reasonString) { success, evaluateError in
                if success {
                    callback()
                } else {
                    self.pluginResponse(status: CDVCommandStatus_ERROR, message: self.evaluateAuthenticationPolicyMessageForLA(errorCode: evaluateError!._code), command: command)
                    //TODO: If you have choosen the 'Fallback authentication mechanism selected' (LAError.userFallback). Handle gracefully
                }
            }
        } else {
            pluginResponse(status: CDVCommandStatus_ERROR, message: PluginError.BIOMETRICS_NOT_AVAILABLE, command: command)
        }
    }
    
    func evaluateAuthenticationPolicyMessageForLA(errorCode: Int) -> String {
        var message = ""
        switch errorCode {
        case LAError.userCancel.rawValue:
            message = "user.canceled"
        default:
            message = "auth.failed"
        }
        return message
    }
    
    func evaluateBiometricsTypeIfAvailable(laContext: LAContext) -> String {
        if #available(iOS 11.0, *) {
            switch laContext.biometryType {
            case .faceID:
                return "face"
            case .touchID:
                return "touch"
            default:
                return "none"
            }
        } else {
            return "touch"
        }
    }
}
public enum PluginError{
    static let BIOMETRICS_NOT_AVAILABLE = "biometrics.not_available"
    static let KEYCHAIN_EXPIRED = "security_key.expired"
    static let USER_NOT_FOUND = "user.not_found"
    static let INVALID_ARGUMENT = "argument.invalid"
}
