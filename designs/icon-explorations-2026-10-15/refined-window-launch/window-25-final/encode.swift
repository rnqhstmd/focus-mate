import Foundation
import AVFoundation
import AppKit
import CoreVideo

let root = URL(fileURLWithPath: CommandLine.arguments[1])
let output = root.appendingPathComponent("focus-mate-window-25-splash.mp4")
try? FileManager.default.removeItem(at: output)
let writer = try AVAssetWriter(outputURL: output, fileType: .mp4)
let settings: [String:Any] = [AVVideoCodecKey:AVVideoCodecType.h264, AVVideoWidthKey:720, AVVideoHeightKey:1560, AVVideoCompressionPropertiesKey:[AVVideoAverageBitRateKey:6_000_000, AVVideoExpectedSourceFrameRateKey:60, AVVideoMaxKeyFrameIntervalKey:60, AVVideoProfileLevelKey:AVVideoProfileLevelH264HighAutoLevel]]
let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
input.expectsMediaDataInRealTime = false
let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes:[kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32ARGB,kCVPixelBufferWidthKey as String:720,kCVPixelBufferHeightKey as String:1560,kCVPixelBufferCGImageCompatibilityKey as String:true,kCVPixelBufferCGBitmapContextCompatibilityKey as String:true])
writer.add(input)
guard writer.startWriting() else { fatalError("startWriting: \(String(describing: writer.error))") }
writer.startSession(atSourceTime: .zero)
for index in 0..<96 {
  while !input.isReadyForMoreMediaData { Thread.sleep(forTimeInterval:0.001) }
  try autoreleasepool {
    let file = root.appendingPathComponent("frames/" + String(format:"%04d.png",index))
    let data = try Data(contentsOf:file)
    guard let image = NSBitmapImageRep(data:data)?.cgImage else { fatalError("PNG decode") }
    var optional:CVPixelBuffer?
    let result = CVPixelBufferPoolCreatePixelBuffer(nil,adaptor.pixelBufferPool!,&optional)
    guard result == kCVReturnSuccess, let buffer = optional else { fatalError("pixel buffer") }
    CVPixelBufferLockBaseAddress(buffer, [])
    let context = CGContext(data:CVPixelBufferGetBaseAddress(buffer),width:720,height:1560,bitsPerComponent:8,bytesPerRow:CVPixelBufferGetBytesPerRow(buffer),space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.noneSkipFirst.rawValue)!
    context.draw(image,in:CGRect(x:0,y:0,width:720,height:1560))
    CVPixelBufferUnlockBaseAddress(buffer,[])
    guard adaptor.append(buffer,withPresentationTime:CMTime(value:Int64(index),timescale:60)) else { fatalError("append: \(String(describing:writer.error))") }
  }
}
writer.endSession(atSourceTime:CMTime(value:96,timescale:60))
input.markAsFinished()
let done = DispatchSemaphore(value:0)
writer.finishWriting { done.signal() }
done.wait()
guard writer.status == .completed else { fatalError("finish: \(String(describing:writer.error))") }
let asset = AVURLAsset(url:output)
let track = asset.tracks(withMediaType:.video)[0]
print("MP4: \(track.naturalSize.width)x\(track.naturalSize.height), duration \(CMTimeGetSeconds(asset.duration))s, fps \(track.nominalFrameRate), audio tracks \(asset.tracks(withMediaType:.audio).count)")
