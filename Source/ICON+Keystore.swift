/*
 * Copyright 2018 ICON Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

import Foundation
import CryptoSwift

public struct Keystore: Codable {
    public let version: Int = 3
    public var id: String = UUID().uuidString
    public var address: String
    public var crypto: Crypto
    public var coinType: String = "icx"
    
    public struct Crypto: Codable {
        public let ciphertext: String
        public let cipherparams: CipherParams
        public let cipher: String
        public let kdf: String
        public let kdfparams: KDF
        public let mac: String
    }
    
    public struct CipherParams: Codable {
        public let iv: String
    }
    
    public struct KDF: Codable {
        public let dklen: Int
        public let salt: String
        public var c: Int?
        public var n: Int?
        public var p: Int?
        public var r: Int?
        public var prf: String?
        
        init(dklen: Int, salt: String) {
            self.dklen = dklen
            self.salt = salt
        }
    }
    
    public init(address: String, crypto: Crypto) {
        self.address = address
        self.crypto = crypto
    }
    
    public static func load(jsonData: Data, password: String) throws -> Keystore {
        let decoder = JSONDecoder()
        let keystore = try decoder.decode(Keystore.self, from: jsonData)
        
        return keystore
    }
}

extension Keystore {
    public func extract(password: String) throws -> PrivateKey {
        if crypto.kdf == "pbkdf2" {
            guard let enc = crypto.ciphertext.hexToData(),
                let iv = crypto.cipherparams.iv.hexToData(),
                let salt = crypto.kdfparams.salt.hexToData(),
                let count = crypto.kdfparams.c else { throw ICError.invalid(reason: .malformedKeystore) }
            
            guard let devKeyArray = Cipher.pbkdf2(password: password, salt: salt, keyByteCount: PBE_DKLEN, round: count) else { throw ICError.fail(reason: .decrypt) }
            let devKey = Data(devKeyArray)
            let decrypted = try Cipher.decrypt(devKey: devKey, enc: enc, dkLen: PBE_DKLEN, iv: iv)
            
            if self.crypto.mac == decrypted.mac {
                return PrivateKey(hex: Data(hex: decrypted.decryptText))
            }
        } else if crypto.kdf == "scrypt" {
            guard let n = crypto.kdfparams.n,
                let p = crypto.kdfparams.p,
                let r = crypto.kdfparams.r,
                let iv = crypto.cipherparams.iv.hexToData(),
                let cipherText = crypto.ciphertext.hexToData(),
                let salt = crypto.kdfparams.salt.hexToData() else { throw ICError.invalid(reason: .malformedKeystore) }
            
            guard let devKey = Cipher.Scrypt(password: password, saltData: salt, dkLen: crypto.kdfparams.dklen, N: n, R: r, P: p) else { throw ICError.fail(reason: .decrypt) }
            
            let decrypted = try Cipher.decrypt(devKey: devKey, enc: cipherText, dkLen: PBE_DKLEN, iv: iv)
            
            if self.crypto.mac == decrypted.mac {
                return PrivateKey(hex: Data(hex: decrypted.decryptText))
            }
        }
        throw ICError.invalid(reason: .malformedKeystore)
    }
    
    public func jsonData() throws -> Data {
        let encoder = JSONEncoder()
        
        return try encoder.encode(self)
    }
}

extension Wallet {
    private var R_STANDARD: Int {
        return 8
    }
    private var N_STANDARD: Int {
        return 1 << 14
    }
    private var P_STANDARD: Int {
        return 1
    }
    
    public func generateKeystore(password: String) throws -> Keystore {
        let prvKey = self.key.privateKey.data
        let address = Cipher.makeAddress(self.key.privateKey, self.key.publicKey)
        
        let salt = try Cipher.randomData(count: 32)
        
        guard let derivedKey = Cipher.Scrypt(password: password, saltData: salt, dkLen: PBE_DKLEN, N: N_STANDARD, R: R_STANDARD, P: P_STANDARD) else { throw ICError.message(error: "Key modular failed") }
        
        let encrypted = try Cipher.encrypt(devKey: derivedKey, data: prvKey, salt: salt)
        
        let cipherParams = Keystore.CipherParams(iv: encrypted.iv)
        var kdfParams = Keystore.KDF(dklen: PBE_DKLEN, salt: salt.hexEncodedString())
        kdfParams.n = N_STANDARD
        kdfParams.p = P_STANDARD
        kdfParams.r = R_STANDARD
        let crypto = Keystore.Crypto(ciphertext: encrypted.cipherText, cipherparams: cipherParams, cipher: "aes-128-ctr", kdf: "scrypt", kdfparams: kdfParams, mac: encrypted.mac)
        
        let keystore = Keystore(address: address, crypto: crypto)
        
        return  keystore
    }
}
