//
//  ViewController.swift
//  Emitter-Swift
//
//  Created by Ilyasa Azmi on 24/05/19.
//  Copyright © 2019 co.ilyasa.azmi. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    var imageView: UIImageView!
    var imageViewDark: UIImageView!
    var gradientLayer = CAGradientLayer()
    let emitterLayer = CAEmitterLayer()
    var currentImage: Int = 10
    var layerBackground: Int = 10
    var player: AVAudioPlayer?
    let notification = UINotificationFeedbackGenerator()
    
    @IBOutlet weak var startSpeechButton: UIButton!
    @IBOutlet weak var detectedTextLabel: UILabel!
    
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    var lang: String = "en-US"

    override func viewDidLoad() {
        super.viewDidLoad()

        gradientLayer.colors = [
            UIColor(red: 84/255, green: 172/255, blue: 210/255, alpha: 1).cgColor,
            UIColor(red: 61/255, green: 140/255, blue: 182/255, alpha: 1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x:0, y:0)
        gradientLayer.endPoint = CGPoint(x:1, y:1)

        gradientLayer.frame = view.bounds

        view.layer.insertSublayer(gradientLayer, at: 0)
        
        buihWater()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(clickView(_:)))
        tapGesture.delegate = self as? UIGestureRecognizerDelegate
        view.addGestureRecognizer(tapGesture)

        playSoundFunc(resource: "Bubbles")
        
        startSpeechButton.isEnabled = false  //2
        speechRecognizer?.delegate = self as? SFSpeechRecognizerDelegate  //3
        speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: lang))
        SFSpeechRecognizer.requestAuthorization { (authStatus) in  //4
            
            var isButtonEnabled = false
            
            switch authStatus {  //5
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation() {
                self.startSpeechButton.isEnabled = isButtonEnabled
            }
        }
    }
    
    @objc func clickView(_ sender: UIView) {
        if currentImage == 10 {
            setImage(image1: "mozart-crystal", image2: "mozart-dark")
            currentImage = 0
            showCrystal(image: "mozart-crystal", resources: "Mozart-symphony-40")
        } else if currentImage == 0 {
            transitionImage(image1: "beethoven-crystal", image2: "beethoven-dark")
            currentImage = 1
            showCrystal(image: "beethoven-crystal", resources: "beethoven")
        } else if currentImage == 1 {
            transitionImage(image1: "heavy_metal-crystal", image2: "heavy_metal-dark")
            currentImage = 2
            showCrystal(image: "heavy_metal-crystal", resources: "heavy_metal_thunder")
            UIDevice.vibrate()
        } else if currentImage == 2 {
            transitionImage(image1: "stupid", image2: "stupid-dark")
            currentImage = 3
            showCrystal(image: "stupid", resources: "noise")
            UIDevice.vibrate()
        } else if currentImage == 3 {
            transitionImage(image1: "setan-crystal", image2: "setan-dark")
            currentImage = 4
            showCrystal(image: "setan-crystal", resources: "hell")
            UIDevice.vibrate()
        } else if currentImage == 4 {
            transitionImage(image1: "mozart-crystal", image2: "mozart-dark")
            currentImage = 0
            showCrystal(image: "mozart-crystal", resources: "Mozart-symphony-40")
        } 
    }
    
    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if currentImage == 10 {
            setImage(image1: "mozart-crystal", image2: "mozart-dark")
            currentImage = 0
            showCrystal(image: "mozart-crystal", resources: "Mozart-symphony-40")
        } else if currentImage == 0 {
            transitionImage(image1: "beethoven-crystal", image2: "beethoven-dark")
            currentImage = 1
            showCrystal(image: "beethoven-crystal", resources: "beethoven")
        } else if currentImage == 1 {
            transitionImage(image1: "heavy_metal-crystal", image2: "heavy_metal-dark")
            currentImage = 2
            showCrystal(image: "heavy_metal-crystal", resources: "heavy_metal_thunder")
        } else if currentImage == 2 {
            transitionImage(image1: "stupid", image2: "stupid-dark")
            currentImage = 3
            showCrystal(image: "stupid", resources: "noise")
            UIDevice.vibrate()
        } else if currentImage == 3 {
            transitionImage(image1: "setan-crystal", image2: "setan-dark")
            currentImage = 4
            showCrystal(image: "setan-crystal", resources: "hell")
            UIDevice.vibrate()
        } else if currentImage == 4 {
            transitionImage(image1: "mozart-crystal", image2: "mozart-dark")
            currentImage = 0
            showCrystal(image: "mozart-crystal", resources: "Mozart-symphony-40")
        }
    }
    
    @IBAction func startSpeechButton(_ sender: Any) {
        speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: lang))
        
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            startSpeechButton.isEnabled = false
            startSpeechButton.setTitle("Start Recording", for: .normal)
        } else {
            startRecording()
            startSpeechButton.setTitle("Stop Recording", for: .normal)
        }
    }
    
    func startRecording() {
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category(rawValue: convertFromAVAudioSessionCategory(AVAudioSession.Category.record)))
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            if let result = result {
                
                self.detectedTextLabel.text = result.bestTranscription.formattedString
                let bestString = self.detectedTextLabel.text

                isFinal = (result.isFinal)
                
                var lastString: String = ""
                for segment in result.bestTranscription.segments {
                    let indexTo = bestString!.index(bestString!.startIndex, offsetBy: segment.substringRange.location)
                    lastString = (bestString?.substring(from: indexTo))!
                }
                self.checkRecognizeSpeech(resultImage: lastString)
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.startSpeechButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        detectedTextLabel.text = "Say something, I'm listening!"
        
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            startSpeechButton.isEnabled = true
        } else {
            startSpeechButton.isEnabled = false
        }
    }
    
    func checkRecognizeSpeech(resultImage: String){
        switch resultImage {
        case "Mozart's":
            if currentImage == 10 {
                setImage(image1: "mozart-crystal", image2: "mozart-dark")
            } else {
                transitionImage(image1: "mozart-crystal", image2: "mozart-dark")
            }
            currentImage = 0
            showCrystal(image: "mozart-crystal", resources: "Mozart-symphony-40")
            break
        case "Mozart":
            if currentImage == 10 {
                setImage(image1: "mozart-crystal", image2: "mozart-dark")
            } else {
                transitionImage(image1: "mozart-crystal", image2: "mozart-dark")
            }
            currentImage = 0
            showCrystal(image: "mozart-crystal", resources: "Mozart-symphony-40")
            break
        case "Beethoven":
            if currentImage == 10 {
                setImage(image1: "beethoven-crystal", image2: "beethoven-dark")
            } else {
                transitionImage(image1: "beethoven-crystal", image2: "beethoven-dark")
            }
            currentImage = 1
            showCrystal(image: "beethoven-crystal", resources: "beethoven")
            break
        case "Metal":
            if currentImage == 10 {
                setImage(image1: "heavy_metal-crystal", image2: "heavy_metal-dark")
            } else {
                transitionImage(image1: "heavy_metal-crystal", image2: "heavy_metal-dark")
            }
            currentImage = 2
            showCrystal(image: "heavy_metal-crystal", resources: "heavy_metal_thunder")
            break
        case "Stupid":
            if currentImage == 10 {
                setImage(image1: "stupid", image2: "stupid-dark")
            } else {
                transitionImage(image1: "stupid", image2: "stupid-dark")
            }
            currentImage = 3
            showCrystal(image: "stupid", resources: "noise") //sementara
            break
        case "Devil":
            if currentImage == 10 {
                setImage(image1: "setan-crystal", image2: "setan-dark")
            } else {
                transitionImage(image1: "setan-crystal", image2: "setan-dark")
            }
            currentImage = 4
            showCrystal(image: "setan-crystal", resources: "hell")
            break
        default: break
        }
    }
    
    func setImage(image1: String, image2: String){
        showImage(imageName: image1)
        showImageDark(imageName: image2)
    }
    
    func transitionImage(image1: String, image2: String){
        let toImage = UIImage(named: image1)
        UIView.transition(with: self.imageView,
                          duration:5,
                          options: .transitionCrossDissolve,
                          animations: { self.imageView.image = toImage },
                          completion: nil)
        let toImageDark = UIImage(named: image2)
        UIView.transition(with: self.imageViewDark,
                          duration:5,
                          options: .transitionCrossDissolve,
                          animations: { self.imageViewDark.image = toImageDark },
                          completion: nil)
    }
    
    func showCrystal(image: String, resources: String){
        gradientLayerBackground()
        animateCrystal()
        animateCrystalDark()
        crystalKecil(gambar: image)
        playSoundFunc(resource: resources)
        shinyGradientLayer()
        notification.notificationOccurred(.success)
    }
    
    func animateCrystal(){
        let startPoint = CGPoint(x: 200, y: 200)
        let endPoint = CGPoint(x: 275, y: 275)
        let duration: Double = 10.0
        
        let positionAnimation = constructPostionAnimation(startingPoint: startPoint, endPoint: endPoint, animationDuration: duration)
        
        imageView.layer.add(positionAnimation, forKey: "position")
        
        let scaleAnimation = constructScaleAnimation(startingScale: 0.2, endingScale: 1.0, animationDuration: 2.5)
        
        imageView.layer.add(scaleAnimation, forKey: "scale")
        
        let rotationAnimation = constructRotateAnimation(animationDuration: 4.5)
        imageView.layer.add(rotationAnimation, forKey: "rotate")
        
        let opacityFadeAnimation = constructOpacityAnimation(startingOpacity: 0.1, endingOpacity: 1.0, animationDuration: 2.5)
        imageView.layer.add(opacityFadeAnimation, forKey: "opacity")
        
    }
    
    func animateCrystalDark(){
        let startPoint = CGPoint(x: 200, y: 200)
        let endPoint = CGPoint(x: 275, y: 275)
        let duration: Double = 10.0
        
        let positionAnimation = constructPostionAnimation(startingPoint: startPoint, endPoint: endPoint, animationDuration: duration)
        
        imageViewDark.layer.add(positionAnimation, forKey: "position")
        
        let scaleAnimation = constructScaleAnimation(startingScale: 0.2, endingScale: 1.0, animationDuration: 2.5)
        
        imageViewDark.layer.add(scaleAnimation, forKey: "scale")
        
        let rotationAnimation = constructRotateAnimation(animationDuration: 4.5)
        imageViewDark.layer.add(rotationAnimation, forKey: "rotate")
        
        let opacityFadeAnimation = constructOpacityAnimation(startingOpacity: 0.1, endingOpacity: 1.0, animationDuration: 2.5)
        imageViewDark.layer.add(opacityFadeAnimation, forKey: "opacity")
        
    }
    
    func crystalKecil(gambar: String) {
        emitterLayer.emitterPosition = CGPoint(x: 220, y: 320)
        let cell = CAEmitterCell()
        cell.scale = 0.05
        cell.scaleRange = 0.3
        cell.birthRate = 2
        cell.lifetime = 10
        cell.velocity = 100
        
        cell.emissionRange = CGFloat.pi * 2.0

        cell.contents = UIImage(named: gambar)!.cgImage
        emitterLayer.emitterCells = [cell]
        
        view.layer.addSublayer(emitterLayer)
    }
    
    func buihWater(){
        let flakeEmitterCell = CAEmitterCell()
        flakeEmitterCell.contents = UIImage(named: "bubble")?.cgImage
        flakeEmitterCell.scale = 0.03
        flakeEmitterCell.scaleRange = 0.1
        flakeEmitterCell.emissionRange = .pi
        flakeEmitterCell.lifetime = 20.0
        flakeEmitterCell.birthRate = 10
        flakeEmitterCell.velocity = -30
        flakeEmitterCell.velocityRange = -20
        flakeEmitterCell.yAcceleration = 5
        flakeEmitterCell.xAcceleration = 5
        flakeEmitterCell.spin = -0.5
        flakeEmitterCell.spinRange = 1.0
        
        let snowEmitterLayer = CAEmitterLayer()
        snowEmitterLayer.emitterPosition = CGPoint(x: view.bounds.width / 2.0, y: -50)
        snowEmitterLayer.emitterSize = CGSize(width: view.bounds.width, height: 0)
        snowEmitterLayer.emitterShape = CAEmitterLayerEmitterShape.line
        snowEmitterLayer.beginTime = CACurrentMediaTime()
        snowEmitterLayer.timeOffset = 10
        snowEmitterLayer.emitterCells = [flakeEmitterCell]
        
        view.layer.addSublayer(snowEmitterLayer)
    }
    
    func showImage(imageName: String){
        imageView = UIImageView(image: UIImage(named: imageName))
        imageView.frame = CGRect(x: 100, y: 200, width: 200, height: 230)
        view.addSubview(imageView)
    }
    func showImageDark(imageName: String){
        imageViewDark = UIImageView(image: UIImage(named: imageName))
        imageViewDark.frame = CGRect(x: 100, y: 200, width: 200, height: 230)
        view.addSubview(imageViewDark)
    }
    
    func gradientLayerBackground(){
        let gradientChangeAnimation = CABasicAnimation(keyPath: "colors")
        gradientChangeAnimation.duration = 5.0
        
        let color10 = [
            UIColor(red: 84/255, green: 172/255, blue: 210/255, alpha: 1).cgColor,
            UIColor(red: 61/255, green: 140/255, blue: 182/255, alpha: 1).cgColor
        ]
        
        let color0 = [
            UIColor(red: 52/255, green: 152/255, blue: 219/255, alpha: 1).cgColor,
            UIColor(red: 22/255, green: 75/255, blue: 111/255, alpha: 1).cgColor
        ]
        
        let color1 = [
            UIColor(red: 24/255, green: 188/255, blue: 155/255, alpha: 1).cgColor,
            UIColor(red: 4/255, green: 165/255, blue: 130/255, alpha: 1).cgColor
        ]
        
        let color2 = [
            UIColor(red: 163/255, green: 143/255, blue: 131/255, alpha: 1).cgColor,
            UIColor(red: 117/255, green: 112/255, blue: 107/255, alpha: 1).cgColor
        ]
        
        let color3 = [
            UIColor(red: 112/255, green: 112/255, blue: 112/255, alpha: 1).cgColor,
            UIColor(red: 81/255, green: 81/255, blue: 81/255, alpha: 1).cgColor
        ]
        
        let color4 = [
            UIColor(red: 139/255, green: 27/255, blue: 25/255, alpha: 1).cgColor,
            UIColor(red: 148/255, green: 2/255, blue: 0/255, alpha: 1).cgColor
        ]
        
        if currentImage == 0 {
            if layerBackground == 10 {
                gradientChangeAnimation.fromValue = color10
                gradientChangeAnimation.toValue = color0
            } else if layerBackground == 1 {
                gradientChangeAnimation.fromValue = color1
                gradientChangeAnimation.toValue = color0
            } else if layerBackground == 2 {
                gradientChangeAnimation.fromValue = color2
                gradientChangeAnimation.toValue = color0
            } else if layerBackground == 3 {
                gradientChangeAnimation.fromValue = color3
                gradientChangeAnimation.toValue = color0
            } else if layerBackground == 4 {
                gradientChangeAnimation.fromValue = color4
                gradientChangeAnimation.toValue = color0
            }
            layerBackground = 0
            
        } else if currentImage == 1 {
            if layerBackground == 10 {
                gradientChangeAnimation.fromValue = color10
                gradientChangeAnimation.toValue = color1
            } else if layerBackground == 0 {
                gradientChangeAnimation.fromValue = color0
                gradientChangeAnimation.toValue = color1
            } else if layerBackground == 2  {
                gradientChangeAnimation.fromValue = color2
                gradientChangeAnimation.toValue = color1
            } else if layerBackground == 3 {
                gradientChangeAnimation.fromValue = color3
                gradientChangeAnimation.toValue = color1
            } else if layerBackground == 4 {
                gradientChangeAnimation.fromValue = color4
                gradientChangeAnimation.toValue = color1
            }
            layerBackground = 1
        } else if currentImage == 2 {
            if layerBackground == 10 {
                gradientChangeAnimation.fromValue = color10
                gradientChangeAnimation.toValue = color2
            } else if layerBackground == 0 {
                gradientChangeAnimation.fromValue = color0
                gradientChangeAnimation.toValue = color2
            } else if layerBackground == 1 {
                gradientChangeAnimation.fromValue = color1
                gradientChangeAnimation.toValue = color2
            } else if layerBackground == 3 {
                gradientChangeAnimation.fromValue = color3
                gradientChangeAnimation.toValue = color2
            } else if layerBackground == 4 {
                gradientChangeAnimation.fromValue = color4
                gradientChangeAnimation.toValue = color2
            }
            layerBackground = 2
        } else if currentImage == 3 {
            if layerBackground == 10 {
                gradientChangeAnimation.fromValue = color10
                gradientChangeAnimation.toValue = color3
            } else if layerBackground == 0 {
                gradientChangeAnimation.fromValue = color0
                gradientChangeAnimation.toValue = color3
            } else if layerBackground == 1 {
                gradientChangeAnimation.fromValue = color1
                gradientChangeAnimation.toValue = color3
            } else if layerBackground == 2 {
                gradientChangeAnimation.fromValue = color2
                gradientChangeAnimation.toValue = color3
            } else if layerBackground == 4 {
                gradientChangeAnimation.fromValue = color4
                gradientChangeAnimation.toValue = color3
            }
            layerBackground = 3
        } else if currentImage == 4 {
            if layerBackground == 10 {
                gradientChangeAnimation.fromValue = color10
                gradientChangeAnimation.toValue = color4
            } else if layerBackground == 0 {
                gradientChangeAnimation.fromValue = color0
                gradientChangeAnimation.toValue = color4
            } else if layerBackground == 1 {
                gradientChangeAnimation.fromValue = color1
                gradientChangeAnimation.toValue = color4
            } else if layerBackground == 2 {
                gradientChangeAnimation.fromValue = color2
                gradientChangeAnimation.toValue = color4
            } else if layerBackground == 3 {
                gradientChangeAnimation.fromValue = color3
                gradientChangeAnimation.toValue = color4
            }
            layerBackground = 4
        }
        
        gradientChangeAnimation.fillMode = CAMediaTimingFillMode.forwards
        gradientChangeAnimation.isRemovedOnCompletion = false
        gradientLayer.add(gradientChangeAnimation, forKey: "colorChange")
    }
    
    func shinyGradientLayer(){
        let shinyGradientLayer = CAGradientLayer()
        shinyGradientLayer.colors = [UIColor.white.cgColor, UIColor.clear.cgColor]
        shinyGradientLayer.locations = [0, 1]
        shinyGradientLayer.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 400)
        
        let angle = 45 * CGFloat.pi / 180
        shinyGradientLayer.transform = CATransform3DMakeRotation(angle, 0, 0, 1)
        
        //animation
        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.duration = 1.5
        animation.fromValue = -view.frame.width
        animation.toValue = view.frame.width
        animation.repeatCount = Float.infinity
        
        shinyGradientLayer.add(animation, forKey: "doesn't matter just key")
        
        imageView.layer.mask = shinyGradientLayer
    }
    
    private func constructOpacityAnimation(startingOpacity: CGFloat, endingOpacity: CGFloat, animationDuration: Double) -> CABasicAnimation{
        let opacityFadeAnimation = CABasicAnimation(keyPath: "opacity")
        opacityFadeAnimation.fromValue = startingOpacity
        opacityFadeAnimation.toValue = endingOpacity
        opacityFadeAnimation.duration = animationDuration * 2
        opacityFadeAnimation.autoreverses = true
        opacityFadeAnimation.repeatCount = Float.infinity
        
        return opacityFadeAnimation
    }
    
    private func constructRotateAnimation(animationDuration: Double) -> CABasicAnimation{
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.fromValue = 0
        rotationAnimation.toValue = Double.pi * 2
        rotationAnimation.duration = animationDuration * 2
        rotationAnimation.repeatCount = Float.infinity
        
        return rotationAnimation
    }
    
    private func constructScaleAnimation(startingScale: CGFloat, endingScale: CGFloat, animationDuration: Double) -> CABasicAnimation{
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = startingScale
        scaleAnimation.toValue = endingScale
        scaleAnimation.duration = animationDuration * 2
        scaleAnimation.autoreverses = true
        scaleAnimation.repeatCount = Float.infinity
        
        return scaleAnimation
    }
    
    private func constructPostionAnimation(startingPoint: CGPoint, endPoint: CGPoint, animationDuration: Double) -> CABasicAnimation{
        let positionAnimation = CABasicAnimation(keyPath: "position")
        positionAnimation.fromValue = NSValue(cgPoint: startingPoint)
        positionAnimation.toValue = NSValue(cgPoint: endPoint)
        positionAnimation.duration = animationDuration
        positionAnimation.autoreverses = true
        positionAnimation.repeatCount = Float.infinity
        
        positionAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        
        return positionAnimation
    }
    
    func playSoundFunc(resource: String) {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "mp3") else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            guard let player = player else { return }
            
            player.play()
            player.numberOfLoops = -1
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
}

extension UIDevice {
    static func vibrate() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}

fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
    return input.rawValue
}
