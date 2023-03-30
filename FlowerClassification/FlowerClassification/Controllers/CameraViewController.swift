//
//  CameraViewController.swift
//  FlowerClassification
//
//  Created by Khanh Vu on 30/03/5 Reiwa.
//

import Foundation
//
//  ViewController.swift
//  IntergrateMLModel
//
//  Created by Khanh Vu on 24/03/5 Reiwa.
//

import UIKit
import SnapKit
import AVFoundation

class CameraViewController: UIViewController {
    var session: AVCaptureSession!
    var previewLayer : AVCaptureVideoPreviewLayer!
    var photoOutput : AVCapturePhotoOutput!
    var videoOutput: AVCaptureVideoDataOutput!
    var deviceInput: AVCaptureInput!
    var videoDeviceInput: AVCaptureDeviceInput!
    
    private var isCapture = false
    private let sessionQueue = DispatchQueue(label: "session queue")// Communicate with the session and other session objects on this queue.
    private var setupResult: SessionSetupResult = .success
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera], mediaType: .video, position: .unspecified)
    
    
    private lazy var vPreviewVideo: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 15
        v.layer.masksToBounds = true
        v.backgroundColor = .white
        return v
    }()
    
    private lazy var btnSwitchCamera: UIButton = {
        let btn = UIButton()
        btn.backgroundColor = .clear
        btn.addTarget(self, action: #selector(changeCamera), for: .touchUpInside)
        btn.setBackgroundImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera"), for: .normal)
        btn.tintColor = .white
        return btn
    }()
    
    private lazy var btnCapture: CustomCaptureButton = {
        let vCapture = CustomCaptureButton(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        vCapture.btn.addTarget(self, action: #selector(captureImage), for: .touchUpInside)
        return vCapture
    }()
    
    private var vOverlay: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.orange.cgColor
        return v
    }()
    
    private lazy var imvPreviewImage: UIImageView = {
        let imv = UIImageView()
        imv.isHidden = true
        imv.layer.cornerRadius = 20
        imv.layer.masksToBounds = true
        return imv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configView()
        // Do any additional setup after loading the view.
        self.checkPermissions()
        
        sessionQueue.async {
            self.configureSession()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.startSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.stopSession()
    }
    
    func configView() {
        self.view.backgroundColor = UIColor(hexString: "#242121")
        [self.vPreviewVideo, self.btnSwitchCamera, self.btnCapture].forEach { subView in
            self.view.addSubview(subView)
        }
        self.vPreviewVideo.snp.makeConstraints { make in
            make.height.equalTo(self.view.snp.width).multipliedBy(1.5)
            make.centerX.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview().inset(10)
        }
        self.btnCapture.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.height.equalTo(60)
            make.bottom.equalToSuperview().offset(-60)
        }
        self.btnSwitchCamera.snp.makeConstraints { make in
            make.width.equalTo(40)
            make.height.equalTo(30)
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalTo(self.btnCapture.snp.centerY)
        }
        
        //        self.btnCapture.layer.cornerRadius = 30
        //        self.btnCapture.vCenter.layer.cornerRadius = 24
        
    }
    
    private func configureSession() {
        if setupResult != .success {
            return
        }
        self.session = AVCaptureSession()
        
        self.session.beginConfiguration()
        
        /*
         We do not create an AVCaptureMovieFileOutput when setting up the session because the
         AVCaptureMovieFileOutput does not support movie recording with AVCaptureSession.Preset.Photo.
         */
        self.session.sessionPreset = .high
        
        // Add video input.
        self.setUpCamera()
        
        DispatchQueue.main.async {
            self.setUpPreviewLayer()
        }
        self.setupVideoOutput()
        self.session.commitConfiguration()
    }
    
    func startSession() {
        sessionQueue.async {
            switch self.setupResult {
            case .success:
                // Only setup observers and start the session running if setup succeeded.
                self.session.startRunning()
            case .notAuthorized:
                DispatchQueue.main.async {
                    let changePrivacySetting = "AVCam doesn't have permission to use the camera, please change privacy settings"
                    let message = NSLocalizedString(changePrivacySetting, comment: "Alert message when the user has denied access to the camera")
                    let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                            style: .cancel,
                                                            handler: nil))
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"),
                                                            style: .`default`,
                                                            handler: { _ in
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                    }))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            case .configurationFailed:
                DispatchQueue.main.async {
                    let alertMsg = "Alert message when something goes wrong during capture session configuration"
                    let message = NSLocalizedString("Unable to capture media", comment: alertMsg)
                    let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                            style: .cancel,
                                                            handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
        
    }
    
    func stopSession() {
        sessionQueue.async {
            if self.setupResult == .success {
                self.session.stopRunning()
            }
        }
    }
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // The user has previously granted access to the camera.
            break
        case .notDetermined:
            /*
             The user has not yet been presented with the option to grant
             video access. We suspend the session queue to delay session
             setup until the access request has completed.
             
             Note that audio access will be implicitly requested when we
             create an AVCaptureDeviceInput for audio during session setup.
             */
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })
            
        default:
            // The user has previously denied access.
            setupResult = .notAuthorized
        }
    }
    
    func setUpCamera() {
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            // Choose the back dual camera if available, otherwise default to a wide angle camera.
            if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                // If the back dual camera is not available, default to the back wide angle camera.
                defaultVideoDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                /*
                 In some cases where users break their phones, the back wide angle camera is not available.
                 In this case, we should default to the front wide angle camera.
                 */
                defaultVideoDevice = frontCameraDevice
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: defaultVideoDevice!)
            
            if self.session.canAddInput(videoDeviceInput) {
                self.session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                //                DispatchQueue.main.async {
                //                    /*
                //                        Why are we dispatching this to the main queue?
                //                        Because AVCaptureVideoPreviewLayer is the backing layer for PreviewView and UIView
                //                        can only be manipulated on the main thread.
                //                        Note: As an exception to the above rule, it is not necessary to serialize video orientation changes
                //                        on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                //
                //                        Use the status bar orientation as the initial video orientation. Subsequent orientation changes are
                //                        handled by CameraViewController.viewWillTransition(to:with:).
                //                    */
                //                    let statusBarOrientation = UIApplication.shared.statusBarOrientation
                //                    var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
                //                    if statusBarOrientation != .unknown {
                //                        if let videoOrientation = AVCaptureVideoOrientation(interfaceOrientation: statusBarOrientation) {
                //                            initialVideoOrientation = videoOrientation
                //                        }
                //                    }
                //
                //                    self.previewLayer.connection?.videoOrientation = initialVideoOrientation
                //                }
            } else {
                print("Could not add video device input to the session")
                setupResult = .configurationFailed
                self.session.commitConfiguration()
                return
            }
        } catch {
            print("Could not create video device input: \(error)")
            self.setupResult = .configurationFailed
            self.session.commitConfiguration()
            return
        }
    }
    
    
    func setUpPreviewLayer() {
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        self.previewLayer.videoGravity = .resizeAspectFill
        self.vPreviewVideo.layer.insertSublayer(self.previewLayer, above: self.vPreviewVideo.layer)
        self.previewLayer.frame = self.vPreviewVideo.bounds
        self.vPreviewVideo.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapHandleFocus)))
    }
    
    func setupVideoOutput(){
        self.videoOutput = AVCaptureVideoDataOutput()
        let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInteractive)
        self.videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        if self.session.canAddOutput(self.videoOutput) {
            self.session.addOutput(self.videoOutput)
        } else {
            print("could not add video output")
            self.setupResult = .configurationFailed
            self.session.commitConfiguration()
        }
        self.videoOutput.connections.first?.videoOrientation = .portrait
    }
    
    func setUpPhotoOutput() {
        self.photoOutput = AVCapturePhotoOutput()
        if self.session.canAddOutput(self.photoOutput) {
            self.session.addOutput(self.photoOutput)
            
            self.photoOutput.isHighResolutionCaptureEnabled = true
            self.photoOutput.isLivePhotoCaptureEnabled = self.photoOutput.isLivePhotoCaptureSupported
            self.photoOutput.isDepthDataDeliveryEnabled = self.photoOutput.isDepthDataDeliverySupported
            
        } else {
            print("Could not add photo output to the session")
            self.setupResult = .configurationFailed
            self.session.commitConfiguration()
            return
        }
    }
    
    @objc func tapHandleFocus(_ gestureRecognizer: UITapGestureRecognizer) {
        self.addSquareWhenTapFocus(gestureRecognizer)
        let devicePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: gestureRecognizer.location(in: gestureRecognizer.view))
        focus(with: .autoFocus, exposureMode: .autoExpose, at: devicePoint, monitorSubjectAreaChange: true)
        
    }
    
    @objc func changeCamera() {
        sessionQueue.async {
            let currentVideoDevice = self.videoDeviceInput.device
            let currentPosition = currentVideoDevice.position
            
            let preferredPosition: AVCaptureDevice.Position
            let preferredDeviceType: AVCaptureDevice.DeviceType
            
            switch currentPosition {
            case .unspecified, .front:
                preferredPosition = .back
                preferredDeviceType = .builtInDualCamera
                
            case .back:
                preferredPosition = .front
                preferredDeviceType = .builtInWideAngleCamera
            }
            
            let devices = self.videoDeviceDiscoverySession.devices
            var newVideoDevice: AVCaptureDevice? = nil
            
            // First, look for a device with both the preferred position and device type. Otherwise, look for a device with only the preferred position.
            if let device = devices.first(where: { $0.position == preferredPosition && $0.deviceType == preferredDeviceType }) {
                newVideoDevice = device
            } else if let device = devices.first(where: { $0.position == preferredPosition }) {
                newVideoDevice = device
            }
            
            if let videoDevice = newVideoDevice {
                do {
                    let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                    
                    self.session.beginConfiguration()
                    
                    // Remove the existing device input first, since using the front and back camera simultaneously is not supported.
                    self.session.removeInput(self.videoDeviceInput)
                    
                    if self.session.canAddInput(videoDeviceInput) {
                        self.session.addInput(videoDeviceInput)
                        self.videoDeviceInput = videoDeviceInput
                    } else {
                        self.session.addInput(self.videoDeviceInput)
                    }
                    
                    /*
                     Set Live Photo capture and depth data delivery if it is supported. When changing cameras, the
                     `livePhotoCaptureEnabled and depthDataDeliveryEnabled` properties of the AVCapturePhotoOutput gets set to NO when
                     a video device is disconnected from the session. After the new video device is
                     added to the session, re-enable them on the AVCapturePhotoOutput if it is supported.
                     */
                    //                    self.photoOutput.isLivePhotoCaptureEnabled = self.photoOutput.isLivePhotoCaptureSupported
                    //                    self.photoOutput.isDepthDataDeliveryEnabled = self.photoOutput.isDepthDataDeliverySupported
                    self.videoOutput.connections.first?.videoOrientation = .portrait

                    self.session.commitConfiguration()
                } catch {
                    print("Error occured while creating video device input: \(error)")
                }
            }
        }
    }
    
    @objc func captureImage() {
        print("capture")
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut) {
            self.btnCapture.layer.borderWidth = 10
            self.isCapture = true
        } completion: { _ in
            self.btnCapture.layer.borderWidth = 6
        }
        
    }
    
    private func focus(with focusMode: AVCaptureDevice.FocusMode, exposureMode: AVCaptureDevice.ExposureMode, at devicePoint: CGPoint, monitorSubjectAreaChange: Bool) {
        sessionQueue.async {
            let device = self.videoDeviceInput.device
            do {
                try device.lockForConfiguration()
                
                /*
                 Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
                 Call set(Focus/Exposure)Mode() to apply the new point of interest.
                 */
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                    device.focusPointOfInterest = devicePoint
                    device.focusMode = focusMode
                }
                
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                    device.exposurePointOfInterest = devicePoint
                    device.exposureMode = exposureMode
                }
                
                device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                device.unlockForConfiguration()
            } catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }
    
    func convertToUIImage(pixelBuffer: CVPixelBuffer) -> UIImage {
        let image = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        guard let cameraImage = context.createCGImage(image, from: image.extent) else { return UIImage() }
        // return UIImage(cgImage: cameraImage).aspectFittedToHeight(self.stepperControl.value*0.01*Double(cameraImage.height))
        return UIImage(cgImage: cameraImage)
    }
    
    func addSquareWhenTapFocus(_ recognizer: UITapGestureRecognizer) {
        self.vOverlay.transform = .identity
        self.vOverlay.removeFromSuperview()
        let tapLocation = recognizer.location(in: view)
//        vOverlay.center = tapLocation
        self.view.addSubview(self.vOverlay)
        self.vOverlay.snp.makeConstraints { make in
            make.width.height.equalTo(160)
            make.centerX.equalTo(tapLocation.x)
            make.centerY.equalTo(tapLocation.y)
        }
                
        UIView.animate(withDuration: 0.3) {
            self.vOverlay.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.vOverlay.removeFromSuperview()
            self.vOverlay.transform = .identity
        }
    }
    
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if self.isCapture {
            self.isCapture = false
            guard let cvPixel = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                return
            }
            let image = convertToUIImage(pixelBuffer: cvPixel)
            let aspectRatio = image.size.height / image.size.width
            self.updateImagePreviewWhenCaptured(with: image, ratio: aspectRatio)
        }
        
        
    }
}
extension CameraViewController {
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    func updateImagePreviewWhenCaptured(with image: UIImage, ratio: CGFloat) {
        DispatchQueue.main.async {
            self.view.addSubview(self.imvPreviewImage)
            self.imvPreviewImage.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(20)
                make.bottom.equalTo(self.vPreviewVideo.snp.bottom).offset(-10)
                make.width.equalTo(120)
                make.height.equalTo(120 * ratio)
                print("ratio", ratio)

            }
            self.imvPreviewImage.image = image
            self.imvPreviewImage.isHidden = false
            
//            DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
//                self.imvPreviewImage.removeFromSuperview()
//            })
        }
    }
}
