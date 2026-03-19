//
//  BCRegister+Text.swift
//  iosClubRadio
//
//  Copyright © 2020 Inforex. All rights reserved.
//

import Foundation
import UIKit

extension WriteView : UITextViewDelegate{
    
    func setTextView(){
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        daily_textView.delegate = self
        daily_textView.textContainer.maximumNumberOfLines = 6
    }
    

    @objc func keyboardWillShow(notification: NSNotification) {
        if !isKeyboard {
            if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                view_bottom_constraint.constant = keyboardSize.size.height
                if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first{
                    let bottomPadding = window.safeAreaInsets.bottom
                    var textHeight = 60
                    if UIScreen.main.bounds.height > 667 {
                        textHeight = 110
                    }
                    let height = keyboardSize.size.height - bottomPadding - CGFloat(textHeight)
                    view.bounds.origin.y += height
                }
                self.layoutIfNeeded()
            }
            isKeyboard = true
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        isKeyboard = false
        view.bounds.origin.y = 0
        self.layoutIfNeeded()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if daily_textView.text == "내용을 입력하세요" {
            daily_textView.text = ""
        }
        daily_textView.textColor = UIColor(r: 48,g: 48,b: 48)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let existingLines = textView.text.components(separatedBy: CharacterSet.newlines)
        let newLines = text.components(separatedBy: CharacterSet.newlines)
        let linesAfterChange = existingLines.count + newLines.count - 1
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.count

        return (numberOfChars <= 100 && /// 최대 글자수 제한
            linesAfterChange <= textView.textContainer.maximumNumberOfLines ) /// 텍스트뷰 최대 줄 길이 제한
    }
}
