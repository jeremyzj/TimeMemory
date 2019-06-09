//
//  ViewController.swift
//  TimeMemories
//
//  Created by magi on 2019/6/8.
//  Copyright © 2019 magi. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
//        let documentPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory,
//                                                                FileManager.SearchPathDomainMask.userDomainMask, true)
//        let documnetPath = documentPaths[0]
//        let videoOutputPath = documnetPath  + "/test_output.mp4"
//        FileManager.default.createFile(atPath: videoOutputPath, contents: nil, attributes: nil)
//        print("out put path", videoOutputPath)
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        var tempPath:String
        repeat{
            let random = arc4random()
            tempPath = paths[0] + "/\(random).mp4"
        }while(FileManager.default.fileExists(atPath: tempPath))
        print("out put path", tempPath)
        
        
        if let image1 = UIImage(named: "25.jpg"), let image2 = UIImage(named: "27.jpg"),
        let image3 = UIImage(named: "29.jpg"), let image4 = UIImage(named: "30.jpg") {
            createFrameImageVideo(path: tempPath, images: [image1, image2, image3, image4])
        }
    }
    
    func convertCIImageToCGImage(inputImage: CIImage) -> CGImage! {
        let context = CIContext(options: nil)
        return context.createCGImage(inputImage, from: inputImage.extent)
    }
    
    func createFrameImageVideo(path: String?, images: Array<UIImage>)
    {
        guard let urlPath = path else {
            print("路径不能为空")
            return
        }
        
        let url = URL(fileURLWithPath: urlPath)
        
        do {
            let videoWriter: AVAssetWriter = try AVAssetWriter(url: url, fileType: AVFileType.mov)
            let videoSettings : [String: Any] = [
                AVVideoWidthKey: NSNumber(value: 400),
                AVVideoHeightKey: NSNumber(value: 200),
                AVVideoCodecKey: AVVideoCodecType.h264
            ]
            
            
            let writeInput: AVAssetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            writeInput.expectsMediaDataInRealTime = true
            let adaptor: AVAssetWriterInputPixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writeInput, sourcePixelBufferAttributes: nil)
            
            videoWriter.add(writeInput)
            videoWriter.startWriting()
            videoWriter.startSession(atSourceTime: .zero)
            
//            let timeOffset: CMTime = .zero
//            var buffer:CVPixelBuffer
            var frameCount = 0
            let numberOfSecondsPerFrame = 6;
//            var frameDuration = 10 * numberOfSecondsPerFrame
            for image in images {
                guard let ciimg = CIImage(image: image) else { continue }
                guard let cgimg = convertCIImageToCGImage(inputImage: ciimg) else { continue }
                if let buffer = pixelBufferFromCGImage(image: cgimg) {
                    var append_ok: Bool = false
                    var j = 0
                    while (!append_ok && j < 30) {
                        if (adaptor.assetWriterInput.isReadyForMoreMediaData)  {
                            let frameTime = CMTime(seconds: Double(frameCount), preferredTimescale: CMTimeScale(numberOfSecondsPerFrame))
                            append_ok = adaptor.append(buffer, withPresentationTime: frameTime)
                            if !append_ok {
                                if let error = videoWriter.error {
                                    print("Unresolved error %@,%@.", error, error.localizedDescription);
                                }
                            }
                        } else {
                            print("adaptor not ready %d, %d\n", frameCount, j)
                            Thread.sleep(forTimeInterval: 0.1)
                        }
                        j += 1
                    }
                    if (!append_ok) {
                        print("error appending image %d times %d\n, with error.", frameCount, j);
                    }
                    frameCount+=1
                } else {
                    continue
                }
            }
            writeInput.markAsFinished()
            videoWriter.finishWriting {
                
            }
            
        } catch let error  {
            print("Error: \(error.localizedDescription)")
        }
    }

    
    func pixelBufferFromCGImage(image: CGImage) -> CVPixelBuffer? {
        let size = CGSize(width: 400, height: 200)
        let options: [CFString: NSNumber] = [
            kCVPixelBufferCGImageCompatibilityKey: NSNumber(booleanLiteral: true),
            kCVPixelBufferCGBitmapContextCompatibilityKey: NSNumber(booleanLiteral: true)]
        var pxbuffer:CVPixelBuffer? = nil
        let status: CVReturn = CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32ARGB, options as CFDictionary, &pxbuffer)
        if (status != kCVReturnSuccess) {
            print("创建pix buffer失败")
        }
        CVPixelBufferLockBaseAddress(pxbuffer!, [])
        let pxData = CVPixelBufferGetBaseAddress(pxbuffer!)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pxData, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pxbuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        assert(context != nil, "context is nil")
        
        context?.concatenate(CGAffineTransform(rotationAngle: 0))
        context?.draw(image, in: CGRect(x: 0,y: 0, width: image.width, height: image.height))
        
        CVPixelBufferUnlockBaseAddress(pxbuffer!, [])
        
        return pxbuffer!
    }
        
        
        
    
