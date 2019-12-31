import Vapor
@testable import App

extension Application {
    
    /// Creates an `@testable Application` object with `Environment` argument support.
    ///
    /// - Parameter envArgs: Array of `String` arguments that can be passed in.
    /// - Returns: A running `@testable` instance of the `Application`.
    static func testable(envArgs: [String]? = nil) throws -> Application {
        // set default .testing environment
        var config = Config.default()
        var services = Services.default()
        var env = Environment.testing
        // apply any supplied arguments
        if let arguments = envArgs {
            env.arguments = arguments
        }
        // return a configured app
        try App.configure(&config, &env, &services)
        let app = try Application(config: config, environment: env, services: services)
        try App.boot(app)
        return app
    }
    
    /// Resets the application's testimages/ subdirectory.
    static func reset() throws {
        let seedsDir = (DirectoryConfig.detect().workDir).appending("seeds/")
        let testimagesDir = (DirectoryConfig.detect().workDir).appending("testimages/")
        if !FileManager.default.fileExists(atPath: testimagesDir.appending("test-gif")) {
            try FileManager.default.copyItem(
                atPath: seedsDir.appending("test-gif"),
                toPath: testimagesDir.appending("test-gif")
            )
        }
        if !FileManager.default.fileExists(atPath: testimagesDir.appending("test-jpg")) {
            try FileManager.default.copyItem(
                atPath: seedsDir.appending("test-jpg"),
                toPath: testimagesDir.appending("test-jpg")
            )
        }
        if !FileManager.default.fileExists(atPath: testimagesDir.appending("test-png")) {
            try FileManager.default.copyItem(
                atPath: seedsDir.appending("test-png"),
                toPath: testimagesDir.appending("test-png")
            )
        }
    }
    
    // MARK: - Return Responses
    
    /// Returns the response to a request with a generic optional body.
    ///
    /// - Parameters:
    ///   - path: The endpoint being tested.
    ///   - method: HTTPMethod for the request.
    ///   - headers: HTTPHeaders for the request (usually just "Authorization").
    ///   - body: An optional body to be encoded as the request's content.
    /// - Returns: The `Response` to the request.
    func getResponse<T>(
        from path: String,
        method: HTTPMethod = .POST,
        headers: HTTPHeaders = .init(),
        body: T? = nil
    ) throws -> Response where T: Content {
        // the responder to reply to the request
        let responder = try self.make(Responder.self)
        // create and container-wrap the request
        let request = HTTPRequest(
            method: method,
            url: URL(string: path)!,
            headers: headers
        )
        let wrappedRequest = Request(http: request, using: self)
        // encode any body object as the request's content
        if let body = body {
            try wrappedRequest.content.encode(body)
        }
        // send request and return the `Response`
        return try responder.respond(to: wrappedRequest).wait()
    }
    
    /// Convenience to return the response to a request without a body.
    ///
    /// - Parameters:
    ///   - path: The endpoint being tested.
    ///   - method: HTTPMethod for the request.
    ///   - headers: HTTPHeaders for the request (usually just "Authoriztion").
    /// - Returns: The `Response` to the request.
    func getResponse(
        from path: String,
        method: HTTPMethod = .GET,
        headers: HTTPHeaders = .init()
    ) throws -> Response {
        // compiler doesn't direclty support nil as a generic, so pass in a nil-value <T>
        let emptyContent: EmptyContent? = nil
        return try getResponse(from: path, method: method, headers: headers, body: emptyContent)
    }
    
    /// Convenience to send a request with a generic body, discarding the response.
    ///
    /// - Parameters:
    ///   - path: The endpoint being posted to.
    ///   - method: HTTPMethod for the request.
    ///   - headers: HTTPHeaders for the request (usually just "Authorization").
    ///   - body: The body to be encoded as the request's content.
    func sendRequest<T>(
        to path: String,
        method: HTTPMethod = .POST,
        headers: HTTPHeaders = .init(),
        body: T
    ) throws where T: Content {
        // discard the response
        _ = try self.getResponse(from: path, method: method, headers: headers, body: body)
    }
    
