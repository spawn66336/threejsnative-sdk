#if canImport(UIKit)
import Combine
import Foundation
import SwiftUI
import UIKit
import TjnEngineCore

public enum EngineState: Int32, Sendable {
    case detached = 0, attaching, surfaceReady, running, suspended, failed, destroying, destroyed
}

public struct EngineConfiguration: Sendable {
    public var eventCapacity: UInt32
    public var memoryBudgetBytes: UInt64
    public var quality: UInt32

    public init(eventCapacity: UInt32 = 256, memoryBudgetBytes: UInt64 = 512 << 20,
                quality: UInt32 = 1) {
        self.eventCapacity = eventCapacity
        self.memoryBudgetBytes = memoryBudgetBytes
        self.quality = quality
    }
    public static let mobile = EngineConfiguration()
}

public struct RuntimeCapabilities: Sendable {
    public let backend: Int32
    public let maxTextureSize: UInt32
    public let maxRenderTargetSize: UInt32
    public let enabledFeatures: UInt64
}

public struct PerspectiveCameraConfiguration: Sendable {
    public var fovDegrees: Float
    public var aspect: Float
    public var nearPlane: Float
    public var farPlane: Float
    public init(fovDegrees: Float = 45, aspect: Float, nearPlane: Float = 0.1, farPlane: Float = 100) {
        self.fovDegrees = fovDegrees; self.aspect = aspect
        self.nearPlane = nearPlane; self.farPlane = farPlane
    }
}

public enum GeometryDescriptor: Sendable {
    case box(width: Float, height: Float, depth: Float)
}

public enum MaterialDescriptor: Sendable {
    case basic(colorRGB: UInt32)
    case standard(colorRGB: UInt32, metalness: Float, roughness: Float)
}

public enum LightDescriptor: Sendable {
    case ambient(colorRGB: UInt32, intensity: Float)
    case directional(colorRGB: UInt32, intensity: Float)
    case point(colorRGB: UInt32, intensity: Float, distance: Float)
}

public struct AssetRequest: Sendable {
    public let url: URL
    public init(url: URL) { self.url = url }
}

public struct CaptureOptions: Sendable {
    public let renderTarget: TjnRenderTarget?
    public init(renderTarget: TjnRenderTarget? = nil) { self.renderTarget = renderTarget }
}

public enum SuspensionReason: UInt32, Sendable { case explicit = 0, applicationInactive = 1 }
public enum TrimMemoryLevel: Sendable { case moderate, critical }

public struct TjnEngineError: Error, LocalizedError, Sendable {
    public let status: Int32
    public let operation: String
    public var errorDescription: String? { "\(operation) failed with status \(status)" }
}

@available(iOS 13.0, *)
@MainActor
open class TjnObject {
    fileprivate weak var engine: TjnEngine?
    fileprivate let sessionIdentity: UUID
    fileprivate(set) public var handle: TjnObjectHandle
    public private(set) var isReleased = false

    fileprivate init(engine: TjnEngine, handle: TjnObjectHandle) {
        self.engine = engine; self.sessionIdentity = engine.sessionIdentity; self.handle = handle
    }

    public func setPosition(x: Float, y: Float, z: Float) throws {
        try owner().check(tjn_object_set_position(owner().nativeHandle, handle, x, y, z), "object.setPosition")
    }
    public func setQuaternion(x: Float, y: Float, z: Float, w: Float) throws {
        try owner().check(tjn_object_set_quaternion(owner().nativeHandle, handle, x, y, z, w), "object.setQuaternion")
    }
    public func setScale(x: Float, y: Float, z: Float) throws {
        try owner().check(tjn_object_set_scale(owner().nativeHandle, handle, x, y, z), "object.setScale")
    }
    public func release() {
        guard !isReleased else { return }
        isReleased = true
        if let engine, !engine.isReleased { _ = tjn_handle_release(engine.nativeHandle, handle) }
        handle = 0
    }
    fileprivate func owner() throws -> TjnEngine {
        guard !isReleased, let engine, !engine.isReleased else {
            throw TjnEngineError(status: TJN_STATUS_STALE_HANDLE, operation: "object access")
        }
        return engine
    }
}

