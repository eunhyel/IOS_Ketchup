//
//  BCItemCell.swift
//
//  Copyright © 2020 Inforex. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class MenuCell : UITableViewCell{
    
    @IBOutlet var name_label: UILabel!
    
    var bag = DisposeBag()

    override func layoutSubviews() {
        super.layoutSubviews()
        initialize()
    }
    
    func initialize(){
        backgroundColor = .clear
    }
}
