import Foundation

/// Checks that every string the app asks for is translated everywhere, and
/// that no translation is left over from a string that no longer exists.
///
///     swift scripts/check-strings.swift
///
/// Exits non-zero when something is missing, so CI can run it.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let sources = root.appendingPathComponent("Sources/MemoLine")
let resources = sources.appendingPathComponent("Resources")

/// Every L("...") in the code: the key is the English text itself.
func keysInCode() -> Set<String> {
    var keys: Set<String> = []
    let files = (try? FileManager.default.contentsOfDirectory(at: sources, includingPropertiesForKeys: nil)) ?? []
    for file in files where file.pathExtension == "swift" {
        guard let text = try? String(contentsOf: file, encoding: .utf8) else { continue }
        var rest = Substring(text)
        while let start = rest.range(of: "L(\"") {
            rest = rest[start.upperBound...]
            guard let end = rest.firstIndex(of: "\"") else { break }
            keys.insert(String(rest[..<end]))
            rest = rest[end...]
        }
    }
    return keys
}

/// The keys on the left of a Localizable.strings file.
func keysInStrings(at url: URL) -> Set<String> {
    guard let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }
    var keys: Set<String> = []
    for line in text.split(separator: "\n") {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("\""), let end = trimmed.range(of: "\" =") else { continue }
        keys.insert(String(trimmed[trimmed.index(after: trimmed.startIndex)..<end.lowerBound]))
    }
    return keys
}

let wanted = keysInCode()
let languages = ((try? FileManager.default.contentsOfDirectory(at: resources, includingPropertiesForKeys: nil)) ?? [])
    .filter { $0.pathExtension == "lproj" }
    .sorted { $0.lastPathComponent < $1.lastPathComponent }

guard !languages.isEmpty else {
    print("No .lproj folders in \(resources.path)")
    exit(1)
}

var failed = false
for language in languages {
    let file = language.appendingPathComponent("Localizable.strings")
    let have = keysInStrings(at: file)
    let missing = wanted.subtracting(have).sorted()
    let extra = have.subtracting(wanted).sorted()
    let name = language.deletingPathExtension().lastPathComponent
    if missing.isEmpty && extra.isEmpty {
        print("\(name): \(have.count) strings, all good")
    } else {
        failed = true
        print("\(name):")
        for key in missing { print("  missing: \(key)") }
        for key in extra { print("  no longer used: \(key)") }
    }
}

exit(failed ? 1 : 0)
