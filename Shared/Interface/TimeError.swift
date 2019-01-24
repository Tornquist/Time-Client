//
//  TimeError.swift
//  Shared
//
//  Created by Nathan Tornquist on 1/24/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import Foundation

public enum TimeError: Error {
    case unableToSendRequest(String)
    case unableToDecodeResponse()
    case requestFailed(String)
    case httpFailure(String)
    case authenticationFailure(String)
    
    case tokenNotFound()
    case unableToRefreshToken()
}

extension TimeError: Equatable {
    public static func == (lhs: TimeError, rhs: TimeError) -> Bool {
        switch (lhs, rhs) {
        case (.unableToSendRequest, .unableToSendRequest):
            return true
        case (.unableToDecodeResponse, .unableToDecodeResponse):
            return true
        case (.requestFailed, .requestFailed):
            return true
        case (.httpFailure, .httpFailure):
            return true
        case (.authenticationFailure, .authenticationFailure):
            return true
        case (.tokenNotFound, .tokenNotFound):
            return true
        case (.unableToRefreshToken, .unableToRefreshToken):
            return true
        case (.unableToSendRequest, _), (.unableToDecodeResponse, _), (.requestFailed, _), (.httpFailure, _), (.authenticationFailure, _), (.tokenNotFound, _), (.unableToRefreshToken, _):
            return false
        }
    }
}
