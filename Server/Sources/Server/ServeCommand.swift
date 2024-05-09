
import ArgumentParser
import HTTPTypes
import Hummingbird
import HummingbirdWebSocket
import Logging
import Metrics
import NIOPosix
import OTel
import OTLPGRPC
import ServiceLifecycle
import Storage
import Tracing

struct ServeCommand: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "serve",
        abstract: "Starts the BokBank server"
    )

    // MARK: - Arguments

    @Option(name: .shortAndLong, help: "The hostname to listen on. Defaults to 127.0.0.1 (IPv4)")
    var host = "127.0.0.1"

    @Option(name: .shortAndLong, help: "The port number to listen on. Defaults to 2265.")
    var port = 2265

    @Flag(name: .shortAndLong, help: "Enables more verbose logging")
    var verbose = false


    // MARK: - Validation

    func validate() throws {
        if host.isEmpty {
            throw ValidationError("Host parameter cannot be empty.")
        }
        if port < 0 || port > 65535 {
            throw ValidationError("Invalid port number.")
        }
    }

    // MARK: - Execution

    func run() async throws {
        let tracer = try await bootstrapTelemetry()

        // Dependencies
        let storage = StorageService()

        // Routing
        let router = Router(context: BokRequestContext.self)
        router.middlewares.add(LogRequestsMiddleware(.info))
        router.middlewares.add(BokTracingMiddleware(recordingHeaders: [ HTTPField.Name("content-type")! ]))
        router.middlewares.add(AuthenticationMiddleware())
        router.registerRoutes(storage: storage)

        // Web Socket support
        let wsRouter = Router(context: BokRequestContext.self)
        wsRouter.middlewares.add(LogRequestsMiddleware(.info))
        wsRouter.middlewares.add(BokTracingMiddleware(recordingHeaders: [ HTTPField.Name("content-type")! ]))
        wsRouter.middlewares.add(AuthenticationMiddleware())
        wsRouter.registerSync(storage: storage)

        // Application
        var app = Application(
            router: router,
            server: .http1WebSocketUpgrade(webSocketRouter: wsRouter),
            configuration: .init(address: .hostname(host, port: port))
        )
        app.addServices(tracer)
        try await app.run()

    }

    private func bootstrapTelemetry() async throws -> some Service {
        LoggingSystem.bootstrap({
            var logger = StreamLogHandler.standardOutput(label: $0, metadataProvider: $1)
            if verbose {
                logger.logLevel = .debug
            }
            return logger
        }, metadataProvider: .otel())

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 2)

        let exporter = OTLPGRPCSpanExporter(
            configuration: try .init(
                environment: .detected(),
                shouldUseAnInsecureConnection: true
            ),
            group: group,
            requestLogger: Logger(label: "export-request"),
            backgroundActivityLogger: Logger(label: "export-background")
        )
        let processor = OTelSimpleSpanProcessor(exporter: exporter)

        let tracer = OTelTracer(
            idGenerator: OTelRandomIDGenerator(),
            sampler: OTelConstantSampler(isOn: true),
            propagator: OTelW3CPropagator(),
            processor: processor,
            environment: .detected(),
            resource: .init(attributes: [
                "service.name": "bokbank.server"
            ])
        )

        InstrumentationSystem.bootstrap(tracer)
        return tracer
    }

}


// MARK: - Routes

private extension Router<BokRequestContext> {

    func registerRoutes(storage: StorageService) {
        registerListAccounts(storage: storage)
        registerGetAccount(storage: storage)

        registerListTransactions(storage: storage)
        registerGetTransaction(storage: storage)

        registerListMerchants(storage: storage)
        registerGetMerchant(storage: storage)

        registerTransfer(storage: storage)
    }

}
