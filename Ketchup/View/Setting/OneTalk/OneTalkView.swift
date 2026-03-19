//
//
//  Copyright © 2020 Inforex. All rights reserved.
//

import Foundation
import SwiftyJSON
import RxSwift
import RxCocoa
import CoreData

class OneTalkView: XibView{
    
    @IBOutlet weak var close_btn: UIButton!

    
    let bag = DisposeBag()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if isInitailized {
            isInitailized = false
            initialize()
        }
    }

    func initialize(){
        setView()
        bind()
    }
    
    func setView(){
        self.backgroundColor = UIColor(patternImage: UIImage(named: Global.backgroundImage)!)
    }
    
    func bind(){
        close_btn.rx.tap
            .bind { (_) in
                self.removeFromSuperview()
        }.disposed(by: bag)
    }
}

