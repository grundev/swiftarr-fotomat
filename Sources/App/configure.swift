import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {

    // run API on port 8082 by default and set a 10MB hard limit on file size
    let port = Int(Environment.get("PORT") ?? "8082")!
    services.register {
        container -> NIOServerConfig in
        .default(port: port, maxBodySize: 10_000_000)
    }
    
    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)
}
