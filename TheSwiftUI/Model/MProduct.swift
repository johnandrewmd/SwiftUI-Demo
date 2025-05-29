//
//  MProduct.swift
//  TheSwiftUI
//
//  Created by John Daugdaug on 5/28/25.
//

import Foundation

struct MProduct: Identifiable, Codable, Hashable {
    var id: Int?
    var title: String?
    var description: String?
    var thumbnailUrl: String?
    var images: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
        case description = "description"
        case thumbnailUrl = "thumbnail"
        case images = "images"
    }
}
extension MProduct {
    init(CDProduct local: CDProduct) {
        self.id = Int(local.id)
        self.title = local.title
        self.description = local.descr
        self.thumbnailUrl = local.thumbnailUrl
        self.images = local.images
    }
}

struct MProductListResponse: Codable {
    var listProduct: [MProduct] = []
    var total: Int?
    
    enum CodingKeys: String, CodingKey {
        case listProduct = "products"
        case total = "total"
    }
}
