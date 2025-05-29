//
//  DataSource.swift
//  TheSwiftUI
//
//  Created by John Daugdaug on 5/28/25.
//

import CoreData

protocol DSBaseProtocol {}

protocol DSProductProtocol: DSBaseProtocol {
    func getProducts(page: Int, size: Int) async throws -> (list: [MProduct], total: Int)
    func getProduct(id: Int) async throws -> MProduct?
    func saveProducts(products: [MProduct]) async
}
extension DSProductProtocol {
    func saveProducts(products: [MProduct]) async {
        //this is a empty implementation to allow this method to be optional
    }
}

actor DSProductAPIDataService: DSProductProtocol {
    func getProducts(page: Int, size: Int) async throws -> (list: [MProduct], total: Int) {
        return try await withCheckedThrowingContinuation({ continuation in
            let url = String(format: "\(APIConstants.baseURLStr)\(APIConstants.productsEndpoint)", size, page)
            guard let url = URL(string: url) else { return }
            
            URLSession.shared.dataTask(with: url) { (data, _, _) in
                guard let data = data else { return }
                
                if let object = try? JSONDecoder().decode(MProductListResponse.self, from: data) {
                    continuation.resume(returning: (list: object.listProduct, total: object.total ?? 0))
                }
                else {
                    continuation.resume(throwing: APIConstants.AppError.apiError(code: 0,
                                                                                 msg: String(localized: "no.connection.msg")))
                }
            }
            .resume()
        })
    }
    
    func getProduct(id: Int) async throws -> MProduct? {
        return try await withCheckedThrowingContinuation({ continuation in
            let url = String(format: "\(APIConstants.baseURLStr)\(APIConstants.productEndpoint)", id)
            guard let url = URL(string: url) else { return }
            
            URLSession.shared.dataTask(with: url) { (data, _, _) in
                guard let data = data else { return }
                
                if let object = try? JSONDecoder().decode(MProduct.self, from: data) {
                    continuation.resume(returning: object)
                }
                else {
                    continuation.resume(throwing: APIConstants.AppError.apiError(code: 0,
                                                                                 msg: String(localized: "no.connection.msg")))
                }
            }
            .resume()
        })
    }
}

actor DSProductMockDataService: DSProductProtocol {
    func getProducts(page: Int, size: Int) async throws -> (list: [MProduct], total: Int) {
        return try await withCheckedThrowingContinuation({ continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                continuation.resume(returning: (list: [.init(id: 1, title: "Essence Mascara Lash Princess", description: "The Essence Mascara Lash Princess is a popular mascara known for its volumizing and lengthening effects. Achieve dramatic lashes with this long-lasting and cruelty-free formula.", thumbnailUrl: "https://dummyjson.com/image/150", images: ["https://dummyjson.com/image/150"])],
                                                total: 100))
            }
        })
    }
    
    func getProduct(id: Int) async throws -> MProduct? {
        return try await withCheckedThrowingContinuation({ continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                continuation.resume(returning: nil)
            }
        })
    }
}

actor DSProductDBDataService: DSProductProtocol {
    private var managedObjectContext: NSManagedObjectContext
    
    init(persistent: PersistenceController = PersistenceController.shared) {
        self.managedObjectContext = persistent.container.viewContext
    }
    
    func getProducts(page: Int, size: Int) async throws -> (list: [MProduct], total: Int) {
        return try await withCheckedThrowingContinuation({ continuation in
            let result = fetchAll(CDProduct.self, predicate: nil)
            switch result {
            case .success(let managedObject):
                let convert = managedObject.map { MProduct(CDProduct: $0) }
                continuation.resume(returning: (list: convert, total: convert.count))
            case .failure(_):
                debugLog(logMessage: "Couldn't fetch ProjectMO to save")
            }
        })
    }
    
    func getProduct(id: Int) async throws -> MProduct? {
        return try await withCheckedThrowingContinuation({ continuation in
            let predicate = NSPredicate(format: "id = \(id)")
            let result = fetchFirst(CDProduct.self, predicate: predicate)
            switch result {
            case .success(let managedObject):
                if let objMO = managedObject {
                    return continuation.resume(returning: MProduct(CDProduct: objMO))
                } else {
                    return continuation.resume(returning: nil)
                }
            case .failure(_):
                debugLog(logMessage: "Couldn't fetch ProjectMO to save")
                return continuation.resume(returning: nil)
            }
        })
    }
    
    func saveProducts(products: [MProduct]) async {
        Task {
            products.forEach { product in
                managedObjectContext.performAndWait {
                    createOrUpdateObj(obj: product)
                }
            }
            saveData()
        }
    }

    func saveData() {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.performAndWait {
                    try managedObjectContext.save()
                }
            } catch let error as NSError {
                debugLog(logMessage: "Unresolved error saving context: \(error), \(error.userInfo)")
            }
        }
    }
    
    func deleteAllRecords(dbName: String) async {
        return await withCheckedContinuation { continuation in
            let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: dbName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)

            managedObjectContext.performAndWait {
                do {
                    try managedObjectContext.execute(deleteRequest)
                    try managedObjectContext.save()
                } catch let error as NSError {
                    debugLog(logMessage: "--- CoreData Unresolved error saving context: \(error), \(error.userInfo) ---")
                }
            }
            continuation.resume()
        }
    }
    
    func createOrUpdateObj(obj: MProduct) {
        let predicate = NSPredicate(format: "id = \(obj.id ?? 0)")
        let result = fetchFirst(CDProduct.self, predicate: predicate)
        switch result {
        case .success(let managedObject):
            if let objMO = managedObject {
                update(objMO: objMO, from: obj)
            } else {
                createObjMO(from: obj)
            }
        case .failure(_):
            debugLog(logMessage: "Couldn't fetch ProjectMO to save")
        }
    }
    
    private func createObjMO(from obj: MProduct) {
        let objMO = CDProduct(context: managedObjectContext)
        objMO.id = Int16(obj.id ?? 0)
        objMO.title = obj.title ?? ""
        objMO.descr = obj.description ?? ""
        objMO.thumbnailUrl = obj.thumbnailUrl ?? ""
        objMO.images = obj.images ?? []
    }
    
    private func update(objMO: CDProduct, from obj: MProduct) {
        objMO.title = obj.title ?? ""
        objMO.descr = obj.description ?? ""
        objMO.thumbnailUrl = obj.thumbnailUrl ?? ""
        objMO.images = obj.images ?? []
    }
    
    private func fetchFirst<T: NSManagedObject>(_ objectType: T.Type, predicate: NSPredicate?) -> Result<T?, Error> {
        let request = objectType.fetchRequest()
        request.predicate = predicate
        request.fetchLimit = 1
        do {
            let result = try managedObjectContext.fetch(request) as? [T]
            return .success(result?.first)
        } catch {
            return .failure(error)
        }
    }
    
    private func fetchAll<T: NSManagedObject>(_ objectType: T.Type, predicate: NSPredicate?) -> Result<[T], Error> {
        let request = objectType.fetchRequest()
        request.predicate = predicate
        do {
            let result = try managedObjectContext.fetch(request) as? [T]
            return .success(result ?? [])
        } catch {
            return .failure(error)
        }
    }
}
