//
//  BCItemPage.swift
//  iosClubRadio
//
//  Created by cschoi724 on 2020/04/02.
//  Copyright © 2020 Inforex. All rights reserved.
//

import Foundation
import SwiftyJSON
import Kingfisher
import RxSwift
import RxCocoa

class BCItemPage : XibView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var item_collectionView: UICollectionView!
    
    var items : [DailyModel] = []
    var selection : Int = -1
    var selectItem : (DailyModel) -> Void = {_ in}
    var selectedItem : DailyModel!
    var cancel : () -> Void = {}
    weak var mainView : ViewController!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if isInitailized {
            initialize()
            isInitailized = false
        }
    }
    
    func initialize(){
        setCollectionView()
    }

    func setCollectionView(){
        self.swipeRight.isEnabled = false
        item_collectionView.dataSource = self
        item_collectionView.delegate = self
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.minimumLineSpacing = 10
        collectionViewLayout.minimumInteritemSpacing = 0
        item_collectionView.collectionViewLayout = collectionViewLayout
        item_collectionView.register(UINib(nibName: "BCItemCell", bundle: nil), forCellWithReuseIdentifier: "BCItemCell")
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BCItemCell", for: indexPath) as? BCItemCell else{
            return UICollectionViewCell()
        }
        
        if indexPath.row < 0 {
            return cell
        }
        
        items = items.sorted(by: {$0.date < $1.date})
        
        
        let item = items[indexPath.row]
        

        if self.selection == indexPath.row {
            cell.wasSelected = true
        }else{
            cell.wasSelected = false
        }
        
        cell.day_label.text = String(Calendar.current.component(.day, from: item.date))
        
        
        if item.imageData != nil {     //이미지 데이터가 있으면 이미지 데이터로
            cell.slot_imageView.image = UIImage(data: item.imageData ?? Data())
        }
        else {      //이미지 데이터가 없으니 디폴트 이미지로
            cell.slot_imageView.image = UIImage(named: "img_dafault_0" + String(item.defaultImage))
        }
        
        let tap = UITapGestureRecognizer()
        cell.addGestureRecognizer(tap)
        tap.rx.event            
            .bind{ _ in
                cell.wasSelected = true
                App.module.presenter.addSubview(.visibleView, type: WriteView.self){ view in
                    view.isType = .view
                    view.items = self.items[indexPath.row]
                    view.mainView = self.mainView
                }
            }
        .disposed(by: cell.bag)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = self.frame.width/3.2
        return CGSize(width: width, height: width)
    }
}
