import Foundation
import AppKit

let arguments = CommandLine.arguments
guard arguments.count == 3,
      let data = try? Data(contentsOf: URL(fileURLWithPath: arguments[1])),
      let bitmap = NSBitmapImageRep(data: data) else {
    print("Could not read screenshot")
    exit(1)
}
// CI forces light appearance. Inspect the content area, excluding status and tab
// bars: a launch screen has no dark text here, while a rendered dashboard does.
var darkPixels = 0
var sampledPixels = 0
for y in stride(from: bitmap.pixelsHigh / 5, to: bitmap.pixelsHigh * 4 / 5, by: 4) {
    for x in stride(from: bitmap.pixelsWide / 20, to: bitmap.pixelsWide * 19 / 20, by: 4) {
        guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else { continue }
        sampledPixels += 1
        if color.redComponent + color.greenComponent + color.blueComponent < 1.2 { darkPixels += 1 }
    }
}
guard sampledPixels > 0, Double(darkPixels) / Double(sampledPixels) > 0.003 else {
    print("Waiting for \(arguments[2]) content; screenshot is blank")
    exit(1)
}
print("Verified nonblank \(arguments[2]) screenshot")
