//
//  ViewController+func.swift
//  dailyApp
//
//  Created by eunhye on 2021/02/26.
//

import Foundation
import UIKit

extension ViewController {
    
    func bind(){
        write_btn.rx.tap
            .bind { (_) in
                App.module.presenter.addSubview(.visibleView, type: WriteView.self){ view in
                    view.isType = .write
                    view.setDidFinish{ image, data, date in
                        self.merge(date)
                    }
                }
        }.disposed(by: bag)
        
        setting_btn.rx.tap
            .bind { (_) in
                App.module.presenter.addSubview(.visibleView, type: SettingView.self){ view in
                    view.mainView = self
                }
        }.disposed(by: bag)
        
        
        pre_btn.rx.tap
            .bind { (_) in
                if App.DayData.isEmpty || self.count == 1{
                    return
                }
                self.scrollCount(false)
        }.disposed(by: bag)
        
        
        next_btn.rx.tap
            .bind { (_) in
                if App.DayData.isEmpty || self.count == 1{
                    return
                }
                self.scrollCount(true)
        }.disposed(by: bag)
    }
    
    
    /*
     다른 뷰 컨트롤러 호출
     */
    func present(_ id: String) {
        let loginVC = storyboard?.instantiateViewController(withIdentifier: id)
        loginVC?.modalPresentationStyle = .overCurrentContext
        present(loginVC!, animated: true, completion: nil)
    }

    
    func reloadAllViewControllers() {
        let storyboard = UIApplication.shared.windows.filter({$0.isKeyWindow}).first?.rootViewController?.storyboard
        let id = UIApplication.shared.windows.filter({$0.isKeyWindow}).first?.rootViewController?.value(forKey: "storyboardIdentifier")
        let rootVC = storyboard?.instantiateViewController(withIdentifier: id as! String)
        UIApplication.shared.windows.filter({$0.isKeyWindow}).first?.rootViewController = rootVC
    }
    
    
    func scrollCount(_ next : Bool){
        if next {
            pre_btn.isEnabled = true
            pre_btn.setImage(UIImage(named: "btn_hd_prev"), for: .normal)
            
            page_scrollview.contentOffset.x = page_scrollview.contentOffset.x + page_scrollview.frame.size.width * CGFloat(1)
            
            let pageIndex = Int(page_scrollview.contentOffset.x/page_scrollview.frame.width)
            if pageIndex + 1 >= pageControl.numberOfPages {
                next_btn.isEnabled = false
                next_btn.setImage(UIImage(named: "btn_page_next_disa"), for: .normal)
            }
        }
        else {
            next_btn.isEnabled = true
            next_btn.setImage(UIImage(named: "btn_page_next"), for: .normal)
            
            if pageControl.currentPage <= 0 {
                pre_btn.isEnabled = false
                pre_btn.setImage(UIImage(named: "btn_page_prev_disa"), for: .normal)
            }
            page_scrollview.contentOffset.x = page_scrollview.contentOffset.x + page_scrollview.frame.size.width * CGFloat(-1)
        }
        
        
        var pageIndex = Int(page_scrollview.contentOffset.x/page_scrollview.frame.width)
        if pageIndex > self.pages.count - 1{
            pageIndex = 0
        }
        
        if pageIndex < 0 {
            pageIndex = self.pages.count - 1
        }
        
        year_label.text = String(Calendar.current.component(.year, from: self.pages[pageIndex].items.last!.date))
        month_label.text = String(Calendar.current.component(.month, from: self.pages[pageIndex].items.last!.date)) + "월"
    }
}
