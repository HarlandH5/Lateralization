//
//  Lateralization.swift
//
//
//  Created by Harland Harrison on 9/10/24.
//



import Foundation
import SwiftUI
import AppKit

// Preference for left hemisphere over right hemisphere
// Experiment showed this key parameter can be very small!
let biasPercent = 1

// 1000 words per day during 2nd year of life
let exposure = 365000

// -h for help
var cmdArgs = CommandLine.arguments

var fileSystemSingleton = FileSystem()
var RA:[String] = []
var lib:[String:Bool] = [:]
var total = 0
var first = ""
var last = ""
var middle = ""

// Wrapper for the macOS FileManager class
class FileSystem {
    private var fileMgr:FileManager
    private var bundle:Bundle
    
    init() {
        fileMgr = FileManager.default // Singleton for all processes
        bundle = Bundle.main
    }

    // FileManager appears to accept ./ as an existing file
    func fileExists(path:String?) -> Bool {
        if var testPath = path {
            testPath = testPath.replacingOccurrences(of: "/", with:"")
            testPath = testPath.replacingOccurrences(of: ".", with:"")
            testPath = testPath.replacingOccurrences(of: " ", with:"")
            if testPath.count > 0 {
                return fileMgr.fileExists(atPath: path!)
            }
        }
        return false
    }
    
    
    func readFile(path: String?) -> String? {
        guard let path = path else {
            return nil
        }
        guard fileExists(path:path) else {
            return nil
        }
        
        let data:Data? = fileMgr.contents(atPath: path)
        if let data:Data = data {
            if let utf8String = String(data: data, encoding: .utf8) {
                return utf8String }
            if let nonLossyASCIIString = String(data: data, encoding: .nonLossyASCII) {
                return nonLossyASCIIString }
            if let asciiString = String(data: data, encoding: .ascii) {
                return asciiString }
            if let macOSRomanString = String(data: data, encoding: .macOSRoman) {
                return macOSRomanString }
            else
            {
                print("readFile: UNKNOWN DATA TYPE: \(data)")
                let str64 = data.base64EncodedString(options:[])
                return str64
            }
        }
        return nil
    }
}

func initialize() {
    print("\nLateralization.swift = Test a theory of cerebral lateralization by corpus callosum delay")
    print("   Lateralization.swift -h for help\n")
}

func format(_ contents:String) -> [String] {
    var str = contents.uppercased()
    str = str.replacingOccurrences(of: "\n", with:" ")
    str = str.replacingOccurrences(of: "\r", with:" ")
    var count = 0
    while count != str.count {
        count = str.count
        str = str.replacingOccurrences(of: "  ", with:" ")
    }
    total = total + count
    let RA:[String] = str.split(separator: " ").map(String.init)
    return RA
}


func results() {
    guard lib.count > 1 else {return}
    var rightHemi = 0
    let keys = lib.keys.map {String($0)}
    for key in keys {
        if lib[key]! {
            rightHemi = rightHemi+1
        }
    }
    print("vocabulary: \(keys.count)  right hemispere: \(rightHemi) total words: \(total)\n")
}

func randomHemisphere() -> Bool {
    let result = randomInt(zeroTo:100) > 50+biasPercent
    return result
}

func parse(_ contents:String) {
    RA = format(contents)
    for wordIndex in 0..<RA.count {
        let word = RA[wordIndex]
        if lib[word] == nil {
            lib[word] = randomHemisphere()
        }
        first = middle
        middle = last
        last = word
        if (lib[first] == lib[last]) && (lib[middle] != lib[last]) {
            lib[middle] = !lib[middle]!
            // lib[middle] = randomHemisphere()
        }
    }
}

func parseFile(_ filename:String) {
    if !fileSystemSingleton.fileExists(path:filename) {
        error("File not found \"\(filename)\"")
        return
    }
    let content = fileSystemSingleton.readFile(path:filename)
    guard let content = content else {
        error("File not readable \"\(filename)\"",fatal:true)
        return
    }
    parse(content)
}


func error(_ err:String, fatal:Bool = false) {
    print(err)
    if fatal {exit (-1)}
}


func randomInt(zeroTo:UInt32? = nil) -> UInt32 {
    var val = arc4random()
    if let zeroTo = zeroTo {
        val=val%(zeroTo+1)
    }
    return val
}

func helpMessage() {
    print (
    """
    
        Format is:  Lateralization.swift  [-h] \"File_Name\" ...
         where File_Name's are plain text, .txt, or equivalent files.)
    
        Cerebral lateralization gives people a favored hand, 
        (more often the right hand, but many are left handed).
        Lateralization also establishes a speech center in one
        hemisphere, usally the same hemisphere as handedness
        but not always. The mechanism is unknown.
    
        Situs inversus, organs on the 'wrong' side, is a very
        rare condition, while left-handedness is quite common.
        This suggests theories that left-handedness is somehow
        developmental. A theory of minimal brain injury to the
        dominant hemisphere has been disproven.
        
        The corpus callosum connects the two hemispheres with
        the longest, and so the slowest, axons in the cerebrum.
        This suggests a theory that lateralization optimizes
        the speed of thought, speech, and movement, by minimizing
        the use of the slower connections.
    
        Lateralization.swift is a simulation to test how much
        initial bias is needed for a sequence of words learned
        in normal speech to concentrate in one hemisphere. The
        bias was set internally at 1% when it was found that 
        very little bias was, in fact, necessary.
    
        To run Lateralization.swift, use a complete path to any
        large, plain text file, .txt, in any language.
    
    """
    )
}

// main


initialize()

if  cmdArgs.count < 2 {
    helpMessage()
    exit(1)
}

while total < exposure {
    for i in 1...cmdArgs.count-1 {
        if cmdArgs[i].hasPrefix("-h") {
            if total == 0 {
                helpMessage()
            }
        } else {
            parseFile(cmdArgs[i])
        }
    }
}
results()

