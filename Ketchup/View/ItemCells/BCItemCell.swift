//
//  BCItemCell.swift
//  iosClubRadio
//
//  Created by cschoi724 on 2020/04/02.
//  Copyright © 2020 Inforex. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class BCItemCell : UICollectionViewCell{
    
    @IBOutlet weak var slot_imageView: UIImageView!
    @IBOutlet weak var day_label: UILabel!
    @IBOutlet weak var selectedView: UIView!
    
    var bag = DisposeBag()
    var wasSelected = false

    override func layoutSubviews() {
        super.layoutSubviews()
        initialize()
    }
    
    func initialize(){
        if wasSelected {
            selectedView.isHidden = false
        }else{
            selectedView.isHidden = true
        }
        
        labelShadow()
    }
    
    func labelShadow(){
        day_label.layer.shadowColor = UIColor.black.cgColor
        day_label.layer.shadowRadius = 3.0
        day_label.layer.shadowOpacity = 1.0
        day_label.layer.shadowOffset = CGSize(width: 3, height: 3)
        day_label.layer.masksToBounds = false
    }
    

    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()
    }
}


