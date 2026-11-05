import Foundation
import LightCore

let args = Array(CommandLine.arguments.dropFirst())
let language = StateStore().load().language
do {
    switch args.first {
    case "status":
        let device = try HIDTransport.status()
        print("\(device.name) · \(device.details)")
    case "recommend":
        let recommendation = RecommendationEngine.recommend(at: Date(), language: language)
        print("\(recommendation.preset.localizedName(in: language)) · \(recommendation.preset.color.hex)")
        print(recommendation.context)
        print(recommendation.explanation)
    case "color", "dry-run":
        guard args.count >= 2, let color = RGB(hex: args[1]) else {
            throw NSError(domain: "CLI", code: 1, userInfo: [NSLocalizedDescriptionKey: language.text(.cliColor)])
        }
        let brightness: Int
        if args.count > 2 {
            guard let value = Int(args[2]), (0...100).contains(value) else {
                throw NSError(domain: "CLI", code: 2, userInfo: [NSLocalizedDescriptionKey: language.text(.cliBrightness)])
            }
            brightness = value
        } else { brightness = 100 }
        let packet = LightProtocol.color(color, brightness: brightness)
        if args[0] == "dry-run" { print(packet.map { String(format: "%02X", $0) }.joined(separator: " ")) }
        else {
            try HIDTransport.send(packet)
            let store = StateStore()
            var state = store.load()
            state.color = color; state.brightness = brightness; state.lastApplied = Date(); state.lastCommandWasOff = false
            try store.save(state)
            print(language.text(.colorSent, color.hex, String(brightness)))
        }
    case "off":
        try HIDTransport.send(LightProtocol.off)
        let store = StateStore()
        var state = store.load()
        state.lastCommandWasOff = true; state.lastApplied = Date()
        try store.save(state)
        print(language.text(.offSent))
    default:
        print("lumactl status | recommend | dry-run '#RRGGBB' [0…100] | color '#RRGGBB' [0…100] | off")
    }
} catch {
    let message = (error as? LightError)?.localizedDescription(in: language) ?? error.localizedDescription
    fputs("\(message)\n", stderr)
    exit(1)
}
