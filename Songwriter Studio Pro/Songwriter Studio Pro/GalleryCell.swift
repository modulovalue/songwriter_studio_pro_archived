//
//  GalleryCell.swift
//  SongwriterStudioPro
//
//  Created by Modestas Valauskas on 12.12.17.
//  Copyright © 2017 MV. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class GalleryCell: UITableViewCell {

    private let disposeBag = DisposeBag()

    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var lengthLbl: UILabel!

    @IBOutlet weak var shareBtn: UIButton!
    @IBOutlet weak var openBtn: UIButton!
    @IBOutlet weak var deleteBtn: UIButton!

    func set(name: String,
             length: String,
             share: @escaping () -> Void,
             open: @escaping () -> Void,
             delete: @escaping () -> Void) {
        nameLbl.text = name
        lengthLbl.text = length

        shareBtn.rx.tap.subscribe({ btn in
            share()
        }).disposed(by: disposeBag)

        openBtn.rx.tap.subscribe({ btn in
            open()
        }).disposed(by: disposeBag)

        deleteBtn.rx.tap.subscribe({ btn in
            delete()
        }).disposed(by: disposeBag)
    }

}
