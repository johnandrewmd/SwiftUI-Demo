//
//  DataRepository.swift
//  TheSwiftUI
//
//  Created by John Daugdaug on 5/28/25.
//

import Combine

protocol BaseDataRepositoryProtocol {
    var dbContainer: DSProductProtocol { get }
    var apiClient: DSProductProtocol { get }

    init(dbContainer: DSProductProtocol, dataClient: DSProductProtocol)
}

protocol BaseDataRepositoryWithErrorProtocol {
    var error: PassthroughSubject<APIConstants.AppError, Error> { get }
}

actor ProductDataRepository: @preconcurrency BaseDataRepositoryWithErrorProtocol {
    private(set) var dbContainer: DSProductProtocol
    private(set) var dataClient: DSProductProtocol
    private(set) var error = PassthroughSubject<APIConstants.AppError, Error>()
    
    private(set) var products = PassthroughSubject<(list: [MProduct], total: Int), Error>()
    private(set) var product = PassthroughSubject<MProduct, Error>()
    private(set) var isLoading = PassthroughSubject<Bool, Error>()
    
    init(dbContainer: DSProductProtocol = DSProductDBDataService(),
         dataClient: DSProductProtocol = DSProductAPIDataService()) {
        self.dbContainer = dbContainer
        self.dataClient = dataClient
    }
}
extension ProductDataRepository {
    func getProductListing(page: Int, size: Int, isOffline: Bool) async {
        guard let dataClient = self.dataClient as? DSProductAPIDataService else { return }
        guard let database = self.dbContainer as? DSProductDBDataService else { return }
        
        return await withCheckedContinuation { continuation in
            Task {
                if isOffline {
                    self.products.send(try await database.getProducts(page: 0, size: 0))
                    return continuation.resume()
                }
                
                self.isLoading.send(true)
                do {
                    let results = try await dataClient.getProducts(page: page, size: size)
                    
                    await database.saveProducts(products: results.list)
                    
                    self.products.send(results)
                    self.isLoading.send(false)
                }
                catch let error as APIConstants.AppError {
                    debugLog(logMessage: "\(error)")
                    
                    switch error {
                    case let .apiError(_, msg):
                        debugLog(logMessage: "\(msg)")
                    }
                    
                    self.products.send(try await database.getProducts(page: 0, size: 0))
                    self.isLoading.send(false)
                } catch {
                    debugLog(logMessage: String(localized: "no.connection.msg"))
                    
                    self.products.send(try await database.getProducts(page: 0, size: 0))
                    self.isLoading.send(false)
                }
                return continuation.resume()
            }
        }
    }
    func getProduct(id: Int, isOffline: Bool) async {
        guard let dataClient = self.dataClient as? DSProductAPIDataService else { return }
        guard let database = self.dbContainer as? DSProductDBDataService else { return }
        
        return await withCheckedContinuation { continuation in
            Task {
                if isOffline {
                    if let local = try await database.getProduct(id: id) {
                        self.product.send(local)
                        return continuation.resume()
                    }
                }
                
                self.isLoading.send(true)
                do {
                    guard let result = try await dataClient.getProduct(id: id) else {
                        return continuation.resume()
                    }
                    
                    await database.createOrUpdateObj(obj: result)
                    
                    self.product.send(result)
                    self.isLoading.send(false)
                }
                catch let error as APIConstants.AppError {
                    debugLog(logMessage: "\(error)")
                    
                    switch error {
                    case let .apiError(_, msg):
                        debugLog(logMessage: "\(msg)")
                    }
                    
                    self.products.send(try await database.getProducts(page: 0, size: 0))
                    self.isLoading.send(false)
                } catch {
                    debugLog(logMessage: String(localized: "no.connection.msg"))
                    
                    self.products.send(try await database.getProducts(page: 0, size: 0))
                    self.isLoading.send(false)
                }
                return continuation.resume()
            }
        }
    }
}
