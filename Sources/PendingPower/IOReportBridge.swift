import Foundation

// Private IOReport.framework — loaded via dlsym at runtime.
// References: asitop, Stats.app, macmon, MX Power Gadget.

typealias IOReportSubscriptionRef = OpaquePointer

private typealias FnCopyChannelsInGroup = @convention(c) (
    CFString?, CFString?, UInt64, UInt64, UInt64
) -> Unmanaged<CFMutableDictionary>?

private typealias FnCreateSubscription = @convention(c) (
    UnsafeMutableRawPointer?,
    CFMutableDictionary,
    UnsafeMutablePointer<Unmanaged<CFMutableDictionary>?>,
    UInt64,
    CFTypeRef?
) -> IOReportSubscriptionRef?

private typealias FnCreateSamples = @convention(c) (
    IOReportSubscriptionRef, CFMutableDictionary, CFTypeRef?
) -> Unmanaged<CFDictionary>?

private typealias FnCreateSamplesDelta = @convention(c) (
    CFDictionary, CFDictionary, CFTypeRef?
) -> Unmanaged<CFDictionary>?

typealias IOReportIterateBlock = @convention(block) (CFDictionary) -> Int32
private typealias FnIterate = @convention(c) (CFDictionary, IOReportIterateBlock) -> Void

private typealias FnChannelGetCFString = @convention(c) (CFDictionary) -> Unmanaged<CFString>?
private typealias FnSimpleGetIntegerValue = @convention(c) (CFDictionary, Int32) -> Int64

final class IOReportBridge {
    static let shared: IOReportBridge? = IOReportBridge()

    private let handle: UnsafeMutableRawPointer

    private let _copyChannelsInGroup: FnCopyChannelsInGroup
    private let _createSubscription: FnCreateSubscription
    private let _createSamples: FnCreateSamples
    private let _createSamplesDelta: FnCreateSamplesDelta
    private let _iterate: FnIterate
    private let _channelGetGroup: FnChannelGetCFString
    private let _channelGetSubGroup: FnChannelGetCFString
    private let _channelGetChannelName: FnChannelGetCFString
    private let _channelGetUnitLabel: FnChannelGetCFString
    private let _simpleGetIntegerValue: FnSimpleGetIntegerValue

    private init?() {
        guard let h = dlopen("/usr/lib/libIOReport.dylib", RTLD_LAZY | RTLD_LOCAL) else {
            return nil
        }
        self.handle = h

        func sym<T>(_ name: String, as: T.Type) -> T? {
            guard let p = dlsym(h, name) else { return nil }
            return unsafeBitCast(p, to: T.self)
        }

        guard
            let s1 = sym("IOReportCopyChannelsInGroup", as: FnCopyChannelsInGroup.self),
            let s2 = sym("IOReportCreateSubscription", as: FnCreateSubscription.self),
            let s3 = sym("IOReportCreateSamples", as: FnCreateSamples.self),
            let s4 = sym("IOReportCreateSamplesDelta", as: FnCreateSamplesDelta.self),
            let s5 = sym("IOReportIterate", as: FnIterate.self),
            let s6 = sym("IOReportChannelGetGroup", as: FnChannelGetCFString.self),
            let s7 = sym("IOReportChannelGetSubGroup", as: FnChannelGetCFString.self),
            let s8 = sym("IOReportChannelGetChannelName", as: FnChannelGetCFString.self),
            let s9 = sym("IOReportChannelGetUnitLabel", as: FnChannelGetCFString.self),
            let s10 = sym("IOReportSimpleGetIntegerValue", as: FnSimpleGetIntegerValue.self)
        else {
            return nil
        }

        self._copyChannelsInGroup = s1
        self._createSubscription = s2
        self._createSamples = s3
        self._createSamplesDelta = s4
        self._iterate = s5
        self._channelGetGroup = s6
        self._channelGetSubGroup = s7
        self._channelGetChannelName = s8
        self._channelGetUnitLabel = s9
        self._simpleGetIntegerValue = s10
    }

    // MARK: - High-level wrappers

    func copyChannels(group: String, subgroup: String? = nil) -> CFMutableDictionary? {
        let g = group as CFString
        let sg = subgroup as CFString?
        return _copyChannelsInGroup(g, sg, 0, 0, 0)?.takeRetainedValue()
    }

    func createSubscription(channels: CFMutableDictionary) -> (sub: IOReportSubscriptionRef, subbed: CFMutableDictionary)? {
        var subbed: Unmanaged<CFMutableDictionary>? = nil
        guard let sub = _createSubscription(nil, channels, &subbed, 0, nil),
              let s = subbed?.takeRetainedValue()
        else {
            return nil
        }
        return (sub, s)
    }

    func createSamples(_ sub: IOReportSubscriptionRef, subbed: CFMutableDictionary) -> CFDictionary? {
        return _createSamples(sub, subbed, nil)?.takeRetainedValue()
    }

    func createSamplesDelta(prev: CFDictionary, current: CFDictionary) -> CFDictionary? {
        return _createSamplesDelta(prev, current, nil)?.takeRetainedValue()
    }

    func iterate(samples: CFDictionary, block: @escaping IOReportIterateBlock) {
        _iterate(samples, block)
    }

    func channelGroup(_ ch: CFDictionary) -> String? {
        _channelGetGroup(ch)?.takeUnretainedValue() as String?
    }
    func channelSubGroup(_ ch: CFDictionary) -> String? {
        _channelGetSubGroup(ch)?.takeUnretainedValue() as String?
    }
    func channelName(_ ch: CFDictionary) -> String? {
        _channelGetChannelName(ch)?.takeUnretainedValue() as String?
    }
    func channelUnit(_ ch: CFDictionary) -> String? {
        _channelGetUnitLabel(ch)?.takeUnretainedValue() as String?
    }
    func simpleIntegerValue(_ ch: CFDictionary) -> Int64 {
        _simpleGetIntegerValue(ch, 0)
    }
}
