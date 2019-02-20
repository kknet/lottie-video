//
//  Spitfire.swift
//  Pods
//
//  Created by seanmcneil on 3/8/17.
//
//

import AVFoundation
import UIKit
import Lottie

public class Spitfire {
    public init() { }
    
    private var videoWriter: AVAssetWriter?
    
    private var outputURL: URL {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let documentURL = URL(fileURLWithPath: documentsPath)
        
        return documentURL.appendingPathComponent("output.mov")
    }
    
    /// Produces a video based on the contents of a UIImage array
    ///
    /// - Parameters:
    ///   - images: Images to use for creating video. Should all have the same dimensions
    ///   - fps: Frames per second, with a default value of 30
    ///   - progress: Handler that will return a fractional value indicating percent complete
    ///   - success: Handler that will return a URL of the completed video if successful
    ///   - failure: Handler that will return an error message if one occurs
    public func makeVideo(with lottieView: LOTAnimationView, containerView: UIView, progress: @escaping ((Progress) -> ()), success: @escaping ((URL) -> ())) throws {
//        guard let size = images.first?.size else {
//            throw(SpitfireError.ImageArrayEmpty)
//        }
//
//        guard fps > 0 && fps <= 60 else {
//            let message = NSLocalizedString("Framerate must be between 1 and 60", comment: "")
//            throw(SpitfireError.InvalidFramerate(message))
//        }
//
//        guard (size.width .truncatingRemainder(dividingBy: 16.0)) == 0 else {
//            let message = NSLocalizedString("Image width must be divisble by 16", comment: "")
//            throw(SpitfireError.ImageDimensionsMultiplierFailure(message))
//        }
        
        let size = lottieView.frame.size
        
        let fps = 20
        let framesMax = lottieView.animationDuration * CGFloat(fps)
        
        
        try? FileManager.default.removeItem(at: outputURL)
        
        do {
            try videoWriter = AVAssetWriter(outputURL: outputURL, fileType: AVFileTypeQuickTimeMovie)
        } catch let error {
            throw(error)
        }
        
        guard let videoWriter = videoWriter else {
            throw(SpitfireError.VideoWriterFailure)
        }
        
        let videoSettings: [String : Any] = [
            AVVideoCodecKey  : AVVideoCodecH264,
            AVVideoWidthKey  : size.width,
            AVVideoHeightKey : size.height,
            ]
        
        let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoSettings)
        
        let sourceBufferAttributes: [String : Any] = [
            (kCVPixelBufferPixelFormatTypeKey as String): Int(kCVPixelFormatType_32ARGB),
            (kCVPixelBufferWidthKey as String): Float(size.width),
            (kCVPixelBufferHeightKey as String): Float(size.height)]
        
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoWriterInput,
            sourcePixelBufferAttributes: sourceBufferAttributes
        )
        
        assert(videoWriter.canAdd(videoWriterInput))
        videoWriter.add(videoWriterInput)
        
        if videoWriter.startWriting() {
            videoWriter.startSession(atSourceTime: kCMTimeZero)
            assert(pixelBufferAdaptor.pixelBufferPool != nil)
            
            let writeQueue = DispatchQueue(label: "writeQueue", qos: .userInteractive)
            
            videoWriterInput.requestMediaDataWhenReady(on: writeQueue, using: { [weak self] in
                let frameDuration = CMTimeMake(1, Int32(fps))
                let currentProgress = Progress(totalUnitCount: Int64(framesMax))
                var frameCount: Int64 = 0
                
                while(Int(frameCount) < Int(framesMax)) {
                    // Will continue to loop until the video writer is able to write, which effectively handles buffer backups
                    if videoWriterInput.isReadyForMoreMediaData {
                        let lastFrameTime = CMTimeMake(frameCount, Int32(fps))
                        let presentationTime = frameCount == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, frameDuration)
                        
                        
                        //let image = images[Int(frameCount)]
//                        lottieView.animationProgress = CGFloat(frameCount) / framesMax
                        
                        DispatchQueue.main.sync {
                          
                            lottieView.animationProgress = CGFloat(frameCount) / framesMax
                            
                            UIGraphicsBeginImageContextWithOptions(containerView.bounds.size, containerView.isOpaque, 0.0)
                            containerView.drawHierarchy(in: containerView.bounds, afterScreenUpdates: false)
                            let image = UIGraphicsGetImageFromCurrentImageContext()
                            UIGraphicsEndImageContext()
                            
                            do {
                                try self?.append(pixelBufferAdaptor: pixelBufferAdaptor, with: image!, at: presentationTime, success: {
                                    frameCount += 1
                                    print(frameCount)
                                    currentProgress.completedUnitCount = frameCount
                                    progress(currentProgress)
                                })
                            } catch { } // Do not throw here
                            
                        }
                        
                        
//                        UIGraphicsBeginImageContextWithOptions(containerView.bounds.size, containerView.isOpaque, 0.0)
//                        containerView.drawHierarchy(in: containerView.bounds, afterScreenUpdates: false)
//                        let image = UIGraphicsGetImageFromCurrentImageContext()
//                        UIGraphicsEndImageContext()
//
//                        do {
//                            try self?.append(pixelBufferAdaptor: pixelBufferAdaptor, with: image!, at: presentationTime, success: {
//                                frameCount += 1
//                                currentProgress.completedUnitCount = frameCount
//                                progress(currentProgress)
//                            })
//                        } catch { } // Do not throw here
                    }
                }
                
                videoWriterInput.markAsFinished()
                videoWriter.finishWriting { [weak self] () -> Void in
                    guard let strongSelf = self else { return }
                    
                    success(strongSelf.outputURL)
                }
            })
        }
    }
}
