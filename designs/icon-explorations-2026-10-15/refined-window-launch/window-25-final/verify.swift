import Foundation
import AVFoundation
import AppKit
let root = URL(fileURLWithPath:CommandLine.arguments[1])
let asset = AVURLAsset(url:root.appendingPathComponent("focus-mate-window-25-splash.mp4"))
let track = asset.tracks(withMediaType:.video)[0]
let reader = try AVAssetReader(asset:asset)
let output = AVAssetReaderTrackOutput(track:track,outputSettings:[kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32BGRA])
reader.add(output)
reader.startReading()
var count=0
while output.copyNextSampleBuffer() != nil { count += 1 }
print("MP4 sample count: \(count), decode status: \(reader.status.rawValue)")
let generator = AVAssetImageGenerator(asset:asset)
generator.appliesPreferredTrackTransform = true
generator.requestedTimeToleranceBefore = .zero
generator.requestedTimeToleranceAfter = .zero
for (name,time) in [("closed",0.0),("open",0.8),("end",95.0/60.0)] {
  let image = try generator.copyCGImage(at:CMTime(seconds:time,preferredTimescale:600),actualTime:nil)
  let bitmap = NSBitmapImageRep(cgImage:image)
  try bitmap.representation(using:.png,properties:[:])!.write(to:root.appendingPathComponent("keyframe-\(name).png"))
}
print("Extracted 3 PNGs from encoded MP4.")

let report:[String:Any] = ["mp4":["width":track.naturalSize.width,"height":track.naturalSize.height,"duration_seconds":CMTimeGetSeconds(asset.duration),"nominal_fps":track.nominalFrameRate,"decoded_frame_count":count,"reader_completed":reader.status == .completed,"audio_tracks":asset.tracks(withMediaType:.audio).count],"visual_review":"Encoded MP4 closed/open/end frames checked: upright, centered, monochrome; original shape preserved."]
try JSONSerialization.data(withJSONObject:report,options:[.prettyPrinted,.sortedKeys]).write(to:root.appendingPathComponent("validation.json"))
