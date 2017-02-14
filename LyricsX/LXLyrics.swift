//
//  LXLyrics.swift
//  LyricsX
//
//  Created by 邓翔 on 2017/2/5.
//  Copyright © 2017年 ddddxxx. All rights reserved.
//

import Foundation

struct LXLyricsLine {
    
    var sentence: String
    var position: Double
    
    var timeTag: String {
        let min = Int(position / 60)
        let sec = position - Double(min * 60)
        return String(format: "%02d:%06.3f", min, sec)
    }
    
    init(sentence: String, position: Double) {
        self.sentence = sentence
        self.position = position
    }
    
    init?(sentence: String, timeTag: String) {
        var tagContent = timeTag
        tagContent.remove(at: tagContent.startIndex)
        tagContent.remove(at: tagContent.index(before: tagContent.endIndex))
        let components = tagContent.components(separatedBy: ":")
        if components.count == 2,
            let min = Double(components[0]),
            let sec = Double(components[1]) {
            let position = sec + min * 60
            self.init(sentence: sentence, position: position)
        } else {
            return nil
        }
    }
    
}

struct LXLyrics {
    
    var lyrics: [LXLyricsLine]
    var idTags: [idTagKey: String]
    var metadata: [metadataKey: Any]
    
    var offset: Int {
        get {
            return idTags[.Offset].flatMap() { Int($0) } ?? 0
        }
        set {
            idTags[.Offset] = "\(offset)"
        }
    }
    
    var timeDelay: Double {
        get {
            return Double(offset) / 1000
        }
        set {
            offset = Int(timeDelay * 1000)
        }
    }
    
    init?(_ lrcContents: String) {
        lyrics = []
        idTags = [:]
        metadata = [:]
        
        guard let regexForIDTag = try? NSRegularExpression(pattern: "\\[[^\\]]+:[^\\]]+\\]"),
            let regexForTimeTag = try? NSRegularExpression(pattern: "\\[\\d+:\\d+.\\d+\\]|\\[\\d+:\\d+\\]") else {
            return
        }
        
        let lyricsLines = lrcContents.components(separatedBy: .newlines)
        for line in lyricsLines {
            let timeTagsMatched: [NSTextCheckingResult] = regexForTimeTag.matches(in: line, options: [], range: NSMakeRange(0, line.characters.count))
            if timeTagsMatched.count > 0 {
                let index: Int = timeTagsMatched.last!.range.location + timeTagsMatched.last!.range.length
                let lyricsSentence: String = line.substring(from: line.characters.index(line.startIndex, offsetBy: index))
                let lyrics = timeTagsMatched.flatMap() { result -> LXLyricsLine? in
                    let timeTagStr = (line as NSString).substring(with: result.range) as String
                    return LXLyricsLine(sentence: lyricsSentence, timeTag: timeTagStr)
                }
                self.lyrics += lyrics
            } else {
                let idTagsMatched = regexForIDTag.matches(in: line, range: NSMakeRange(0, line.characters.count))
                guard idTagsMatched.count > 0 else {
                    continue
                }
                for result in idTagsMatched {
                    var tagStr = ((line as NSString).substring(with: result.range)) as String
                    tagStr.remove(at: tagStr.startIndex)
                    tagStr.remove(at: tagStr.index(before: tagStr.endIndex))
                    let components = tagStr.components(separatedBy: ":")
                    if components.count == 2 {
                        let key = idTagKey(components[0])
                        let value = components[1]
                        idTags[key] = value
                    }
                }
            }
        }
        
        if lyrics.count == 0 {
            return nil
        }
        
        lyrics.sort() { $0.position < $1.position }
    }
    
    init?(metadata: [metadataKey: Any]) {
        if let lrcURL = metadata[.lyricsURL] as? URL, let lrcContent = try? String(contentsOf: lrcURL) {
            self.init(lrcContent)
            self.metadata = metadata
        } else {
            return nil
        }
    }
    
    subscript(_ position: Double) -> (current:LXLyricsLine?, next:LXLyricsLine?) {
        for (index, line) in lyrics.enumerated() {
            if line.position - timeDelay > position {
                let previous = lyrics.index(index, offsetBy: -1, limitedBy: lyrics.startIndex).flatMap() { lyrics[$0] }
                return (previous, line)
            }
        }
        return (lyrics.last, nil)
    }
    
    struct source {
        
        static let unknow = "unknow"
        
    }
    
}

extension LXLyrics {
    
    struct idTagKey: RawRepresentable, Hashable {
        
        var rawValue: String
        
        init(_ rawValue: String) {
            self.rawValue = rawValue
        }
        
        init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        var hashValue: Int {
            return rawValue.hash
        }
        
        static let Title: idTagKey = .init("ti")
        
        static let Album: idTagKey = .init("al")
        
        static let Artist: idTagKey = .init("ar")
        
        static let Author: idTagKey = .init("au")
        
        static let LrcBy: idTagKey = .init("by")
        
        static let Offset: idTagKey = .init("offset")
        
    }
    
    enum metadataKey {
        
        case source
        
        case lyricsURL
        
        case searchTitle
        
        case searchArtise
        
    }
    
}

// MARK: - Debug Print Support

extension LXLyrics.idTagKey: CustomStringConvertible {
    
    public var description: String {
        return rawValue
    }
    
}

extension LXLyricsLine: CustomStringConvertible {
    
    public var description: String {
        return "[\(timeTag)]\(sentence)"
    }
    
}

extension LXLyrics: CustomStringConvertible {
    
    public var description: String {
        get {
            let meta = metadata.reduce("") { $0 + "[[\($1.key): \($1.value)]]\n"}
            let tag = idTags.reduce("") { $0 + "[\($1.key): \($1.value)]\n" }
            let lrc = lyrics.reduce("") { $0 + "\($1.description)\n" }
            return meta + tag + lrc
        }
    }
    
}