    // MARK: - Return Results Only
    
    /// Returns the decoded content of the response to a request with an optional
    /// generic body.
    ///
    /// - Parameters:
    ///   - path: The endpoint being tested.
    ///   - method: HTTPMethod for the request.
    ///   - headers: HTTPHeaders for the request (usually just "Authorization").
    ///   - body: An optional body to be encoded as the request's content.
    ///   - type: The `Decodable` result type to be returned.
    /// - Returns: The decoded body of the response to the request.
    func getResult<C, T>(
        from path: String,
        method: HTTPMethod = .GET,
        headers: HTTPHeaders = .init(),
        body: C? = nil,
        decodeTo type: T.Type
    ) throws -> T where C: Content, T: Decodable {
        let response = try self.getResponse(
            from: path,
            method: method,
            headers: headers,
            body: body
        )
        return try response.content.decode(type).wait()
    }
    
    /// Convenience to return the decoded content of the response to a request
    /// without a body.
    ///
    /// - Parameters:
    ///   - path: The endpoint being tested.
    ///   - method: HTTPMethod for the request.
    ///   - headers: HTTPHeaders for the request (usually just "Authorization").
    ///   - type: The `Decodable` result type to be returned.
    /// - Returns: The decoded body of the response to the request.
    func getResult<T>(
        from path: String,
        method: HTTPMethod = .GET,
        headers: HTTPHeaders = .init(),
        decodeTo type: T.Type
    ) throws -> T where T: Content {
        let emptyContent: EmptyContent? = nil
        return try self.getResult(
            from: path,
            method: method,
            headers: headers,
            body: emptyContent,
            decodeTo: type
        )
    }
    
    // MARK: Use MultiPart for Content
    
    /// Returns the response to a request with a generic optional body.
    ///
    /// - Parameters:
    ///   - path: The endpoint being tested.
    ///   - method: HTTPMethod for the request.
    ///   - headers: HTTPHeaders for the request (usually just "Authorization").
    ///   - body: An optional body to be encoded as the request's content as `.formData`.
    /// - Returns: The `Response` to the request.
func getFormResponse<T>(
        from path: String,
        method: HTTPMethod = .POST,
        headers: HTTPHeaders = .init(),
        body: T? = nil
    ) throws -> Response where T: Content {
        // the responder to reply to the request
        let responder = try self.make(Responder.self)
        // create and container-wrap the request
        let request = HTTPRequest(
            method: method,
            url: URL(string: path)!,
            headers: headers
        )
        let wrappedRequest = Request(http: request, using: self)
        // encode any body object as the request's content
        if let body = body {
            try wrappedRequest.content.encode(body, as: .formData)
        }
        // send request and return the `Response`
        return try responder.respond(to: wrappedRequest).wait()
    }
    
    /// Returns the decoded content of the response to a request with an optional
    /// generic MultiPart encoded body.
    ///
    /// - Parameters:
    ///   - path: The endpoint being tested.
    ///   - method: HTTPMethod for the request.
    ///   - headers: HTTPHeaders for the request (usually just "Authorization").
    ///   - body: An optional body to be encoded as the request's content, as `.formData`.
    ///   - type: The `Decodable` result type to be returned.
    /// - Returns: The decoded body of the response to the request.
func getFormResult<C, T>(
        from path: String,
        method: HTTPMethod = .GET,
        headers: HTTPHeaders = .init(),
        body: C? = nil,
        decodeTo type: T.Type
    ) throws -> T where C: Content, T: Decodable {
        let response = try self.getFormResponse(
            from: path,
            method: method,
            headers: headers,
            body: body
        )
        return try response.content.decode(type).wait()
    }


}

/// An empty `Content` object that can be used to keep the compiler happy when there
/// is no generic body T to be evaluated.
struct EmptyContent: Content {}

