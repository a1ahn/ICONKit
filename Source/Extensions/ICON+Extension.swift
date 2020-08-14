//
//  ICON+Extension.swift
//  ICONKit-ios
//
//  Created by nha1a on 2020/07/07.
//  Copyright © 2020 ICONTROL. All rights reserved.
//

import Foundation

extension ICONService {
    
    public enum Service {
        case yeouido
        case euljiro
        case main
        
        var node: ICONService {
            switch self {
            case .yeouido:
                return ICONService(provider: "https://bicon.net.solidwallet.io", nid: "0x3")
                
            case .euljiro:
                return ICONService(provider: "https://test-ctz.solidwallet.io", nid: "0x2")
                
            case .main:
                return ICONService(provider: "https://ctz.solidwallet.io", nid: "0x1")
            }
        }
    }
}
