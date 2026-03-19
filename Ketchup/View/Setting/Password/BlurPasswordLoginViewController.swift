//
//  BlurPasswordLoginViewController.swift
//
//  Created by rain on 4/22/16.
//  Copyright © 2016 Recruit Lifestyle Co., Ltd. All rights reserved.
//

import UIKit

class BlurPasswordLoginViewController: UIViewController {

    @IBOutlet weak var password_label: UILabel!
    @IBOutlet weak var passwordStackView: UIStackView!
    
    //MARK: Property
    var passwordUIValidation: MyPasswordUIValidation!
    var isEdit = false
    var isPassword = false
    var passwordFist = ""
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: Global.backgroundImage)!)
        passwordUIValidation = MyPasswordUIValidation(in: passwordStackView)
        passwordUIValidation.view.isEdit = isEdit
        passwordUIValidation.isEdit = isEdit
        passwordUIValidation.success = { [weak self] _ in
            if self!.isEdit {
                print("*️⃣ 한번더!")    //패스워드 한번더 입력
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self?.passwordUIValidation.resetUI()
                    self?.password_label.text = "다시한번 입력해주세요"
                    if self!.isPassword{
                        if self?.passwordFist == self?.passwordUIValidation.password{
                            if self!.isEdit {
                                UserDefaults.standard.set(self?.passwordUIValidation.password, forKey: "key")      //패스워드값
                                UserDefaults.standard.set(true, forKey: "password")     //패스워드 여부
                            }
                            self?.dismiss(animated: true, completion: nil)
                        }
                        else {
                            self?.passwordUIValidation.view.wrongPassword()
                            self?.password_label.text = "잘못 입력하셨습니다"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self?.passwordUIValidation.resetUI()
                                self?.password_label.text = "암호입력"
                                self?.isPassword = false
                                self?.passwordFist = ""
                            }
                        }
                    }
                    else {
                        self?.passwordFist = (self?.passwordUIValidation.password)!
                    }
                    self?.isPassword = true
                }
            }
            else {
                print("*️⃣ 성공!")
                self?.dismiss(animated: true, completion: nil)
            }
        }
        
        passwordUIValidation.failure = {
            Toast.show("잘못입력하셨습니다.")
            print("*️⃣ 실패!")
        }
        passwordUIValidation.view.rearrangeForVisualEffectView(in: self)
        passwordUIValidation.view.deleteButtonLocalizedTitle = ""
    }
}
