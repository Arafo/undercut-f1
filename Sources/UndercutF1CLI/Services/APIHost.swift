import Foundation
import Logging
import NIOCore
import NIOHTTP1
import NIOPosix
import UndercutF1Data

struct APIContext {
    let dateTimeProvider: DateTimeProviding
    let sessionInfoProcessor: SessionInfoProcessor
    let timingDataProcessor: TimingDataProcessor
    let timingService: TimingService
}

final class APIHost {
    static let defaultPort = 0xF1F1 // 61937

    private let group: MultiThreadedEventLoopGroup
    private var channel: Channel?
    private let router: APIRouter
    private let logger: Logger
    private let port: Int
    private var isShutdown = false

    init(port: Int = APIHost.defaultPort, context: APIContext, logger: Logger) {
        self.port = port
        self.logger = logger
        self.group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        self.router = APIRouter(context: context, logger: logger)
    }

    func start() throws {
        guard channel == nil else { return }

        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.soReuseaddr), value: 1)
            .childChannelInitializer { [router] channel in
                channel.pipeline.configureHTTPServerPipeline().flatMap {
                    channel.pipeline.addHandler(HTTPHandler(router: router))
                }
            }
            .childChannelOption(ChannelOptions.socketOption(.soReuseaddr), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())

        channel = try bootstrap.bind(host: "127.0.0.1", port: port).wait()
        logger.info("API host listening on http://127.0.0.1:\(port)")
    }

    func run() async throws {
        guard let channel else { return }
        try await channel.closeFuture.get()
    }

    func shutdown() async {
        guard !isShutdown else { return }
        isShutdown = true
        if let channel {
            _ = try? channel.close().wait()
        }
        do {
            try group.syncShutdownGracefully()
        } catch {
            logger.error("Failed to shut down API host: \(error.localizedDescription)")
        }
    }
}

private final class HTTPHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart

    private let router: APIRouter
    private var requestHead: HTTPRequestHead?
    private var bodyBuffer: ByteBuffer?
    private var keepAlive = false

    init(router: APIRouter) {
        self.router = router
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let part = unwrapInboundIn(data)
        switch part {
        case .head(let head):
            requestHead = head
            keepAlive = head.isKeepAlive
            bodyBuffer = context.channel.allocator.buffer(capacity: 0)
        case .body(var buffer):
            bodyBuffer?.writeBuffer(&buffer)
        case .end:
            let head = requestHead
            let body = bodyBuffer
            requestHead = nil
            bodyBuffer = nil

            Task {
                let response = await router.handle(head: head, body: body)
                context.channel.eventLoop.execute {
                    self.writeResponse(response, context: context)
                }
            }
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        context.close(promise: nil)
    }

    private func writeResponse(_ response: APIResponse, context: ChannelHandlerContext) {
        var headers = response.headers
        let length = response.body?.readableBytes ?? 0
        headers.replaceOrAdd(name: "Content-Length", value: "\(length)")
        if keepAlive {
            headers.replaceOrAdd(name: "Connection", value: "keep-alive")
        }
        let head = HTTPResponseHead(version: .http1_1, status: response.status, headers: headers)
        context.write(wrapOutboundOut(.head(head)), promise: nil)
        if var body = response.body {
            context.write(wrapOutboundOut(.body(.byteBuffer(&body))), promise: nil)
        }
        let promise = context.eventLoop.makePromise(of: Void.self)
        context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: promise)
        if !keepAlive {
            promise.futureResult.whenComplete { _ in
                context.close(promise: nil)
            }
        }
    }
}

private extension EventLoopFuture {
    func get() async throws -> Value {
        try await withCheckedThrowingContinuation { continuation in
            whenComplete { result in
                switch result {
                case .success(let value):
                    continuation.resume(returning: value)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
