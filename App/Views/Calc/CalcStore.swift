import Foundation
import BloomCore

@Observable
final class CalcStore {
    var display: String = "0"
    var expression: String = " "
    var memoryValue: Double = 0 {
        didSet { JSONStore.shared.set(.memory, memoryValue) }
    }
    var lastEgg: Egg?
    var eggEpoch: Int = 0

    private var engine = CalcEngine()
    private var sequence: [String] = []
    private weak var history: HistoryStore?
    private weak var sounds: SoundStore?

    init(history: HistoryStore?, sounds: SoundStore?) {
        self.history = history
        self.sounds = sounds
        memoryValue = JSONStore.shared.get(.memory, as: Double.self) ?? 0
    }

    init() {
        self.history = nil
        self.sounds = nil
        memoryValue = JSONStore.shared.get(.memory, as: Double.self) ?? 0
    }

    func press(_ key: String) {
        switch key {
        case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
            guard let d = key.first else { return }
            engine.digit(d)
            sequence.append(key)
            refreshDisplay()
            sounds?.play("d\(d)")
        case ".":
            engine.dot()
            sequence.append(".")
            refreshDisplay()
            sounds?.play("dot")
        case "+":
            engine.setOp(.add)
            sequence.append("+")
            refreshDisplay()
            sounds?.play("op+")
        case "-":
            engine.setOp(.subtract)
            sequence.append("−")
            refreshDisplay()
            sounds?.play("op-")
        case "*":
            engine.setOp(.multiply)
            sequence.append("×")
            refreshDisplay()
            sounds?.play("op*")
        case "/":
            engine.setOp(.divide)
            sequence.append("÷")
            refreshDisplay()
            sounds?.play("op/")
        case "=":
            handleEquals()
        case "C":
            engine.clearAll()
            sequence.removeAll()
            refreshDisplay()
            sounds?.play("clear")
        case "±":
            engine.toggleSign()
            refreshDisplay()
            sounds?.play("sign")
        case "%":
            engine.percent()
            refreshDisplay()
            sounds?.play("percent")
        case "⌫":
            engine.backspace()
            if !sequence.isEmpty {
                sequence.removeLast()
            }
            refreshDisplay()
            sounds?.play("clear")
        case "MC":
            memoryValue = 0
            sounds?.play("memory")
        case "MR":
            recallMemory()
            sounds?.play("memory")
        case "M+":
            if let value = Double(display) {
                memoryValue += value
            }
            sounds?.play("memory")
        case "M-":
            if let value = Double(display) {
                memoryValue -= value
            }
            sounds?.play("memory")
        default:
            break
        }
    }

    func recycle(tokens: [String]) {
        engine.clearAll()
        sequence.removeAll()
        for token in tokens {
            press(token)
        }
    }

    private func handleEquals() {
        guard let result = engine.equals() else {
            refreshDisplay()
            return
        }
        display = result.display
        expression = result.expression

        let tokenSequence = result.sequence
        if display == "Error" {
            sounds?.play("error")
        } else {
            history?.add(
                type: "calc",
                title: "Calculation",
                value: display,
                extra: ["tokens": tokenSequence]
            )
            if let egg = EasterEggs.match(sequence: tokenSequence) {
                lastEgg = egg
                eggEpoch += 1
                sounds?.play("easteregg")
            } else {
                sounds?.play("equals")
            }
        }
        sequence.removeAll()
    }

    private func refreshDisplay() {
        display = engine.displayText
        expression = engine.expressionText
    }

    private func recallMemory() {
        engine.clearAll()
        sequence.removeAll()
        let magnitude = BloomCore.Formatters.plain(abs(memoryValue))
        for character in magnitude {
            if character == "." {
                engine.dot()
            } else {
                engine.digit(character)
            }
        }
        if memoryValue < 0 {
            engine.toggleSign()
        }
        refreshDisplay()
    }
}