@available(iOS 13.0, *) @MainActor public final class TjnScene: TjnObject {
    public func add(_ child: TjnObject) throws {
        let engine = try owner(); try engine.assertOwned(child)
        try engine.check(tjn_scene_add(engine.nativeHandle, handle, child.handle), "scene.add")
    }
    public func remove(_ child: TjnObject) throws {
        let engine = try owner(); try engine.assertOwned(child)
        try engine.check(tjn_scene_remove(engine.nativeHandle, handle, child.handle), "scene.remove")
    }
}
@available(iOS 13.0, *) @MainActor open class TjnCamera: TjnObject {}
@available(iOS 13.0, *) @MainActor public final class TjnPerspectiveCamera: TjnCamera {
    public func lookAt(x: Float, y: Float, z: Float) throws {
        let engine = try owner()
        try engine.check(tjn_camera_look_at(engine.nativeHandle, handle, x, y, z), "camera.lookAt")
    }
}
@available(iOS 13.0, *) @MainActor public final class TjnGeometry: TjnObject {}
@available(iOS 13.0, *) @MainActor public final class TjnMaterial: TjnObject {
    public func setBaseColorTexture(_ texture: TjnTexture) throws {
        let engine = try owner(); try engine.assertOwned(texture)
        try engine.check(tjn_material_set_base_color_texture(engine.nativeHandle, handle, texture.handle),
                         "material.setBaseColorTexture")
    }
}
@available(iOS 13.0, *) @MainActor public final class TjnMesh: TjnObject {}
@available(iOS 13.0, *) @MainActor public final class TjnLight: TjnObject {}
@available(iOS 13.0, *) @MainActor public final class TjnTexture: TjnObject {}
@available(iOS 13.0, *) @MainActor public final class TjnRenderTarget: TjnObject {}
@available(iOS 13.0, *) @MainActor public final class LoadedResource: TjnObject {
    public func root() throws -> TjnObject {
        let engine = try owner(); var value: TjnObjectHandle = 0
        try engine.check(tjn_resource_get_root(engine.nativeHandle, handle, &value), "resource.root")
        return TjnObject(engine: engine, handle: value)
    }
}
@available(iOS 13.0, *) @MainActor public final class TjnAnimationAction: TjnObject {
    public func stop() throws {
        let engine = try owner()
        try engine.check(tjn_animation_stop(engine.nativeHandle, handle), "animation.stop")
    }
}
@available(iOS 13.0, *) @MainActor public final class TjnOrbitControls: TjnObject {
    public func wheel(deltaPixels: Float) throws {
        let engine = try owner()
        try engine.check(tjn_orbit_controls_wheel(engine.nativeHandle, handle, deltaPixels), "controls.wheel")
    }
}

@available(iOS 13.0, *)
@MainActor
public final class TjnEngine: ObservableObject {
    public let renderView: TJNEngineView
    @Published public private(set) var state: EngineState = .detached
    @Published public private(set) var capabilities: RuntimeCapabilities?

    fileprivate let sessionIdentity = UUID()
    fileprivate var nativeHandle: TjnEngineHandle { controller.engineHandle }
    fileprivate var isReleased = false
    private let controller: TJNEngineController
    private enum Pending {
        case resource(CheckedContinuation<LoadedResource, Error>)
        case capture(CheckedContinuation<UIImage, Error>)
    }
    private var pending: [TjnRequestId: Pending] = [:]

    public init(configuration: EngineConfiguration = .mobile) throws {
        var native = TjnEngineConfig()
        native.struct_size = UInt32(MemoryLayout<TjnEngineConfig>.size)
        native.struct_version = TJN_ENGINE_STRUCT_VERSION
        native.abi_version = TJN_ENGINE_ABI_VERSION
        native.event_capacity = configuration.eventCapacity
        native.memory_budget_bytes = configuration.memoryBudgetBytes
        native.quality = configuration.quality
        let controller = try TJNEngineController(configuration: native)
        self.controller = controller
        self.renderView = controller.renderView
        controller.eventHandler = { [weak self] event in self?.receive(event) }
        updateCapabilities()
        controller.startDisplayLink()
    }

