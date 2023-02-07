//
//  ViewController+func.swift
//  dailyApp
//
//  Created by eunhye on 2021/02/26.
//

import Foundation
import UIKit
import SwiftyJSON


extension ViewController {

    
    func createPages(){
        if !App.DayData.isEmpty {
            defult_label.isHidden = true
        }
        
        for subview in page_scrollview.subviews {
            subview.removeFromSuperview()
        }
        
        if !pages.isEmpty {
            pages.removeAll()
        }
        
        
        //날짜순으로 정렬한 뒤에
        App.DayData = App.DayData.sorted(by: {$0.date < $1.date})
        
        //년과 달을 중복되지 않게 갯수를 구한다
        let units: Set<Calendar.Component> = [.month, .year]
        let dateCount = Set(App.DayData.map({Calendar.current.dateComponents(units, from: $0.date)})).sorted(by: {Int($0.year!)*100 + Int($0.month!) < Int($1.year!)*100 + Int($1.month!)})
        
        //log.d(dateCount)
        
        DispatchQueue.main.async {
        //달의 갯수를 넣는다
            self.count = dateCount.count
            
            let scrollViewWidth = UIScreen.main.bounds.width - 30
                self.pageControl.numberOfPages = self.count
                self.page_scrollview.contentSize = CGSize(width: scrollViewWidth * CGFloat(self.count),
                                                          height: self.page_scrollview.frame.height)
                
                self.page_scrollview.contentOffset.x = self.page_scrollview.frame.size.width *  CGFloat(self.count - 1)
                
                if self.count > 1 {
                    self.next_btn.isEnabled = false
                    self.pre_btn.isEnabled = true
                    self.next_btn.setImage(UIImage(named: "btn_page_next_disa"), for: .normal)
                    self.pre_btn.setImage(UIImage(named: "btn_hd_prev"), for: .normal)
                }
                else {
                }
        }
        
        //log.d(dateCount)
        var setIndex = 1
        for row in dateCount {
            let page = getPage(setIndex, date: row)
            self.page_scrollview.addSubview(page)
            self.pages.append(page)
            setIndex += 1
        }
        
        
        if count < 2 {
            pre_btn.setImage(UIImage(named: "btn_page_prev_disa"), for: .normal)
        }
        else {
            pre_btn.setImage(UIImage(named: "btn_hd_prev"), for: .normal)
        }
        
        //페이지 하나면 무한스크롤 안되게
        //if count <= 1 {
        //    page_scrollview.isScrollEnabled = false
        //}
    }
    
    func getPage(_ row : Int, date : DateComponents) -> BCItemPage{
        
        let scrollViewWidth = UIScreen.main.bounds.width - 30
        let pageX = scrollViewWidth * CGFloat(row - 1)
        
        let page = BCItemPage(frame: CGRect(x: pageX,
                                            y: 0,
                                            width: scrollViewWidth,
                                            height: page_scrollview.frame.height))
        
        
        //현재 달력의 날짜 데이터 넣기
        let units: Set<Calendar.Component> = [.month, .year]
        page.items = App.DayData.filter{ Calendar.current.dateComponents(units, from: $0.date) == date}
        
        page.mainView = self
        
        if selectedItem != nil,
            row > 0, row <= count{
            page.items.forEach{
                if $0.id == selectedItem.id {
                    page.selectedItem = selectedItem
                    self.page_scrollview.contentOffset.x = pageX
                    self.pageControl.currentPage = row - 1
                }
            }
        }
        
        page.tag = row
        return page
    }
    
    
    
    func insertCell(_ date : Date){
        defult_label.isHidden = true
        setDataLoad()
        createPages()

        //let pageIndex = Int(page_scrollview.contentOffset.x/page_scrollview.frame.width)
        //pages[pageIndex].items.insert(App.DayData.last!, at: pages[pageIndex].items.count)
        //pages[pageIndex].item_collectionView.reloadData()
        
        /*
        if pages.count == App.DayData.last?.page {
        }
        else {
            setDataLoad()
            createPages()
        }
        
        month_label.text = String(Calendar.current.component(.month, from: App.DayData.last!.date)) + "월"
        year_label.text = String(Calendar.current.component(.year, from: App.DayData.last!.date))
        */
    }
    
    
    func deleteCell(_ item : DailyModel){
        
        let pageIndex = Int(page_scrollview.contentOffset.x/page_scrollview.frame.width)
        App.DayData.removeAll{$0.date == item.date}
        pages[pageIndex].items.removeAll{$0.date == item.date}
        
        if pages[pageIndex].items.isEmpty {
            setDataLoad()
            createPages()
        }
        else {
            pages[pageIndex].item_collectionView.reloadData()
        }
    }
    
    func editCell(_ item : DailyModel, _ editDate : Bool){
        let pageIndex = Int(page_scrollview.contentOffset.x/page_scrollview.frame.width)
        for i in 0..<pages[pageIndex].items.count{
            if editDate {   //날짜를 변경했으면 아이디로 비교해서 교체
                if pages[pageIndex].items[i].id == item.id {
                    pages[pageIndex].items[i] = item
                }
            }
            else {
                if pages[pageIndex].items[i].date == item.date {
                    pages[pageIndex].items[i] = item
                }
            }
        }
        
        pages[pageIndex].item_collectionView.reloadData()
    }
}
