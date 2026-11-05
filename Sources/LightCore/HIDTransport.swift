import Foundation
import IOKit.hid

public enum LightError: LocalizedError {
    case notFound, multipleDevices, deviceBusy(Int32), writeFailed(Int32)
    public var errorDescription: String? { localizedDescription(in: .system) }
    public func localizedDescription(in language: AppLanguage) -> String {
        switch self {
        case .notFound: return language.text(.notFound)
        case .multipleDevices: return language.text(.multipleDevices)
        case .deviceBusy(let code): return language.text(.deviceBusy, String(code))
        case .writeFailed(let code): return language.text(.writeFailed, String(code))
        }
    }
}

public struct DeviceInfo: Sendable {
    public let name: String
    public let details: String
}

public enum HIDTransport {
    private static func withDevice<T>(_ body: (IOHIDDevice) throws -> T) throws -> T {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        defer { IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone)) }
        let matching: [String: Any] = [kIOHIDVendorIDKey: LightProtocol.vendorID, kIOHIDProductIDKey: LightProtocol.productID]
        IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)
        guard let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice>, !devices.isEmpty else {
            throw LightError.notFound
        }
        let preferred = devices.filter {
            (IOHIDDeviceGetProperty($0, kIOHIDPrimaryUsagePageKey as CFString) as? NSNumber)?.intValue == 0xFF00
        }
        let choices = preferred.isEmpty ? Array(devices) : Array(preferred)
        guard choices.count == 1, let device = choices.first else { throw LightError.multipleDevices }
        return try body(device)
    }

    public static func status() throws -> DeviceInfo {
        try withDevice { device in
            let name = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String ?? "ROBOBLOQ USBHID"
            return DeviceInfo(name: name, details: "USB · 96 LED · 1A86:FE07")
        }
    }

    public static func send(_ packet: [UInt8]) throws {
        try sendPackets([packet], delays: [0])
    }

    public static func fade(from start: RGB, to end: RGB, didWrite: (LightTransition.Frame) -> Void) throws {
        let frames = LightTransition.blackoutFrames(from: start, to: end)
        try sendPackets(frames.map { LightProtocol.color($0.color) }, delays: frames.map(\.delayBefore)) { index in
            didWrite(frames[index])
        }
    }

    private static func sendPackets(_ packets: [[UInt8]], delays: [TimeInterval], didWrite: (Int) -> Void = { _ in }) throws {
        try withDevice { device in
            let result = IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeSeizeDevice))
            guard result == kIOReturnSuccess else { throw LightError.deviceBusy(result) }
            // Closing a handle must not send an OFF command: the controller keeps its color.
            defer { IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone)) }
            for (index, packet) in packets.enumerated() {
                // One handle throughout the fade-out, dark pause, and fade-in.
                if delays[index] > 0 { Thread.sleep(forTimeInterval: delays[index]) }
                let resultCode = packet.withUnsafeBufferPointer { buffer in
                    IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, 0, buffer.baseAddress!, buffer.count)
                }
                guard resultCode == kIOReturnSuccess else { throw LightError.writeFailed(resultCode) }
                didWrite(index)
            }
        }
    }
}
