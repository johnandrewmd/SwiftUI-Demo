//
//  APIConstants.swift
//  TheSwiftUI
//
//  Created by John Daugdaug on 5/28/25.
//

import Foundation

enum APIConstants {}

extension APIConstants {
    static let baseURLStr = "https://dummyjson.com"
}

extension APIConstants {
    static let productsEndpoint = "/products?limit=%d&skip=%d&sortBy=title&order=asc"
    static let productEndpoint = "/products/%d"
}

extension APIConstants {
    enum AppError: Error {
        case apiError(code: Int, msg: String)
    }
}

