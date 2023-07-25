import CoreAudio

class AudioDevice {
    let deviceID: AudioDeviceID

    init(deviceID: AudioDeviceID) {
        self.deviceID = deviceID
    }

    /**
     * Returns the name of the device.
     */
    func getName() -> String {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var name: CFString = "" as CFString
        var propertySize = UInt32(MemoryLayout<CFString>.size)
        let status = AudioObjectGetPropertyData(
            self.deviceID,
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &name
        )
        if status != noErr {
            return ""
        }
        return name as String
    }

    /**
     * Returns whether the device is an input device.
     */
    func isInputDevice() -> Bool {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        var propertySize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(
            self.deviceID,
            &propertyAddress,
            0,
            nil,
            &propertySize
        )
        if status != noErr {
            return false
        }
        return propertySize > 0
    }
}

/**
 * Produces list of all input devices.
 * Can also switch the active input device.
 */
class AudioDevices {
    /**
     * Returns list of all input devices.
     */
    static func getInputDevices() -> [AudioDevice] {
        var devices: [AudioDevice] = []
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var propertySize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize
        )
        if status != noErr {
            return devices
        }
        let deviceCount = Int(propertySize) / MemoryLayout<AudioDeviceID>.size
        let deviceIDs = UnsafeMutablePointer<AudioDeviceID>.allocate(capacity: deviceCount)
        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            deviceIDs
        )
        if status != noErr {
            return devices
        }
        for i in 0..<deviceCount {
            let deviceID = deviceIDs[i]
            let device = AudioDevice(deviceID: deviceID)
            if device.isInputDevice() {
                devices.append(device)
            }
        }
        return devices
    }

    /**
     * Returns the active input device.
     */
    static func getActiveInputDevice() -> AudioDevice? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID: AudioDeviceID = 0
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &deviceID
        )
        if status != noErr {
            return nil
        }
        return AudioDevice(deviceID: deviceID)
    }

    /**
     * Sets the active input device.
     */
    static func setActiveInputDevice(_ device: AudioDevice) {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = device.deviceID
        let propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            propertySize,
            &deviceID
        )
        if status != noErr {
            return
        }
    }

    /**
     * Sets balance of current output device to center
     */
    static func balanceCenter() -> Bool {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID: AudioDeviceID = 0
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &deviceID
        )
        if status != noErr {
            return false
        }

        propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStereoPan,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var balance: Float32 = 0
        propertySize = UInt32(MemoryLayout<Float32>.size)
        status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &balance
        )
        if status != noErr {
            return false
        }

        if balance == 0.5 {
            return false
        }

        balance = 0.5
        status = AudioObjectSetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            propertySize,
            &balance
        )
        if status != noErr {
            return false
        }

        return true
    }
}
