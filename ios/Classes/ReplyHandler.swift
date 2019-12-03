//
//  ReplyHandler.swift
//  bluetooth_ble
//
//  Created by Caijinglong on 2019/11/29.
//

import Foundation
import Flutter

class ReplyHandler{
    
    var call: FlutterMethodCall
    var result: FlutterResult
    
    var isReply = false
    
    init(call: FlutterMethodCall, result: @escaping FlutterResult){
        self.call = call
        self.result = result
    }
    
    func success(any:Any?){
        replyOnMainThread(result: any)
    }
    
    func fail(code:String, message:String? = nil, details:Any? = nil){
        let error = FlutterError(code: code, message: message, details: details)
        replyOnMainThread(result: error)
    }
    
    func notImplemented(){
        replyOnMainThread(result: FlutterMethodNotImplemented)
    }
    
    private func replyOnMainThread(result:Any?){
        if isReply{
            return
        }
        isReply = true
        DispatchQueue.main.async {
            self.result(result)
        }
    }
    
}

extension ReplyHandler{
    subscript(key:String) -> Any? {
        return (self.call.arguments as? Dictionary)?[key]
    }
    
    func getData(key:String)-> Data{
        let typedData = self[key] as! FlutterStandardTypedData
        return typedData.data
    }
}
