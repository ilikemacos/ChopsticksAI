// chopsticksAI retrieval engine.
//
// Scoring must stay identical to js/chopsticks-ai.js: same normalisation, same
// word-boundary matching, same weights, same tie-break. chopsticks-ai/fixtures.json
// is run against both and they must agree.

enum ChopsticksAI {
    static let confidenceFloor = 4

    struct Result {
        let answer: String
        let confident: Bool
        let intent: ChopsticksAIIntent?
        let suggestions: [ChopsticksAIIntent]
    }

    static func normalise(_ text: String) -> String {
        var out = ""
        out.reserveCapacity(text.count)
        var lastWasSpace = true
        for ch in text.lowercased() {
            if ch.isLetter || ch.isNumber {
                out.append(ch)
                lastWasSpace = false
            } else if !lastWasSpace {
                out.append(" ")
                lastWasSpace = true
            }
        }
        if out.hasSuffix(" ") { out.removeLast() }
        return out
    }

    private struct Scored {
        let intent: ChopsticksAIIntent
        let score: Int
    }

    static func rank(_ query: String) -> [ChopsticksAIIntent] {
        scored(query).map { $0.intent }
    }

    private static func scored(_ query: String) -> [Scored] {
        let text = normalise(query)
        guard !text.isEmpty else { return [] }
        // Padding lets a plain containment check act as a word-boundary check,
        // which is what stops "unzip" matching the "zip" term.
        let padded = " " + text + " "

        var results: [Scored] = []
        for intent in ChopsticksAIKB.intents {
            var total = 0
            for (term, weight) in intent.terms where padded.contains(" " + term + " ") {
                total += weight
            }
            if total > 0 {
                results.append(Scored(intent: intent, score: total))
            }
        }

        results.sort { a, b in
            if a.score != b.score { return a.score > b.score }
            if a.intent.priority != b.intent.priority { return a.intent.priority > b.intent.priority }
            return a.intent.id < b.intent.id
        }
        return results
    }

    static func ask(_ query: String) -> Result {
        let ranked = scored(query)

        guard let top = ranked.first, top.score >= confidenceFloor else {
            let hints = ranked.prefix(3).map { $0.intent }
            var answer = "I'm not sure about that one.\n\nI know about rNitro, Fathom Air, Fathom Pro, ARENA, installing, and privacy. Try rephrasing"
            if hints.isEmpty {
                answer += "."
            } else {
                answer += ", or ask about:\n" + hints.map { "• " + $0.label }.joined(separator: "\n")
            }
            return Result(answer: answer, confident: false, intent: nil, suggestions: Array(hints))
        }

        let related = ranked.dropFirst().prefix(3).map { $0.intent }
        var answer = top.intent.answer
        if !related.isEmpty {
            answer += "\n\nRelated:\n" + related.map { "• " + $0.label }.joined(separator: "\n")
        }
        return Result(answer: answer, confident: true, intent: top.intent, suggestions: Array(related))
    }
}
