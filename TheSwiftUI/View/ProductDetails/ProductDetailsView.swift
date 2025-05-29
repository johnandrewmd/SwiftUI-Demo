//
//  ProductDetailsView.swift
//  TheSwiftUI
//
//  Created by John Daugdaug on 5/28/25.
//

import SwiftUI
import SDWebImageSwiftUI

struct ProductDetailsView: View {
    @ObservedObject var vm: ProductDetailsViewModel
    @ObservedObject var navigation: ProductRoutes

    init(viewModel: ProductDetailsViewModel = ProductDetailsViewModel(), navigation: ProductRoutes = ProductRoutes()) {
        self.vm = viewModel
        self.navigation = navigation
    }
    
    var body: some View {
        VStack {
            headerView
            mainView
        }
        .padding(.horizontal)
        .onDisappear {
            vm.houseKeeping()
        }
    }
}
extension ProductDetailsView {
    var headerView: some View {
        HStack() {
            Button {
                navigation.popToRoot()
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 16, height: 16)
            }
            Spacer()
        }
        .overlay(content: {
            Text("product.details")
                .font(.headline)
        })
        .frame(height: 44)
    }
}
extension ProductDetailsView {
    var mainView: some View {
        VStack(spacing: 16) {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(vm.product?.images ?? [], id: \.self) { imageUrl in
                        WebImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 200)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(8)
                        } placeholder: {
                            ZStack {
                                Image(systemName: "photo.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .opacity(0.3)
                                    .frame(height: 200)
                                ProgressView()
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            Text(vm.product == nil ? "The Title":vm.product?.title ?? "")
                .font(.title)
                .redacted(reason: vm.product == nil ? .placeholder : [])
            
            Text(vm.product == nil ? "The Description":vm.product?.description ?? "")
                .font(.subheadline)
                .redacted(reason: vm.product == nil ? .placeholder : [])
            
            Spacer()
        }
    }
}

#Preview {
    ProductDetailsView()
}
