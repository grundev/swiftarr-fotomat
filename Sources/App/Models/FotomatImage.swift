#if os(Linux)
import SwiftImageMagickLinux
#else
import SwiftImageMagickMac
#endif
import Vapor
import Foundation

/// Wrapper for an image file, providing image manipulation functions for `swiftarr`.

final class FotomatImage {
    // MARK: Properties
    
    /// The URL of the image file.
    private var imageURL: URL
    
    // MARK: Initialization
    
    /// Initializea a new FotomatImage.
    ///
    /// - Parameter imageURL: The URL of the image file.
    /// - Throws: 500 error if the file is not found at the specified URL.
    init(imageURL: URL) throws {
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
          throw Abort(.internalServerError, reason: "image file not found")
        }
        self.imageURL = imageURL
    }
    
    // MARK: Functions
    
    /// Orients the image for proper viewing. Top-left should be in top-left.
    ///
    /// - Throws: 500 error if the image could not be retrieved from ImageMagick.
    /// - Returns: `Data` representation of the auto-oriented image, as JPEG.
    func autoOrient() throws -> Data {
        // prepare magick
        MagickWandGenesis()
        let wand = NewMagickWand()
        
        // load image
        MagickReadImage(wand, imageURL.path)
        MagickAutoOrientImage(wand)
        
        // pull image out as JPEG
        MagickSetImageCompressionQuality(wand, 100)
        MagickSetImageFormat(wand, "jpg")
        var length = 0
        guard let image = MagickGetImageBlob(wand, &length) else {
            throw Abort(.internalServerError, reason: "can't get image from imagemagick")
        }
        let data = Data(bytes: image, count: length)
        
        // clean up
        DestroyMagickWand(wand)
        MagickRelinquishMemory(image)
        MagickWandTerminus()
        
        return data
    }
    
    /// Crops the image to its maximum centered square.
    ///
    /// - Throws: 500 error if the image could not be retrieved from ImageMagick.
    /// - Returns: `Data` representation of the cropped image, as JPEG.
    func cropped() throws -> Data {
        // prepare magick
        MagickWandGenesis()
        let wand = NewMagickWand()
       
        // load image
        MagickReadImage(wand, imageURL.path)
        MagickAutoOrientImage(wand)
        
        // calculate crop region
        let width = MagickGetImageWidth(wand)
        let height = MagickGetImageHeight(wand)
        let size = min(width, height)
        var xOffset: Int
        var yOffset: Int
        if height > width {
            xOffset = 0
            yOffset = (height - width) / 2
        } else {
            xOffset = (width - height) / 2
            yOffset = 0
        }
        // crop
        MagickCropImage(wand, size, size, xOffset, yOffset)
        
        // pull image out as JPEG
        MagickSetImageCompressionQuality(wand, 85)
        MagickSetImageFormat(wand, "jpg")
        var length = 0
        guard let image = MagickGetImageBlob(wand, &length) else {
            throw Abort(.internalServerError, reason: "can't get image from imagemagick")
        }
        let data = Data(bytes: image, count: length)

        // clean up
        DestroyMagickWand(wand)
        MagickRelinquishMemory(image)
        MagickWandTerminus()
        
        return data
    }
    
    /// Returns the image type as a mimetype string.
    ///
    /// - Throws: 500 error if the identity could not be obtained from ImageMagick
    /// - Returns: `String` containing the image mimetype.
    func identify() throws -> String {
        // prepare magick
        MagickWandGenesis()
        let wand = NewMagickWand()
        
        // load image
        MagickReadImage(wand, imageURL.path)
    
        // identify
        guard let identify = String(validatingUTF8: MagickIdentifyImage(wand)) else {
            throw Abort(.internalServerError, reason: "could not read identify info")
        }
        let identifyArray = identify.components(separatedBy: "\n")
        let mimeType = identifyArray[2].components(separatedBy: ":")
        let type = mimeType[1].trimmingCharacters(in: .whitespaces)
        
        // clean up
        DestroyMagickWand(wand)
        MagickWandTerminus()

        return type
    }
    
    /// Creates a PNG thumbnail of the image, scaled to the supplied height.
    ///
    /// - Parameter height: The height of the desired thumbnail.
    /// - Throws: 500 error if the image could not be retrieved from ImageMagick.
    /// - Returns: `Data` representation of the thumbnail image, as PNG.
    func thummbnail(height: Int) throws -> Data {
        // prepare magick
        MagickWandGenesis()
        let wand = NewMagickWand()
        
        // load image
        MagickReadImage(wand, imageURL.path)
        MagickAutoOrientImage(wand)
        
        // calculate dimensions
        let imageWidth = MagickGetImageWidth(wand)
        let imageHeight = MagickGetImageHeight(wand)
        let aspect: Double = Double(height) / Double(imageHeight)
        // thumbnail
        MagickThumbnailImage(wand, Int((aspect * Double(imageWidth)).rounded()), height)
        
        // pull out image as PNG
        MagickSetImageFormat(wand, "png")
        var length = 0
        guard let image = MagickGetImageBlob(wand, &length) else {
            throw Abort(.internalServerError, reason: "can't get image from imagemagick")
        }
        let data = Data(bytes: image, count: length)
        
        // clean up
        DestroyMagickWand(wand)
        MagickRelinquishMemory(image)
        MagickWandTerminus()
        
        return data
    }
    
    /// Creates a thumbnail of a GIF, scaled to the supplied height. The resized file is
    /// saved directly with `MagickWriteImages(...)` instead of being returned as `Data`.
    ///
    /// - Parameters:
    ///   - height: The height of the desired thumbnail.
    ///   - saveTo: The URL to which the thumbnail should be saved.
    /// - Throws: 500 error if the image could not be retrieved from ImageMagick.
    /// - Returns: Void.
    func thummbnailGIF(height: Int, saveTo: URL) throws -> Void {
        // prepare magick
        MagickWandGenesis()
        let wand = NewMagickWand()
        
        // load image
        MagickReadImage(wand, imageURL.path)
        MagickAutoOrientImage(wand)
        
        // calculate dimensions
        let imageWidth = MagickGetImageWidth(wand)
        let imageHeight = MagickGetImageHeight(wand)
        let aspect: Double = Double(height) / Double(imageHeight)

        // thumbnail
        MagickResetIterator(wand)
        while MagickNextImage(wand) != MagickFalse {
            MagickResizeImage(wand, Int((aspect * Double(imageWidth)).rounded()), height, LanczosFilter, 1.0)
        }
        // save resized GIF
        MagickWriteImages(wand, saveTo.path, MagickTrue)
        
        // clean up
        DestroyMagickWand(wand)
        MagickWandTerminus()
    }

    /// Adds a watermark to the image. The default location (`GravityType`) is "SouthEastGravity"
    /// (BottomRight), with options for "Center", "BottomLeft" or "Bottom".
    ///
    /// - Note: There is no reason all 9 `GravityType`s couldn't be supported. The 4 supported
    ///   simply make the most sense for a niche feature.
    ///
    /// - Parameters:
    ///   - text: The text to use for the watermark.
    ///   - location: The location of the watermark within the image, defaults to lower right.
    ///   - font: URL of the font file to use for the watermark text.
    /// - Throws: 500 error if the image could not be retrieved from ImageMagick.
    /// - Returns: `Data` representation of the watermarked image, as JPEG.
    func watermarked(with text: String, location: String, font: URL) throws -> Data {
        guard FileManager.default.fileExists(atPath: font.path) else {
            throw Abort(.internalServerError, reason: "font file not found")
        }
        // set watermark location
        var gravity: GravityType
        switch location {
            case "Center":
                gravity = CenterGravity
            case "BottomLeft":
                gravity = SouthWestGravity
            case "Bottom":
                gravity = SouthGravity
            default:
                gravity = SouthEastGravity
        }
        
        // prepare magick
        MagickWandGenesis()
        let wand = NewMagickWand()
        let pixel = NewPixelWand()
        let draw = NewDrawingWand()
        
        // load image
        MagickReadImage(wand, imageURL.path)
        MagickAutoOrientImage(wand)
        
        // set watermark
        let imageWidth = MagickGetImageWidth(wand)
        var fontSize: Double
        var opacity: Double
        switch imageWidth {
            case ...512:
                fontSize = 36
                opacity = 0.40
            default:
                fontSize = (Double(imageWidth) / 15.0).rounded()
                opacity = 0.50
        }
        
        // prepare drawing wand
        PixelSetColor(pixel, "white")
        PixelSetOpacity(pixel, opacity)
        DrawSetFillColor(draw, pixel)
        DrawSetFont(draw, font.path)
        DrawSetFontSize(draw, fontSize)
        DrawSetGravity(draw, gravity)
        DrawAnnotation(draw, 0, 0, text)

        // add the watermark
        MagickDrawImage(wand, draw)
        
        // pull image out as JPEG
        MagickSetImageCompressionQuality(wand, 85)
        MagickSetImageFormat(wand, "jpg")
        var length = 0
        guard let image = MagickGetImageBlob(wand, &length) else {
            throw Abort(.internalServerError, reason: "can't get image from imagemagick")
        }
        let data = Data(bytes: image, count: length)
        
        // clean up
        DestroyMagickWand(wand)
        DestroyPixelWand(pixel)
        DestroyDrawingWand(draw)
        MagickRelinquishMemory(image)
        MagickWandTerminus()
        
        return data
    }
}
