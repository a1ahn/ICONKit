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
import Result
import BigInt

open class Request<T: Decodable>: Sendable {
    private let jsonrpc = "2.0"
    private let id: Int
    var provider: String
    var method: ICON.METHOD
    var params: [String: Any]?
    
    init(id: Int, provider: String, method: ICON.METHOD, params: [String: Any]?) {
        self.id = id
        self.provider = provider
        self.method = method
        self.params = params
    }
}

extension Request {
    public func execute() -> Result<T, ICError> {
        let result = self.send()
        
        switch result {
        case .failure(let error):
            return .failure(error)
            
        case .success(let data):
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            do {
                let decoded = try decoder.decode(T.self, from: data)
                
                return .success(decoded)
            } catch {
                return .failure(ICError.fail(reason: .parsing))
            }
        }
    }
    
    public func async(_ completion: @escaping (Result<T, ICError>) -> Void){
        self.send { (result) in
            switch result {
            case .failure(let error):
                completion(.failure(error))
                return
                
            case .success(let data):
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                do {
                    let decoded = try decoder.decode(T.self, from: data)
                    completion(.success(decoded))
                    return
                } catch {
                    completion(.failure(ICError.fail(reason: .parsing)))
                }
            }
        }
    }
}

extension ICONService {
    public func getTotalSupply() -> Request<Response.IntValue> {
        return Request<Response.IntValue>(id: self.getID(), provider: self.provider, method: .getTotalSupply, params: nil)
    }
    
    public func getBalance(address: String) -> Request<Response.IntValue> {
        return Request<Response.IntValue>(id: self.getID(), provider: self.provider, method: .getBalance, params: ["address": address])
    }
    
    public func getBlock(height: UInt64) -> Request<Response.Block> {
        return Request<Response.Block>(id: self.getID(), provider: self.provider, method: .getBlockByHeight, params: ["height": "0x" + String(height, radix: 16)])
    }
    
    public func getBlock(hash: String) -> Request<Response.Block> {
        return Request<Response.Block>(id: self.getID(), provider: self.provider, method: .getBlockByHash, params: ["hash": hash])
    }
    
    public func getLastBlock() -> Request<Response.Block> {
        return Request<Response.Block>(id: self.getID(), provider: self.provider, method: .getLastBlock, params: nil)
    }
    
    public func getScoreAPI(scoreAddress: String) -> Request<Response.ScoreAPI> {
        return Request<Response.ScoreAPI>(id: self.getID(), provider: self.provider, method: .getScoreAPI, params: ["address": scoreAddress])
    }
    
    public func getTransaction(hash: String) -> Request<Response.Transaction> {
        return Request<Response.Transaction>(id: self.getID(), provider: self.provider, method: .getTransactionByHash, params: ["txHash": hash])
    }
    
    public func getTransactionResult(hash: String) -> Request<Response.TransactionResult> {
        return Request<Response.TransactionResult>(id: self.getID(), provider: self.provider, method: .getTransactionResult, params: ["txHash": hash])
    }
}
