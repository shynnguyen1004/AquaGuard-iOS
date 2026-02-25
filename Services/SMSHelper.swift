//
//  SMSHelper.swift
//  AquaGuard
//
//  Extracted from SafetyView — utility for composing SMS via system URL scheme.
//

import UIKit

enum SMSHelper {
    static func send(number: String, message: String) {
        let smsString = "sms:\(number)&body=\(message)"
        if let encoded = smsString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: encoded)
        {
            UIApplication.shared.open(url)
        }
    }
}
