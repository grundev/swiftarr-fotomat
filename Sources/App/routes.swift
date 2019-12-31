import Vapor

/// Register your application's routes here.

public func routes(_ router: Router) throws {
    // Basic "It works" example
    router.get { req in
        return "It works!"
    }
    
    let fotomatController = FotomatController()
    
    router.post(ImageData.self, at: "type", use: fotomatController.testImageType)
    router.post(ImageData.self, at: "process",use: fotomatController.processImage)
}
