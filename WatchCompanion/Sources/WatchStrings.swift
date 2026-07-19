import Foundation

enum WatchStrings {
    static let actionCompleted = localized("action.completed")
    static let allDevices = localized("devices.all")
    static let applyBrightness = localized("light.apply_brightness")
    static let blue = localized("color.blue")
    static let close = localized("cover.close")
    static let connecting = localized("connection.connecting")
    static let devices = localized("devices.title")
    static let green = localized("color.green")
    static let lock = localized("lock.lock")
    static let myDevices = localized("devices.mine")
    static let noDevices = localized("devices.empty")
    static let open = localized("cover.open")
    static let openPhone = localized("connection.open_phone")
    static let press = localized("action.press")
    static let red = localized("color.red")
    static let run = localized("action.run")
    static let search = localized("search.placeholder")
    static let stop = localized("cover.stop")
    static let turnOff = localized("action.turn_off")
    static let turnOn = localized("action.turn_on")
    static let unlock = localized("lock.unlock")
    static let white = localized("color.white")

    private static func localized(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }
}
