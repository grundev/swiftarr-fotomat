@testable import App
import Vapor
import XCTest
import Foundation

final class FotomatTests: XCTestCase {
    
    // MARK: - Configure Test Environment
    
    // set properties
    var app: Application!
    
    /// Repopulate the testimages/ subdirectory and create testable app instance.
    override func setUp() {
        try! Application.reset()
        app = try! Application.testable()
    }
    
    /// Shut down the app.
    override func tearDown() {
        try? app.syncShutdownGracefully()
        super.tearDown()
    }
    
    // MARK: - Tests
    
    /// Tests that image.type() returns the correct mimetype string.
    func testImageType() throws {
        // test jpg
        var imageFile = "test-jpg"
        let directoryConfig = DirectoryConfig.detect()
        var imagePath = directoryConfig.workDir.appending("testimages/").appending(imageFile)
        var imageURL = URL(fileURLWithPath: imagePath)
        var imageData = ImageData(
            destDir: "",
            imageURL: imageURL,
            height: 100,
            watermark: nil,
            gravity: nil
        )
        var response = try app.getResponse(
            from: "/type/",
            method: .POST,
            headers: HTTPHeaders(),
            body: imageData
        )
        XCTAssertTrue(response.http.status.code == 200, "should be 200 OK")
        XCTAssertTrue(response.http.body.description == "image/jpeg", "should be 'image/jpeg'")
        
        // test png
        imageFile = "test-png"
        imagePath = directoryConfig.workDir.appending("testimages/").appending(imageFile)
        imageURL = URL(fileURLWithPath: imagePath)
        imageData = ImageData(
            destDir: "",
            imageURL: imageURL,
            height: 100,
            watermark: nil,
            gravity: nil
        )
        response = try app.getResponse(
            from: "/type/",
            method: .POST,
            headers: HTTPHeaders(),
            body: imageData
        )
        XCTAssertTrue(response.http.status.code == 200, "should be 200 OK")
        XCTAssertTrue(response.http.body.description == "image/png", "should be 'image/png'")
        
        // test gif
        imageFile = "test-gif"
        imagePath = directoryConfig.workDir.appending("testimages/").appending(imageFile)
        imageURL = URL(fileURLWithPath: imagePath)
        imageData = ImageData(
            destDir: "",
            imageURL: imageURL,
            height: 100,
            watermark: nil,
            gravity: nil
        )
        response = try app.getResponse(
            from: "/type/",
            method: .POST,
            headers: HTTPHeaders(),
            body: imageData
        )
        XCTAssertTrue(response.http.status.code == 200, "should be 200 OK")
        XCTAssertTrue(response.http.body.description == "image/gif", "should be 'image/gif'")
}
    
    /// Tests that profile images are auto-oriented and cropped (not really... the check is
    /// visual), and that GIF files are rejected.
    func testProcessProfile() throws {
        // test jpg
        var imageFile = "test-jpg"
        let directoryConfig = DirectoryConfig.detect()
        var imagePath = directoryConfig.workDir.appending("testimages/").appending(imageFile)
        var imageURL = URL(fileURLWithPath: imagePath)
        var imageData = ImageData(
            destDir: "images/profile/",
            imageURL: imageURL,
            height: 100,
            watermark: nil,
            gravity: nil
        )
        var response = try app.getResponse(
            from: "/process/",
            method: .POST,
            headers: HTTPHeaders(),
            body: imageData
        )
        XCTAssertTrue(response.http.status.code == 200, "should be 200 OK")
        
        // test png
        imageFile = "test-png"
        imagePath = directoryConfig.workDir.appending("testimages/").appending(imageFile)
        imageURL = URL(fileURLWithPath: imagePath)
        imageData = ImageData(
            destDir: "images/profile/",
            imageURL: imageURL,
            height: 100,
            watermark: nil,
            gravity: nil
        )
        response = try app.getResponse(
            from: "/process/",
            method: .POST,
            headers: HTTPHeaders(),
            body: imageData
        )
        XCTAssertTrue(response.http.status.code == 200, "should be 200 OK")

        // test gif
        imageFile = "test-gif"
        imagePath = directoryConfig.workDir.appending("testimages/").appending(imageFile)
        imageURL = URL(fileURLWithPath: imagePath)
        imageData = ImageData(
            destDir: "images/profile/",
            imageURL: imageURL,
            height: 100,
            watermark: nil,
            gravity: nil
        )
        response = try app.getResponse(
            from: "/process/",
            method: .POST,
            headers: HTTPHeaders(),
            body: imageData
        )
        XCTAssertTrue(response.http.status.code == 400, "should be 400 Bad Request")
        XCTAssertTrue(response.http.body.description.contains("must be"), "must be")
    }
    
