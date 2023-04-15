//
//  DetailImageViewController.swift
//  FlowerClassification
//
//  Created by Khanh Vu on 30/03/5 Reiwa.
//

import UIKit
import SnapKit

class DetailImageViewController: UIViewController {
    
    private lazy var btnCancel: UIButton = {
        let btn = UIButton()
        btn.setBackgroundImage(UIImage(systemName: "xmark"), for: .normal)
        btn.tintColor = .gray
        btn.addTarget(self, action: #selector(btnCancelTapped), for: .touchUpInside)
        return btn
    }()
    
    private lazy var vTop: UIView = {
        let v = UIView()
        v.addSubview(btnCancel)
        v.backgroundColor = .clear
        return v
    }()
    
    private lazy var cltvListImage: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let cltv = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        cltv.showsHorizontalScrollIndicator = false
        cltv.backgroundColor = .black
        cltv.delegate = self
        cltv.dataSource = self
        cltv.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        cltv.layer.cornerRadius = 20
        cltv.layer.masksToBounds = true
        return cltv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func configureView() {
        [vTop, cltvListImage].forEach { subView in
            self.view.addSubview(subView)
        }
        
        self.vTop.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(40)
        }
        
        self.btnCancel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.width.height.equalTo(40)
            make.centerY.equalToSuperview()
        }
        
        self.cltvListImage.snp.makeConstraints { make in
            make.top.equalTo(self.vTop.snp.bottom).offset(30)
            make.leading.trailing.equalToSuperview().inset(40)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-40)
        }
    }
    
    @objc func btnCancelTapped() {
        self.dismiss(animated: true, completion: nil)
    }

}

extension DetailImageViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return UICollectionViewCell()
    }
    
    
}
