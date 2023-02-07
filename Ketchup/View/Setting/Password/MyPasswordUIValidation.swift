//
//  MyPasswordUIValidation.swift
//  SmileLock-Example
//
//  Created by rain on 4/22/16.
//  Copyright © 2016 RECRUIT LIFESTYLE CO., LTD. All rights reserved.
//

import UIKit

class MyPasswordModel {
    class func match(_ password: String, _ isEdit: Bool) -> MyPasswordModel? {
        if (UserDefaults.standard.value(forKey: "key") != nil)  {        //test
            if isEdit {     //첫회 편집모드이면 검사 안한다
                return MyPasswordModel()
            }
            else {
                guard password == UserDefaults.standard.value(forKey: "key") as? String else {
                    return nil
                }
            }
        }
        return MyPasswordModel()
    }
}

class MyPasswordUIValidation: PasswordUIValidation<MyPasswordModel> {
    var password = ""
    init(in stackView: UIStackView) {
        super.init(in: stackView, digit: 4)
        validation = { password in
            self.password = password
            return MyPasswordModel.match(password, self.isEdit)
        }
    }
    
    //handle Touch ID
    override func touchAuthenticationComplete(_ passwordContainerView: PasswordContainerView, success: Bool, error: Error?) {
        if success {
            let dummyModel = MyPasswordModel()
            self.success?(dummyModel)
        } else {
            passwordContainerView.clearInput()
        }
    }
}
