//
//  HelperFunc.swift
//  dailyApp
//
//  Created by eunhye on 2021/03/19.
//

import Foundation
import UIKit

func topMostController() -> UIViewController? {
    guard let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first, let rootViewController = window.rootViewController else {
        return nil
    }

    var topController = rootViewController

    while let newTopController = topController.presentedViewController {
        topController = newTopController
    }

    return topController
}
