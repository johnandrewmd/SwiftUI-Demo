//
//  ProductRoutes.swift
//  TheSwiftUI
//
//  Created by John Daugdaug on 5/28/25.
//

import SwiftUI

class ProductRoutes: BaseViewModel {
    enum Routes: Codable, Hashable {
        case productDetails
    }
    
    @MainActor
    @Published var navPath = NavigationPath()
    
    func houseKeeping() {
        DispatchQueue.main.async {
            self.navPath = NavigationPath()
        }
    }
}
extension ProductRoutes {
    @MainActor
    func push(to destination: Routes) {
        navPath.append(destination)
    }
    
    @MainActor
    func pop() {
        if navPath.count <= 0 {
            return
        }
        navPath.removeLast()
    }
    
    @MainActor
    func popToRoot() {
        if navPath.count <= 0{
            return
        }
        navPath.removeLast(navPath.count)
    }
    
    @MainActor
    func popToHome() {
        if navPath.count <= 0 {
            return
        }
        navPath.removeLast(navPath.count-1)
    }
    
    @MainActor
    func isActive() -> Bool {
        if navPath.count > 0 {
            return true
        }
        return false
    }
}
