//
//  ViewController.swift
//  VideoExporter
//
//  Created by Igor Zinovev on 27.09.2018.
//  Copyright © 2018 Igor Zinovev. All rights reserved.
//

import UIKit
import Lottie
import Photos

//extension UIImage {
//    convenience init(view: UIView) {
//        UIGraphicsBeginImageContext(view.frame.size)
//        view.layer.render(in:UIGraphicsGetCurrentContext()!)
//        let image = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        self.init(cgImage: image!.cgImage!)
//    }
//}

extension UIImage{
    convenience init(view: UIView) {

        UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.isOpaque, 0.0)
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: false)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.init(cgImage: (image?.cgImage)!)

    }
}

extension Double {
    func roundTo(places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

class ViewController: UIViewController {
    
    var lottieView: LOTAnimationView?
    
    let spitfire = Spitfire()
    
    var timer: Timer!

    let FPS = 20.0
    
    @IBOutlet weak var button: UIButton!
    
    @IBOutlet weak var imgView: UIImageView!
    
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var previewView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onButtonPress(_ sender: Any) {
        let img = UIImage(named: "Kitten.jpg")
        imgView.image = img
        
        lottieView = LOTAnimationView(name: "lottie")
        print(lottieView?.animationDuration)
        lottieView!.frame = containerView.bounds
        
        containerView.addSubview(lottieView!)
        
        lottieView?.loopAnimation = true
        lottieView?.play()
    }
    
    @IBAction func startRecording(_ sender: Any) {
        
        let foo = UIImage(named: "input_img.png")
        imgView.image = foo
        
        lottieView = LOTAnimationView(name: "lottie")
        lottieView!.frame = containerView.bounds
        
        containerView.addSubview(lottieView!)
        
        lottieView?.loopAnimation = false
        lottieView?.stop()
        lottieView?.animationProgress = 0
//        lottieView?.play()
        
        do {
            try spitfire.makeVideo(with: lottieView!, containerView: containerView, progress: { (progress) in
                let percent = (progress.fractionCompleted * 100).roundTo(places: 2)
                print("\(percent)%")
            }, success: { (url) in
                
                self.merge(url: url, completion: { (exporter) in
                    print(exporter.outputURL!)
                    
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: exporter.outputURL!)
                    }) { saved, error in
                        if saved {
                            let alertController = UIAlertController(title: NSLocalizedString("Your video was saved", comment: ""), message: nil, preferredStyle: .alert)
                            let defaultAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil)
                            alertController.addAction(defaultAction)
                            self.present(alertController, animated: true, completion: nil)
                        }
                    }
                })
                
               
            })
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func merge(url: URL, completion:@escaping (_ exporter: AVAssetExportSession) -> ()) -> Void {
        
        let video = AVAsset(url: url)
        let mainComposition = AVMutableComposition()
        
        
        let compositionVideoTrack = mainComposition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
        var insertTime = kCMTimeZero
        
        try! compositionVideoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, video.duration), of: video.tracks[0], at: insertTime)
        insertTime = CMTimeAdd(insertTime, video.duration)
        
        try! compositionVideoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, video.duration), of: video.tracks[0], at: insertTime)
        insertTime = CMTimeAdd(insertTime, video.duration)
        
        try! compositionVideoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, video.duration), of: video.tracks[0], at: insertTime)
        insertTime = CMTimeAdd(insertTime, video.duration)
        
        
//        let compositionVideoTrack = mainComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        //compositionVideoTrack?.preferredTransform = CGAffineTransform(rotationAngle: .pi / 2)
        
//        var insertTime = kCMTimeZero
//
//        for videoAsset in arrayVideos {
//            try! compositionVideoTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, videoAsset.duration), of: videoAsset.tracks(withMediaType: .video)[0], at: insertTime)
//            insertTime = CMTimeAdd(insertTime, videoAsset.duration)
//        }
        
        let outputFileURL = URL(fileURLWithPath: NSTemporaryDirectory() + "result.mp4")
        
        try? FileManager.default.removeItem(at: outputFileURL)
        //fileManager.removeItemIfExisted(outputFileURL)
        
        let exporter = AVAssetExportSession(asset: mainComposition, presetName: AVAssetExportPresetHighestQuality)
        
        exporter?.outputURL = outputFileURL
        exporter?.outputFileType = AVFileTypeMPEG4
        exporter?.shouldOptimizeForNetworkUse = true
        
        exporter?.exportAsynchronously {
            DispatchQueue.main.async {
                completion(exporter!)
            }
        }
    }
    
}

