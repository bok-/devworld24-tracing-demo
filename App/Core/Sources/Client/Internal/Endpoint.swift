
public struct Endpoint: Sendable {

    // MARK: - Properties

    public var scheme: String
    public var host: String
    public var port: Int


    // MARK: - Initialisation

    public init(scheme: String, host: String, port: Int) {
        self.scheme = scheme
        self.host = host
        self.port = port
    }

}