    /// Tests that forum images are auto-oriented, and GIFs are thumbnailed.
    func testProcessForum() throws {
        // test jpg
        var imageFile = "test-jpg"
        let directoryConfig = DirectoryConfig.detect()
        var imagePath = directoryConfig.workDir.appending("testimages/").appending(imageFile)
        var imageURL = URL(fileURLWithPath: imagePath)
        var imageData = ImageData(
            destDir: "images/forum/",
            imageURL: imageURL,
            height: 100,
            watermark: nil,
            gravity: nil
        )
        var response = try app.getResponse(
            from: "/process/",
            method: .POST,
            headers: HTTPHeaders(),
            body: imageData
        )
        XCTAssertTrue(response.http.status.code == 200, "should be 200 OK")
        
        // test png
        imageFile = "test-png"
        imagePath = directoryConfig.workDir.appending("testimages/").appending(imageFile)
        imageURL = URL(fileURLWithPath: imagePath)
        imageData = ImageData(
            destDir: "images/forum/",
            imageURL: imageURL,
            height: 100,
            watermark: nil,
            gravity: nil
        )
        response = try app.getResponse(
            from: "/process/",
            method: .POST,
            headers: HTTPHeaders(),
            body: imageData
        )
        XCTAssertTrue(response.http.status.code == 200, "should be 200 OK")

        // test gif
        imageFile = "test-gif"
        imagePath = directoryConfig.workDir.appending("testimages/").appending(imageFile)
        imageURL = URL(fileURLWithPath: imagePath)
        imageData = ImageData(
            destDir: "images/forum/",
            imageURL: imageURL,
            height: 100,
            watermark: nil,
            gravity: nil
        )
        response = try app.getResponse(
            from: "/process/",
            method: .POST,
            headers: HTTPHeaders(),
            body: imageData
        )
        XCTAssertTrue(response.http.status.code == 200, "should be 200 OK")
    }
    
    /// Tests that forum images are auto-oriented, and GIFs are thumbnailed. The actual checks
    /// are visual.
    func testProcessTwitarr() throws {
        // test jpg
        var imageFile = "test-jpg"
        let directoryConfig = DirectoryConfig.detect()
        var imagePath = directoryConfig.workDir.appending("testimages/").appending(imageFile)
        var imageURL = URL(fileURLWithPath: imagePath)
        var imageData = ImageData(
            destDir: "images/twitarr/",
            imageURL: imageURL,
            height: 100,
            watermark: nil,
            gravity: nil
        )
        var response = try app.getResponse(
            from: "/process/",
            method: .POST,
            headers: HTTPHeaders(),
            body: imageData
        )
        XCTAssertTrue(response.http.status.code == 200, "should be 200 OK")
        
        // test png
        imageFile = "test-png"
        imagePath = directoryConfig.workDir.appending("testimages/").appending(imageFile)
        imageURL = URL(fileURLWithPath: imagePath)
        imageData = ImageData(
            destDir: "images/twitarr/",
            imageURL: imageURL,
            height: 100,
            watermark: nil,
            gravity: nil
        )
        response = try app.getResponse(
            from: "/process/",
            method: .POST,
            headers: HTTPHeaders(),
            body: imageData
        )
        XCTAssertTrue(response.http.status.code == 200, "should be 200 OK")

        // test gif
        imageFile = "test-gif"
        imagePath = directoryConfig.workDir.appending("testimages/").appending(imageFile)
        imageURL = URL(fileURLWithPath: imagePath)
        imageData = ImageData(
            destDir: "images/twitarr/",
            imageURL: imageURL,
            height: 100,
            watermark: nil,
            gravity: nil
        )
        response = try app.getResponse(
            from: "/process/",
            method: .POST,
            headers: HTTPHeaders(),
            body: imageData
        )
        XCTAssertTrue(response.http.status.code == 200, "should be 200 OK")
    }
    
    /// Tests that full sized images are watermarked when parameters are supplied, and that
    /// thumbnails and GIFs are not. Again, the actual checks are visual.
    func testProcessWatermark() throws {
        // test jpg
        var imageFile = "test-jpg"
        let directoryConfig = DirectoryConfig.detect()
        var imagePath = directoryConfig.workDir.appending("testimages/").appending(imageFile)
        var imageURL = URL(fileURLWithPath: imagePath)
        var imageData = ImageData(
            destDir: "images/twitarr/",
            imageURL: imageURL,
            height: 100,
            watermark: "@grundoon\nJoCo Cruise 2020",
            gravity: nil
        )
        var response = try app.getResponse(
            from: "/process/",
            method: .POST,
            headers: HTTPHeaders(),
            body: imageData
        )
        XCTAssertTrue(response.http.status.code == 200, "should be 200 OK")
        
        // test png
        imageFile = "test-png"
        imagePath = directoryConfig.workDir.appending("testimages/").appending(imageFile)
        imageURL = URL(fileURLWithPath: imagePath)
        imageData = ImageData(
            destDir: "images/twitarr/",
            imageURL: imageURL,
            height: 100,
            watermark: "@grundoon\nJoCo Cruise 2020",
            gravity: nil
        )
        response = try app.getResponse(
            from: "/process/",
            method: .POST,
            headers: HTTPHeaders(),
            body: imageData
        )
        XCTAssertTrue(response.http.status.code == 200, "should be 200 OK")
    }
}