//    NSDictionary *codecSettings = [NSDictionary dictionaryWithObjectsAndKeys:
//    [NSNumber numberWithInt:gVideoTrack.estimatedDataRate/*128000*/], AVVideoAverageBitRateKey,
//    [NSNumber numberWithInt:gVideoTrack.nominalFrameRate],AVVideoMaxKeyFrameIntervalKey,
//    AVVideoProfileLevelH264MainAutoLevel, AVVideoProfileLevelKey,
//    nil];
    
//    NSLog(@"Creating video settings");
//    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
//    AVVideoCodecH264, AVVideoCodecKey,
////    codecSettings,AVVideoCompressionPropertiesKey,
//    [NSNumber numberWithInt:1280], AVVideoWidthKey,
//    [NSNumber numberWithInt:720], AVVideoHeightKey,
//    nil];
    

    
//    NSLog(@"Video Width %d, Height: %d, writing frame video to file", gWidth, gHeight);
    
//    CVPixelBufferRef buffer;
//
//    for(int i = 0; i< gAnalysisFrames.size(); i++)
//    {
//    while (adaptor.assetWriterInput.readyForMoreMediaData == FALSE) {
//    NSLog(@"Waiting inside a loop");
//    NSDate *maxDate = [NSDate dateWithTimeIntervalSinceNow:0.1];
//    [[NSRunLoop currentRunLoop] runUntilDate:maxDate];
//    }
//
    //Write samples:
//    buffer = pixelBufferFromCGImage(gAnalysisFrames[i].frameImage, gWidth, gHeight);
//
//    [adaptor appendPixelBuffer:buffer withPresentationTime:timeOffset];
//
//
//
//    timeOffset = CMTimeAdd(timeOffset, gAnalysisFrames[i].duration);
//    }
//
//    while (adaptor.assetWriterInput.readyForMoreMediaData == FALSE) {
//    NSLog(@"Waiting outside a loop");
//    NSDate *maxDate = [NSDate dateWithTimeIntervalSinceNow:0.1];
//    [[NSRunLoop currentRunLoop] runUntilDate:maxDate];
//    }
//
//    buffer = pixelBufferFromCGImage(gAnalysisFrames[gAnalysisFrames.size()-1].frameImage, gWidth, gHeight);
//    [adaptor appendPixelBuffer:buffer withPresentationTime:timeOffset];
//
//    NSLog(@"Finishing session");
//    //Finish the session:
//    [writerInput markAsFinished];
//    [videoWriter endSessionAtSourceTime:timeOffset];
//    BOOL successfulWrite = [videoWriter finishWriting];
//
//    // if we failed to write the video
//    if(!successfulWrite)
//    {
//
//    NSLog(@"Session failed with error: %@", [[videoWriter error] description]);
//
//    // delete the temporary file created
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    if ([fileManager fileExistsAtPath:path]) {
//    NSError *error;
//    if ([fileManager removeItemAtPath:path error:&error] == NO) {
//    NSLog(@"removeItemAtPath %@ error:%@", path, error);
//    }
//    }
//    }
//    else
//    {
//    NSLog(@"Session complete");
//    }
//
//    [writerInput release];
//
//    }
//

}

