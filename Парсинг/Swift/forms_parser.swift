#!/usr/bin/env swift
// forms_parser.swift
// Read forms.txt, extract Name/Phone/Email using regex, write forms.json
// Run: swift forms_parser.swift

import Foundation

let inputPath = "forms.txt"
let outputPath = "forms.json"

// Read file
guard let rawText = try? String(contentsOfFile: inputPath, encoding: .utf8) else {
    fputs("Failed to read \(inputPath)\n", stderr)
    exit(1)
}

// Normalize newlines to "\n"
let text = rawText.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")

// Extract blocks separated by one or more blank lines (robust to spaces/tabs)
func extractBlocks(_ s: String) -> [String] {
    let pattern = "(?s)(?:^|\\n[ \\t]*\\n)(.*?)(?=\\n[ \\t]*\\n|$)"
    guard let re = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
    let ns = s as NSString
    let matches = re.matches(in: s, options: [], range: NSRange(location: 0, length: ns.length))
    var blocks: [String] = []
    for m in matches {
        let r = m.range(at: 1)
        if r.location != NSNotFound, r.length > 0 {
            let block = ns.substring(with: r).trimmingCharacters(in: .whitespacesAndNewlines)
            if !block.isEmpty {
                blocks.append(block)
            }
        }
    }
    return blocks
}

let blocks = extractBlocks(text)

// Helper to run regex (case insensitive, anchors match lines)
func firstMatch(_ pattern: String, in text: String) -> String? {
    let options: NSRegularExpression.Options = [.caseInsensitive, .anchorsMatchLines]
    guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return nil }
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    if let m = regex.firstMatch(in: text, options: [], range: range) {
        if m.numberOfRanges >= 2, let r = Range(m.range(at: 1), in: text) {
            return String(text[r]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    return nil
}

var resultArray: [[String:String]] = []

for block in blocks {
    // Patterns: capture after "Name:" etc. allow optional spaces
    let name = firstMatch("^[ \\t]*Name\\s*:\\s*(.+)$", in: block) ?? ""
    let phone = firstMatch("^[ \\t]*Phone\\s*:\\s*(.+)$", in: block) ?? ""
    let email = firstMatch("^[ \\t]*Email\\s*:\\s*(.+)$", in: block) ?? ""
    resultArray.append([
        "name": name,
        "phone": phone,
        "email": email
    ])
}

// Encode to JSON
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

do {
    let data = try encoder.encode(resultArray)
    try data.write(to: URL(fileURLWithPath: outputPath))
    print("Wrote \(outputPath) with \(resultArray.count) records.")
} catch {
    fputs("Failed to write JSON: \(error)\n", stderr)
    exit(1)
}
