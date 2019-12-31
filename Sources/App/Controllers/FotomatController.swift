import Vapor
import Foundation

/// Controller providing route handlers for `swiftarr` image processing.

final class FotomatController {
    
    /// The subdirectory containing fonts for watermarking.
    private let fontsDirectory = "fonts"
    /// The font to use for watermarking.
    private let font = "OpenSans-SemiBold.ttf"
    
    /// `POST /process`
    ///
    /// Process an uploaded image, creating both full-sized and thumbnail versions stored in
    /// corresponding subdirectories.
    ///
    /// * a profile image in GIF format is rejected
    /// * a profile image in JPEG or PNG format is auto-oriented, cropped to square, saved as
    ///   JPEG, then thumbnailed as PNG
    /// * a non-profile image in GIF format is thumbnailed
    /// * a non-profile image in JPEG or PNG format is auto-oriented, thumbnailed as PNG, then
    ///   optionally watermarked and saved as JPEG
    ///
    /// - Requires: `ImageData` payload in the HTTP body.
    /// - Parameters:
    ///   - req: The incoming `Request`, provided automatically.
    ///   - data: `ImageData` containing the imageURL and processing parameters.
    /// - Throws: 400 error if the image does not exist at the provided URL, or if a GIF file
    ///   is provided for a profile image.
    /// - Returns: 200 OK on success.
    func processImage(_ req: Request, data: ImageData) throws -> Future<Response> {
        // ensure file exists
        guard FileManager.default.fileExists(atPath: data.imageURL.path) else {
            throw Abort(.badRequest, reason: "image not found at imageURL")
        }
        // set paths
        let imagesDir = (DirectoryConfig.detect().workDir).appending(data.destDir)
        let fullPath = imagesDir.appending("full/")
        let thumbPath = imagesDir.appending("thumbnail/")
        if !FileManager().fileExists(atPath: fullPath) {
            try FileManager().createDirectory(atPath: fullPath, withIntermediateDirectories: true)
        }
        if !FileManager().fileExists(atPath: thumbPath) {
            try FileManager().createDirectory(atPath: thumbPath, withIntermediateDirectories: true)
        }
        // set image
        let image = try FotomatImage(imageURL: data.imageURL)
        let type = try image.identify()
        // process to full + thumbnail
        switch (data.destDir, type) {
            case ("images/profile/", "image/gif"):
                throw Abort(.badRequest, reason: "profile image must be JPEG or PNG")
            
            case ("images/profile/", _):
                // crop as JPEG
                let cropped = try image.cropped()
                let fullURL = URL(fileURLWithPath: fullPath)
                    .appendingPathComponent(data.imageURL.lastPathComponent, isDirectory: false)
                    .appendingPathExtension("jpg")
                try cropped.write(to: fullURL)
                // thumbnail cropped image as PNG
                let thumbImage = try FotomatImage(imageURL: fullURL)
                let thumbnail = try thumbImage.thummbnail(height: data.height)
                let thumbURL = URL(fileURLWithPath: thumbPath)
                    .appendingPathComponent(data.imageURL.lastPathComponent, isDirectory: false)
                    .appendingPathExtension("png")
                try thumbnail.write(to: thumbURL)
            
            case (_, "image/gif"):
                // create resized GIF
                let thumbURL = URL(fileURLWithPath: thumbPath)
                    .appendingPathComponent(data.imageURL.lastPathComponent, isDirectory: false)
                    .appendingPathExtension("gif")
                try image.thummbnailGIF(height: data.height, saveTo: thumbURL)
                // move original GIF
                let fullURL = URL(fileURLWithPath: fullPath)
                    .appendingPathComponent(data.imageURL.lastPathComponent, isDirectory: false)
                    .appendingPathExtension("gif")
                try FileManager.default.moveItem(at: data.imageURL, to: fullURL)
            
            default:
                // thumbnail as PNG
                let thumbnail  = try image.thummbnail(height: data.height)
                let thumbURL = URL(fileURLWithPath: thumbPath)
                    .appendingPathComponent(data.imageURL.lastPathComponent, isDirectory: false)
                    .appendingPathExtension("png")
                try thumbnail.write(to: thumbURL)
                // watermark as JPEG if supplied
                let fullURL = URL(fileURLWithPath: fullPath)
                    .appendingPathComponent(data.imageURL.lastPathComponent, isDirectory: false)
                    .appendingPathExtension("jpg")
                if let watermark = data.watermark {
                    let fontURL = (URL(fileURLWithPath: DirectoryConfig.detect().workDir))
                        .appendingPathComponent(fontsDirectory, isDirectory: true)
                        .appendingPathComponent(font, isDirectory: false)
                    let watermarked = try image.watermarked(
                        with: watermark,
                        location: data.gravity ?? "",
                        font: fontURL
                    )
                    try watermarked.write(to: fullURL)
                } else {
                    // otherwise just orient as JPEG
                    let autoOriented = try image.autoOrient()
                    try autoOriented.write(to: fullURL)
            }
        }
        // remove original temp file, if it remains
        if FileManager.default.fileExists(atPath: data.imageURL.path) {
            try FileManager.default.removeItem(at: data.imageURL)
        }
        // return .ok
        let response = Response(http: HTTPResponse(status: .ok), using: req)
        return req.future(response)
    }
    
    /// `POST /type`
    ///
    /// Test helper returns the mimetype of an image as a string.
    ///
    /// - Parameters:
    ///   - req: The incoming `Request`, provided automatically.
    ///   - data: `ImageData` containing the imageURL.
    /// - Returns: `String` containing the mimetype of the image.
    func testImageType(_ req: Request, data: ImageData) throws -> Response {
        let image = try FotomatImage(imageURL: data.imageURL)
        let type = try image.identify()
        let response = Response(http: HTTPResponse(status: .ok), using: req)
        try response.content.encode(type)
        return response
    }
}

/// Used to provide the parameters for processing an uploaded image.
struct ImageData: Content {
    /// The base directory for processed image file storage.
    var destDir: String
    /// The image URL.
    var imageURL: URL
    /// The height for a thumbnail.
    var height: Int
    /// The text for an optional watermark.
    var watermark: String?
    /// The postion of an optional watermark.
    var gravity: String?
}
