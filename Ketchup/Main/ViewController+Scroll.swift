//
//  ViewController+Scroll.swift
//  dailyApp
//
//  Created by eunhye on 2021/02/26.
//

import Foundation
import UIKit

extension ViewController: UIScrollViewDelegate {
    
    func setScrollView(){
        page_scrollview.delegate = self
        page_scrollview.contentOffset.x = page_scrollview.frame.size.width *  CGFloat(count - 1)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        var pageIndex = Int(scrollView.contentOffset.x/scrollView.frame.width)
        if pageIndex == 0 {
            pageControl.currentPage = count - 1
        }else if pageIndex == count + 1{
            pageControl.currentPage = 0
        }else{
            pageControl.currentPage = pageIndex - 1
        }

        if pageIndex > self.pages.count - 1{
            pageIndex = 0
        }
        
        if pageIndex < 0 {
            pageIndex = self.pages.count - 1
        }
        
        //페이지가 하나두 없으면 표시할 달력 패스
        if pages.count <= 0 {
            return
        }
        
        year_label.text = String(Calendar.current.component(.year, from: self.pages[pageIndex].items.last!.date))
        month_label.text = String(Calendar.current.component(.month, from: self.pages[pageIndex].items.last!.date)) + "월"
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
       
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView) {
        
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {

        let pageIndex = Int(scrollView.contentOffset.x/scrollView.frame.width)
        if pageIndex <= 0 {
            next_btn.isEnabled = true
            next_btn.setImage(UIImage(named: "btn_page_next"), for: .normal)
            pre_btn.isEnabled = false
            pre_btn.setImage(UIImage(named: "btn_page_prev_disa"), for: .normal)
        }
        else if pageIndex + 1 >= pageControl.numberOfPages{
            pre_btn.isEnabled = true
            pre_btn.setImage(UIImage(named: "btn_hd_prev"), for: .normal)
            next_btn.isEnabled = false
            next_btn.setImage(UIImage(named: "btn_page_next_disa"), for: .normal)
        }
        else {
            next_btn.isEnabled = true
            next_btn.setImage(UIImage(named: "btn_page_next"), for: .normal)
            pre_btn.isEnabled = true
            pre_btn.setImage(UIImage(named: "btn_hd_prev"), for: .normal)
        }
    }
}
