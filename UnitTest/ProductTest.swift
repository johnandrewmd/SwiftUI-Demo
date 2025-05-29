//
//  ProductTest.swift
//  TheSwiftUITests
//
//  Created by John Daugdaug on 5/29/25.
//

import XCTest
import Combine

@testable import TheSwiftUI

final class ProductTest: XCTestCase {
    let dbStorate = DSProductDBDataService()
    lazy var dataRepository = ProductDataRepository(dbContainer: dbStorate)
    
    private var cancellables = Set<AnyCancellable>()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testDataRepository() async throws {
        try await productsOnline()
        try await productsOffline()
        try await productOnline()
        try await productOffline()
    }
    
    func productsOnline() async throws {
        await dataRepository.products
            .sink { completion in
                debugLog(logMessage: "Sink: \(completion)")
            } receiveValue: { [weak self] value in
                guard self != nil else { return }
                
                XCTAssertGreaterThan(value.list.count, 0)
            }
            .store(in: &cancellables)
        
        await dataRepository.getProductListing(page: 0, size: 10, isOffline: false)
    }
    
    func productsOffline() async throws {
        await dataRepository.products
            .sink { completion in
                debugLog(logMessage: "Sink: \(completion)")
            } receiveValue: { [weak self] value in
                guard self != nil else { return }
                
                XCTAssertGreaterThan(value.list.count, 0)
            }
            .store(in: &cancellables)
        
        await dataRepository.getProductListing(page: 0, size: 10, isOffline: true)
    }
    
    func productOnline() async throws {
        await dataRepository.product
            .sink { completion in
                debugLog(logMessage: "Sink: \(completion)")
            } receiveValue: { value in
                XCTAssertNotNil(value)
            }
            .store(in: &cancellables)
        
        await dataRepository.getProduct(id: 1, isOffline: false)
    }
    
    func productOffline() async throws {
        await dataRepository.product
            .sink { completion in
                debugLog(logMessage: "Sink: \(completion)")
            } receiveValue: { value in
                XCTAssertNotNil(value)
            }
            .store(in: &cancellables)
        
        await dataRepository.getProduct(id: 1, isOffline: true)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
