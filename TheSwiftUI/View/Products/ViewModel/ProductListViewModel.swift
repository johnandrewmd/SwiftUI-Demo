//
//  ProductListViewModel.swift
//  TheSwiftUI
//
//  Created by John Daugdaug on 5/28/25.
//

import SwiftUI
import Combine

class ProductListViewModel: BaseViewModel {
    private(set) var repository: ProductDataRepository
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published var products: [MProduct] = []
    @Published var isEOF: Bool = false
    private(set) var total: Int = 0
    
    @Published var selectedProdId: Int = 0
    
    private var page: Int = 0
    private var pageSize: Int = 25
    
    init(dataRepository: ProductDataRepository = ProductDataRepository()) {
        self.repository = dataRepository
    }
}
extension ProductListViewModel {
    nonisolated func houseKeeping() {
        cancellables.forEach { cancellable in
            cancellable.cancel()
        }
    }
}
extension ProductListViewModel: @unchecked Sendable {
    func populateData() async {
        await repository.products
            .sink { completion in
                debugLog(logMessage: "Sink: \(completion)")
            } receiveValue: { [weak self] value in
                guard let self = self else { return }
                debugLog(logMessage: "received createSubscribers: \(value)")
                
                DispatchQueue.main.async {
                    self.total = value.total
                    if self.page == 0 {
                        self.products = value.list
                    }
                    else {
                        self.products.append(contentsOf: value.list)
                    }
                    
                    if (self.products.count >= self.total) ||
                        value.list.count < self.pageSize {
                        withAnimation { self.isEOF = true }
                    }
                    else { self.page += self.pageSize+1 }
                }
            }
            .store(in: &cancellables)
        
        await initProducts()
    }
}
extension ProductListViewModel {
    @MainActor
    func refreshProducts() async {
        page = 0
        isEOF = false
        return await withCheckedContinuation { continuation in
            Task {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                
                await repository.getProductListing(page: page, size: pageSize,
                                                   isOffline: !InternetConnectionManager.isConnectedToNetwork())
                continuation.resume()
            }
        }
    }
    
    @MainActor
    func initProducts() async {
        await repository.getProductListing(page: page, size: pageSize,
                                           isOffline: !InternetConnectionManager.isConnectedToNetwork())
    }
    
    @MainActor
    func getProducts() async {
        if page == 0 || isEOF { return }
        
        return await withCheckedContinuation { continuation in
            Task {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                await repository.getProductListing(page: page, size: pageSize,
                                                   isOffline: !InternetConnectionManager.isConnectedToNetwork())
                continuation.resume()
            }
        }
    }
}
