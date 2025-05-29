//
//  ProductDetailsViewModel.swift
//  TheSwiftUI
//
//  Created by John Daugdaug on 5/28/25.
//

import SwiftUI
import Combine

class ProductDetailsViewModel: BaseViewModel {
    private(set) var repository: ProductDataRepository
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published var product: MProduct? = nil

    init(dataRepository: ProductDataRepository = ProductDataRepository()) {
        self.repository = dataRepository
    }
}
extension ProductDetailsViewModel {
    nonisolated func houseKeeping() {
        cancellables.forEach { cancellable in
            cancellable.cancel()
        }
    }
}
extension ProductDetailsViewModel: @unchecked Sendable {
    func populateData(id: Int) async {
        await repository.product
            .sink { completion in
                debugLog(logMessage: "Sink: \(completion)")
            } receiveValue: { [weak self] value in
                guard let self = self else { return }
                debugLog(logMessage: "received createSubscribers: \(value)")

                DispatchQueue.main.async {
                    self.product = value
                }
            }
            .store(in: &cancellables)
        
        await getProduct(id: id)
    }
    func getProduct(id: Int) async {
        await repository.getProduct(id: id, isOffline: !InternetConnectionManager.isConnectedToNetwork())
    }
}
