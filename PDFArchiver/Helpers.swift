//
//  TagHandling.swift
//  PDF Archiver
//
//  Created by Julian Kahnert on 21.01.18.
//  Copyright © 2018 Julian Kahnert. All rights reserved.
//

import Foundation
import Quartz
import os.log
import SystemConfiguration

// MARK: check network connection
func connectedToNetwork() -> Bool {
    // source: https://stackoverflow.com/a/25623647
    var zeroAddress = sockaddr_in()
    zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
    zeroAddress.sin_family = sa_family_t(AF_INET)

    guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            SCNetworkReachabilityCreateWithAddress(nil, $0)
        }
    }) else {
        return false
    }

    var flags: SCNetworkReachabilityFlags = []
    if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
        return false
    }

    let isReachable = flags.contains(.reachable)
    let needsConnection = flags.contains(.connectionRequired)

    return (isReachable && !needsConnection)
}

// MARK: check dialog window
func dialogOK(messageKey: String, infoKey: String, style: NSAlert.Style) {
    let alert = NSAlert()
    alert.messageText = NSLocalizedString(messageKey, comment: "")
    alert.informativeText = NSLocalizedString(infoKey, comment: "")
    alert.alertStyle = style
    alert.addButton(withTitle: "OK")
    alert.runModal()
}

// MARK: other string stuff
func regex_matches(for regex: String, in text: String) -> [String]? {

    do {
        let regex = try NSRegularExpression(pattern: regex)
        let results = regex.matches(in: text,
                                    range: NSRange(text.startIndex..., in: text))
        let output = results.map({ String(text[Range($0.range, in: text)!]) })
        if output.count == 0 {
            return nil
        } else {
            return output
        }
    } catch let error as NSError {
        let log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "Helpers")
        os_log("Invalid regex: %@", log: log, type: .error, error.description)
        return nil
    }
}

func getSubstring(_ raw: String, startIdx: Int, endIdx: Int) -> String {
    let start = raw.index(raw.startIndex, offsetBy: startIdx)
    let end = raw.index(raw.endIndex, offsetBy: endIdx)
    return String(describing: raw[start..<end])
}

func slugifyTag(_ rawIn: String) -> String {
    // normalize description
    var raw = rawIn.lowercased()
    raw = raw.replacingOccurrences(of: "[:;.,!?/\\^+<>#@|]", with: "",
                                   options: .regularExpression, range: nil)
    raw = raw.replacingOccurrences(of: " ", with: "")
    // german umlaute
    raw = raw.replacingOccurrences(of: "ä", with: "ae")
    raw = raw.replacingOccurrences(of: "ö", with: "oe")
    raw = raw.replacingOccurrences(of: "ü", with: "ue")
    return raw.replacingOccurrences(of: "ß", with: "ss")
}