    public func makeScene() throws -> TjnScene {
        TjnScene(engine: self, handle: try outHandle(tjn_scene_create, operation: "scene.create"))
    }
    public func makePerspectiveCamera(_ value: PerspectiveCameraConfiguration) throws -> TjnPerspectiveCamera {
        var config = TjnPerspectiveCameraConfig(struct_size: UInt32(MemoryLayout<TjnPerspectiveCameraConfig>.size),
            struct_version: TJN_ENGINE_STRUCT_VERSION, fov_degrees: value.fovDegrees, aspect: value.aspect,
            near_plane: value.nearPlane, far_plane: value.farPlane)
        var handle: TjnObjectHandle = 0
        try check(tjn_perspective_camera_create(nativeHandle, &config, &handle), "camera.create")
        return TjnPerspectiveCamera(engine: self, handle: handle)
    }
    public func makeGeometry(_ value: GeometryDescriptor) throws -> TjnGeometry {
        switch value {
        case let .box(width, height, depth):
            var config = TjnBoxGeometryConfig(struct_size: UInt32(MemoryLayout<TjnBoxGeometryConfig>.size),
                struct_version: TJN_ENGINE_STRUCT_VERSION, width: width, height: height, depth: depth)
            var handle: TjnObjectHandle = 0
            try check(tjn_box_geometry_create(nativeHandle, &config, &handle), "geometry.box")
            return TjnGeometry(engine: self, handle: handle)
        }
    }
    public func makeMaterial(_ value: MaterialDescriptor) throws -> TjnMaterial {
        var config = TjnMaterialConfig()
        config.struct_size = UInt32(MemoryLayout<TjnMaterialConfig>.size)
        config.struct_version = TJN_ENGINE_STRUCT_VERSION
        var create: ((TjnEngineHandle, UnsafePointer<TjnMaterialConfig>?, UnsafeMutablePointer<TjnObjectHandle>?) -> TjnStatus)!
        switch value {
        case let .basic(color): config.color_rgb = color; config.roughness = 1; create = tjn_basic_material_create
        case let .standard(color, metalness, roughness):
            config.color_rgb = color; config.metalness = metalness; config.roughness = roughness
            create = tjn_standard_material_create
        }
        var handle: TjnObjectHandle = 0
        try check(create(nativeHandle, &config, &handle), "material.create")
        return TjnMaterial(engine: self, handle: handle)
    }
    public func makeMesh(geometry: TjnGeometry, material: TjnMaterial) throws -> TjnMesh {
        try assertOwned(geometry); try assertOwned(material)
        var config = TjnMeshConfig(struct_size: UInt32(MemoryLayout<TjnMeshConfig>.size),
            struct_version: TJN_ENGINE_STRUCT_VERSION, geometry: geometry.handle, material: material.handle)
        var handle: TjnObjectHandle = 0
        try check(tjn_mesh_create(nativeHandle, &config, &handle), "mesh.create")
        return TjnMesh(engine: self, handle: handle)
    }
    public func makeLight(_ value: LightDescriptor) throws -> TjnLight {
        var config = TjnLightConfig()
        config.struct_size = UInt32(MemoryLayout<TjnLightConfig>.size); config.struct_version = TJN_ENGINE_STRUCT_VERSION
        switch value {
        case let .ambient(color, intensity): config.type = TJN_OBJECT_AMBIENT_LIGHT; config.color_rgb = color; config.intensity = intensity
        case let .directional(color, intensity): config.type = TJN_OBJECT_DIRECTIONAL_LIGHT; config.color_rgb = color; config.intensity = intensity
        case let .point(color, intensity, distance): config.type = TJN_OBJECT_POINT_LIGHT; config.color_rgb = color; config.intensity = intensity; config.distance = distance
        }
        var handle: TjnObjectHandle = 0
        try check(tjn_light_create(nativeHandle, &config, &handle), "light.create")
        return TjnLight(engine: self, handle: handle)
    }
    public func makeTexture(width: UInt32, height: UInt32, rgba: Data, srgb: Bool = true) throws -> TjnTexture {
        guard rgba.count == Int(width * height * 4) else {
            throw TjnEngineError(status: TJN_STATUS_INVALID_ARGUMENT, operation: "texture byte count")
        }
        var handle: TjnObjectHandle = 0
        let status = rgba.withUnsafeBytes { storage -> TjnStatus in
            var native = TjnTextureRgba8Data()
            native.struct_size = UInt32(MemoryLayout<TjnTextureRgba8Data>.size)
            native.struct_version = TJN_ENGINE_STRUCT_VERSION
            native.width = width; native.height = height
            native.rgba = storage.bindMemory(to: UInt8.self).baseAddress
            native.byte_count = storage.count; native.srgb = srgb ? 1 : 0
            return tjn_texture_create_rgba8(nativeHandle, &native, &handle)
        }
        try check(status, "texture.create")
        return TjnTexture(engine: self, handle: handle)
    }
    public func makeOrbitControls(camera: TjnPerspectiveCamera, target: (Float, Float, Float) = (0, 0, 0)) throws -> TjnOrbitControls {
        try assertOwned(camera)
        var config = TjnOrbitControlsConfig()
        config.struct_size = UInt32(MemoryLayout<TjnOrbitControlsConfig>.size)
        config.struct_version = TJN_ENGINE_STRUCT_VERSION; config.camera = camera.handle
        config.target_x = target.0; config.target_y = target.1; config.target_z = target.2
        config.min_distance = 0.01; config.max_distance = 10_000
        var handle: TjnObjectHandle = 0
        try check(tjn_orbit_controls_create(nativeHandle, &config, &handle), "controls.create")
        return TjnOrbitControls(engine: self, handle: handle)
    }
    public func makeRenderTarget(width: UInt32, height: UInt32, hdr: Bool = false) throws -> TjnRenderTarget {
        var config = TjnRenderTargetConfig(struct_size: UInt32(MemoryLayout<TjnRenderTargetConfig>.size),
            struct_version: TJN_ENGINE_STRUCT_VERSION, width: width, height: height, hdr: hdr ? 1 : 0, depth_stencil: 1)
        var handle: TjnObjectHandle = 0
        try check(tjn_render_target_create(nativeHandle, &config, &handle), "renderTarget.create")
        return TjnRenderTarget(engine: self, handle: handle)
    }
    public func render(scene: TjnScene, camera: TjnCamera) throws {
        try assertOwned(scene); try assertOwned(camera)
        try check(controller.renderScene(scene.handle, camera: camera.handle), "renderer.render")
    }
    public func load(_ request: AssetRequest) async throws -> LoadedResource {
        let data = try await Task.detached(priority: .userInitiated) { try Data(contentsOf: request.url) }.value
        try Task.checkCancellation()
        var id: TjnRequestId = 0
        let status = data.withUnsafeBytes { bytes in
            tjn_resource_load_glb_memory(nativeHandle, bytes.baseAddress, bytes.count, &id)
        }
        try check(status, "resource.load")
        return try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { continuation in pending[id] = .resource(continuation) }
        }, onCancel: { Task { @MainActor [weak self] in self?.cancel(id) } })
    }
    public func playAnimation(resource: LoadedResource, clipName: String) throws -> TjnAnimationAction {
        try assertOwned(resource)
        var handle: TjnObjectHandle = 0
        let status = clipName.utf8CString.withUnsafeBufferPointer { name in
            tjn_animation_play(nativeHandle, resource.handle, name.baseAddress, max(0, name.count - 1), &handle)
        }
        try check(status, "animation.play")
        return TjnAnimationAction(engine: self, handle: handle)
    }
    public func capture(_ options: CaptureOptions = .init()) async throws -> UIImage {
        if let target = options.renderTarget { try assertOwned(target) }
        var native = TjnCaptureOptions(struct_size: UInt32(MemoryLayout<TjnCaptureOptions>.size),
            struct_version: TJN_ENGINE_STRUCT_VERSION, render_target: options.renderTarget?.handle ?? 0, flags: 0)
        var id: TjnRequestId = 0
        try check(tjn_capture_request(nativeHandle, &native, &id), "capture.request")
        return try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { continuation in pending[id] = .capture(continuation) }
        }, onCancel: { Task { @MainActor [weak self] in self?.cancel(id) } })
    }
    public func pause(reason: SuspensionReason = .explicit) { controller.pause(withReason: reason.rawValue) }
    public func resume(reason: SuspensionReason = .explicit) { controller.resume(withReason: reason.rawValue) }
    public func trimMemory(_ level: TrimMemoryLevel) {
        if level == .critical { /* Native budgets are released through explicit object ownership. */ }
    }
    public func release() {
        guard !isReleased else { return }
        isReleased = true
        for (_, value) in pending {
            let error = TjnEngineError(status: TJN_STATUS_CANCELLED, operation: "engine.release")
            switch value { case let .resource(c): c.resume(throwing: error); case let .capture(c): c.resume(throwing: error) }
        }
        pending.removeAll()
        controller.releaseEngine()
        state = .destroyed
        capabilities = nil
    }

    fileprivate func check(_ status: TjnStatus, _ operation: String) throws {
        guard status == TJN_STATUS_OK else { throw TjnEngineError(status: status, operation: operation) }
    }
    fileprivate func assertOwned(_ object: TjnObject) throws {
        guard object.sessionIdentity == sessionIdentity else {
            throw TjnEngineError(status: TJN_STATUS_WRONG_SESSION, operation: "cross-session object")
        }
        _ = try object.owner()
    }
    private func outHandle(_ function: (TjnEngineHandle, UnsafeMutablePointer<TjnObjectHandle>?) -> TjnStatus,
                           operation: String) throws -> TjnObjectHandle {
        var handle: TjnObjectHandle = 0; try check(function(nativeHandle, &handle), operation); return handle
    }
    private func cancel(_ request: TjnRequestId) { if !isReleased { _ = tjn_request_cancel(nativeHandle, request) } }
    private func updateCapabilities() {
        var native = TjnRuntimeCapabilities()
        native.struct_size = UInt32(MemoryLayout<TjnRuntimeCapabilities>.size)
        native.struct_version = TJN_ENGINE_STRUCT_VERSION
        if tjn_engine_get_capabilities(nativeHandle, &native) == TJN_STATUS_OK {
            capabilities = RuntimeCapabilities(backend: native.backend, maxTextureSize: native.max_texture_size,
                maxRenderTargetSize: native.max_render_target_size, enabledFeatures: native.enabled_features)
        }
    }
    private func receive(_ event: TjnEvent) {
        if event.type == TJN_EVENT_STATE_CHANGED { state = EngineState(rawValue: Int32(event.value1)) ?? state }
        guard event.type == TJN_EVENT_RESOURCE_READY || event.type == TJN_EVENT_CAPTURE_READY else { return }
        guard let value = pending.removeValue(forKey: event.request_id) else { return }
        if event.status != TJN_STATUS_OK {
            let error = TjnEngineError(status: event.status, operation: "async request")
            switch value { case let .resource(c): c.resume(throwing: error); case let .capture(c): c.resume(throwing: error) }
            return
        }
        switch value {
        case let .resource(continuation): continuation.resume(returning: LoadedResource(engine: self, handle: event.object))
        case let .capture(continuation):
            do { continuation.resume(returning: try copyCapture(event.request_id)) }
            catch { continuation.resume(throwing: error) }
        }
    }
    private func copyCapture(_ request: TjnRequestId) throws -> UIImage {
        var required = 0, width: UInt32 = 0, height: UInt32 = 0, stride: UInt32 = 0
        let query = tjn_capture_copy_rgba(nativeHandle, request, nil, 0, &required, &width, &height, &stride)
        guard query == TJN_STATUS_BUFFER_TOO_SMALL || query == TJN_STATUS_OK else { try check(query, "capture.query"); fatalError() }
        var bytes = [UInt8](repeating: 0, count: required)
        try bytes.withUnsafeMutableBytes { storage in
            try check(tjn_capture_copy_rgba(nativeHandle, request, storage.baseAddress, storage.count,
                &required, &width, &height, &stride), "capture.copy")
        }
        guard let provider = CGDataProvider(data: Data(bytes) as CFData),
              let image = CGImage(width: Int(width), height: Int(height), bitsPerComponent: 8, bitsPerPixel: 32,
                bytesPerRow: Int(stride), space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue), provider: provider,
                decode: nil, shouldInterpolate: false, intent: .defaultIntent) else {
            throw TjnEngineError(status: TJN_STATUS_INTERNAL, operation: "capture.image")
        }
        return UIImage(cgImage: image)
    }
}

@available(iOS 13.0, *)
public struct TjnRenderView: UIViewRepresentable {
    @ObservedObject private var engine: TjnEngine
    public init(engine: TjnEngine) { self.engine = engine }
    public func makeUIView(context: Context) -> TJNEngineView { engine.renderView }
    public func updateUIView(_ uiView: TJNEngineView, context: Context) {}
    public static func dismantleUIView(_ uiView: TJNEngineView, coordinator: Void) {
        // didMoveToWindow performs detach; the Engine is not recreated here.
    }
}
#endif
