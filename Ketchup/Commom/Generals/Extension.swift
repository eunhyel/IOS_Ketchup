//
//  Extension.swift
//  dailyApp
//
//  Created by eunhye on 2021/02/22.
//

import Foundation
import UIKit

extension UIColor {
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1.0) {
        self.init(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: a)
    }
}


extension UIColor {
    convenience init(hex: Int, alpha: CGFloat) {
        let components = (
            R: CGFloat((hex >> 16) & 0xff) / 255,
            G: CGFloat((hex >> 08) & 0xff) / 255,
            B: CGFloat((hex >> 0) & 0xff) / 255
        )
        
        self.init(red: components.R, green: components.G, blue: components.B, alpha: alpha)
    }
}






enum ColorType: String {
    case blue = "20aee5"
    case textColor = "555555"
}

extension UIColor {
    
    class func hexStr(_ hexStr: String) -> UIColor {
        return UIColor.hexStr(hexStr, alpha: 1)
    }
    
    class func color(_ hexColor: ColorType) -> UIColor {
        return UIColor.hexStr(hexColor.rawValue, alpha: 1.0)
    }
    
    class func hexStr(_ str: String, alpha: CGFloat) -> UIColor {
        let hexStr = str.replacingOccurrences(of: "#", with: "")
        let scanner = Scanner(string: hexStr)
        var color: UInt32 = 0
        if scanner.scanHexInt32(&color) {
            let r = CGFloat((color & 0xFF0000) >> 16) / 255.0
            let g = CGFloat((color & 0x00FF00) >> 8) / 255.0
            let b = CGFloat(color & 0x0000FF) / 255.0
            return UIColor(red: r, green: g, blue: b , alpha: alpha)
        } else {
            print("Invalid hex string")
            return .white
        }
    }
    
}


func getNavigationController() -> UIViewController {
    return UIApplication.shared.windows[0].rootViewController!
}


extension UIImage {
    func jpegData(withCompressionQuality quality: CGFloat) -> Data? {
        return autoreleasepool(invoking: {() -> Data? in
            return self.jpegData(compressionQuality: quality)
        })
    }
}


extension String {

    func toDate(withFormat format: String = "yyyy-MM-dd HH:mm:ss")-> Date?{

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.dateFormat = format
        let date = dateFormatter.date(from: self)

        return date

    }
}

extension Date {

    func toString(withFormat format: String = "yyyyMMddHHmmss") -> String {

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        let str = dateFormatter.string(from: self)

        return str
    }
}
