//
//  FilterViewController.swift
//  IntergrateMLModel
//
//  Created by Khanh Vu on 26/03/5 Reiwa.
//

import UIKit
import SnapKit
import AVFoundation
import Vision

protocol CameraProtocol: NSObject {
    func didSendImageCaptured(image: UIImage)
}
class FilterViewController: UIViewController {
    
    private lazy var lbIdentifier: UILabel = {
        let lb = UILabel()
        lb.textColor = .white
        lb.font = UIFont.boldSystemFont(ofSize: 20)
        lb.text = "Identifier"
        lb.textAlignment = .center
        return lb
    }()
    private lazy var lbConfidence: UILabel = {
        let lb = UILabel()
        lb.textColor = .white
        lb.font = UIFont.boldSystemFont(ofSize: 20)
        lb.text = "Confidence"
        lb.textAlignment = .center
        return lb
    }()
    private lazy var stvLabel: UIStackView = {
        let stv = UIStackView()
        [lbIdentifier, lbConfidence].forEach { sub in
            stv.addArrangedSubview(sub)
        }
        stv.distribution = .fillEqually
        stv.axis = .vertical
        stv.alignment = .center
        stv.spacing = 10
        
        return stv
    }()
    private var cameraView: CameraView!
    private var detailView: DetailImageView!
    weak var delegate: CameraProtocol?
    private var imagePicker = UIImagePickerController()

    private var coremlRequest: VNCoreMLRequest?
    let dataDict = ["Agapanthus": "Hoa Bách Tử Liên", "Tansy": "Hoa Cúc", "Bougainvillea": "Hoa Giấy", "Jasmine": "Hoa Nhài"]
    var isCaptured = false
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setUpView()
        predict()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.cameraView.startSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.cameraView.stopSession()
    }
    
    func setUpView() {
        self.view.backgroundColor = UIColor(hexString: "#242121")
        self.cameraView = CameraView(cameraType: .video)
        self.cameraView.delegate = self
        self.cameraView.isHidden = false
        self.detailView = DetailImageView()
        self.detailView.delegate = self
        self.detailView.isHidden = true
        [cameraView, detailView, stvLabel].forEach { sub in
            self.view.addSubview(sub)
        }
        cameraView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.leading.equalTo(self.view.snp.leading)
            make.trailing.equalTo(self.view.snp.trailing)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        detailView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.leading.equalTo(self.view.snp.leading)
            make.trailing.equalTo(self.view.snp.trailing)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        stvLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(60)
        }
        
    }
    
    private func predict() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            
            guard let model = try? VNCoreMLModel(for: FlowerShop(configuration: MLModelConfiguration()).model) else {
                fatalError("Model initilation failed!")
            }
            let coremlRequest = VNCoreMLRequest(model: model) { [weak self] request, error in
                guard let self = self else {
                    return
                }
                DispatchQueue.main.async {
                    if let results = request.results {
                        self.handleRequest(results)
                    }
                }
            }
            coremlRequest.imageCropAndScaleOption = .scaleFill
            self?.coremlRequest = coremlRequest
        }
    }
    
    func handleRequest(_ results: [Any]) {
        if let results = results as? [VNClassificationObservation] {
            print("\(results.first!.identifier) : \(results.first!.confidence)")
            let name = dataDict[results.first!.identifier]
            if results.first!.identifier == "Agapanthus" && results.first!.confidence < 0.9 {
                DispatchQueue.main.async {
                    self.lbIdentifier.text = "Unkown"
                    self.lbConfidence.text = ""
                }
            } else {
                DispatchQueue.main.async {
                    self.lbIdentifier.text = name
                    self.lbConfidence.text = "\(results.first!.confidence)"
                }
            }
        }
    }
    
    func handleCoreml(cvPixel: CVPixelBuffer) {
        DispatchQueue.global().sync {
            guard let coremlRequest = self.coremlRequest else {
                return
            }
            let bufferImage = VNImageRequestHandler(cvPixelBuffer: cvPixel, options: [:])
            
            do {
                try bufferImage.perform([coremlRequest])
            } catch {
                print("cant perform predict: ", error)
            }
        }
    }
}
extension FilterViewController: CameraViewDelegate {
    func didShowAlert(title: String, message: String) {
        self.showAlert(title: title, message: message)
    }
    
    func didShowAlertSetting(title: String, message: String) {
        self.showAlertSetting(title: title, message: message)
    }
    
    func didCapturedImage(imageCaptured: UIImage) {
        DispatchQueue.main.async {
            self.detailView.configImage(image: imageCaptured)
            self.isCaptured = true
            self.detailView.isHidden = false
            self.cameraView.isHidden = true
            DispatchQueue.global().sync {
                guard let coremlRequest = self.coremlRequest else {
                    return
                }
                let bufferImage = VNImageRequestHandler(cgImage: imageCaptured.cgImage!, options: [:])
                
                do {
                    try bufferImage.perform([coremlRequest])
                } catch {
                    print("cant perform predict: ", error)
                }
            }
        }
    }
    
    func btnCancelTapped() {
        self.dismiss(animated: true)
    }
    
    func btnLibraryTapped() {
        self.imagePicker.delegate = self
        self.imagePicker.sourceType = .photoLibrary
        self.isCaptured = true
        present(imagePicker, animated: true, completion: nil)
    }
    func didCaptureFrameVideo(cvPixel: CVPixelBuffer) {
        if !isCaptured {
            DispatchQueue.global().sync {
                guard let coremlRequest = self.coremlRequest else {
                    return
                }
                let bufferImage = VNImageRequestHandler(cvPixelBuffer: cvPixel, options: [:])
                
                do {
                    try bufferImage.perform([coremlRequest])
                } catch {
                    print("cant perform predict: ", error)
                }
            }
        }
    }
    
}

extension FilterViewController: DetailImageViewProtocol {
    func btnSendImageTapped(image: UIImage) {
        self.delegate?.didSendImageCaptured(image: image)
        self.dismiss(animated: true)
    }
    
    func btnCancelImageTapped() {
        self.detailView.isHidden = true
        self.cameraView.isHidden = false
        self.isCaptured = false
    }
    
    func btnDownloadTapped() {
        print("down")
    }

}
extension FilterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let img = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        guard let image = img else {
            return
        }
        self.detailView.configImage(image: image)
        self.detailView.isHidden = false
        self.cameraView.isHidden = true
        DispatchQueue.global().sync {
            guard let coremlRequest = self.coremlRequest else {
                return
            }
            let bufferImage = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
            
            do {
                try bufferImage.perform([coremlRequest])
            } catch {
                print("cant perform predict: ", error)
            }
        }
//        self.imvAvata.image = image

        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

