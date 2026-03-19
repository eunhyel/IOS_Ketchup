//
//  Logger.swift
//  iosYeoboya
//
//  Created by cschoi724 on 31/07/2019.
//  Copyright © 2019 Inforex. All rights reserved.
//

import Foundation
import os.log

class log {
    private class config {
        static var systemLog : Active = .disable
        static var date : Active = .enable
        static var event : Active = .enable
        static var fileName : Active = .enable
        static var lineColum : Active = .enable
        static var funcName : Active = .enable
    }
    
    enum Active{
        case disable
        case enable
        
        var rawValue : Bool{
            switch self {
            case .disable: return false
            case .enable: return true
            }
        }
    }
        
    enum Event : String{
        case e = "‼️" // error
        case i = "ℹ️" // info
        case d = "🔹" // debug
        case v = "💬" // verbose
        case w = "⚠️" // warning
        case s = "🔥" // severe
    }
    
    static var filter: String = "^-^"
    static var dateFormat = "yyyy-MM-dd hh:mm:ssSSS" // Use your own
    static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        return formatter
    }
    
    private class func sourceFileName(filePath: String) -> String {
        let components = filePath.components(separatedBy: "/")
        return components.isEmpty ? "" : components.last!
    }
    

    
   class func log(
        _ object: Any,
        date : String,
        event : String,
        sourceFileName: String,
        line: Int,
        column: Int,
        funcName: String) {
        let date = config.date.rawValue ? date : ""
        let event = config.event.rawValue ? event : ""
        let sourceFileName = config.fileName.rawValue ? "[\(sourceFileName)]" : ""
        let lineColum = config.lineColum.rawValue ? "\(line):\(column)" : ""
        let funcName = config.funcName.rawValue ? funcName : ""
    
        //setenv("OS_ACTIVITY_MODE", T##__value: UnsafePointer<Int8>!##UnsafePointer<Int8>!, T##__overwrite: Int32##Int32) 다시 enable 시켜줄수 있을것같음
        if let mode = getenv("OS_ACTIVITY_MODE"){
            if (strcmp(mode, "disable") == 0) { config.systemLog = .disable}
            else {config.systemLog = .enable }
        }else{
            config.systemLog = .enable
        }
    
        #if DEBUG
        if config.systemLog.rawValue{
            NSLog("\(lineColum) \(filter)\(event)\(sourceFileName) \(funcName) : \(object)")
        }else{
            print("\(date) \(lineColum) \(filter)\(event)\(sourceFileName) \(funcName) : \(object)")
        }
        #endif
    }
    

    class func e( _ object: Any,// 1
        filename: String = #file, // 2
        line: Int = #line, // 3
        column: Int = #column, // 4
        funcName: String = #function) {
        log(object, date: dateFormatter.string(from: Date()), event: Event.e.rawValue, sourceFileName: sourceFileName(filePath: filename), line: line, column: column, funcName: funcName)

    }
    class func i( _ object: Any,// 1
        filename: String = #file, // 2
        line: Int = #line, // 3
        column: Int = #column, // 4
        funcName: String = #function) {
        log(object, date: dateFormatter.string(from: Date()), event: Event.i.rawValue, sourceFileName: sourceFileName(filePath: filename), line: line, column: column, funcName: funcName)
        
    }
    
    class func d( _ object: Any,// 1
        filename: String = #file, // 2
        line: Int = #line, // 3
        column: Int = #column, // 4
        funcName: String = #function) {
        log(object, date: dateFormatter.string(from: Date()), event: Event.d.rawValue, sourceFileName: sourceFileName(filePath: filename), line: line, column: column, funcName: funcName)
        
    }
    
    class func v( _ object: Any,// 1
        filename: String = #file, // 2
        line: Int = #line, // 3
        column: Int = #column, // 4
        funcName: String = #function) {
        log(object, date: dateFormatter.string(from: Date()), event: Event.v.rawValue, sourceFileName: sourceFileName(filePath: filename), line: line, column: column, funcName: funcName)
        
    }
    
    class func w( _ object: Any,// 1
        filename: String = #file, // 2
        line: Int = #line, // 3
        column: Int = #column, // 4
        funcName: String = #function) {
        log(object, date: dateFormatter.string(from: Date()), event: Event.w.rawValue, sourceFileName: sourceFileName(filePath: filename), line: line, column: column, funcName: funcName)
        
    }
    
    class func s( _ object: Any,// 1
        filename: String = #file, // 2
        line: Int = #line, // 3
        column: Int = #column, // 4
        funcName: String = #function) {
        log(object, date: dateFormatter.string(from: Date()), event: Event.s.rawValue, sourceFileName: sourceFileName(filePath: filename), line: line, column: column, funcName: funcName)
        
    }
    
    
}



