//
//  ContentView.swift
//  TheSwiftUI
//
//  Created by John Daugdaug on 5/28/25.
//

import SwiftUI
import Combine
import SDWebImageSwiftUI

struct ContentView: View {
    @ObservedObject var vm: ProductListViewModel
    
    @StateObject private var navigation = ProductRoutes()
    @StateObject private var prodDetailsVM = ProductDetailsViewModel()
    
    @State private var loaderId = 0
    @State private var cancellables: Set<AnyCancellable> = []

    init(viewModel: ProductListViewModel = ProductListViewModel()) {
        self.vm = viewModel
    }
    
    var body: some View {
        NavigationStack(path: $navigation.navPath) {
            mainView
                .task {
                    await vm.populateData()
                }
                .background( .white )
                .onAppear(perform: {
                    vm.$selectedProdId
                        .dropFirst()
                        .sink { value in
                            navigation.push(to: .productDetails)
                        }
                        .store(in: &cancellables)
                })
                .onDisappear(perform: {
                    vm.houseKeeping()
                })
                .navigationDestination(for: ProductRoutes.Routes.self) { routes in
                    Group {
                        switch routes {
                        case .productDetails:
                            ProductDetailsView(viewModel: prodDetailsVM, navigation: navigation)
                                .task {
                                    await prodDetailsVM.populateData(id: vm.selectedProdId)
                                }
                        }
                    }
                    .navigationBarBackButtonHidden(true)
                }
        }
    }
}

extension ContentView {
    var mainView: some View {
        List {
            ForEach(vm.products, id: \.self) { item in
                HStack(spacing: 24) {
                    WebImage(url: URL(string: item.thumbnailUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(8)
                    } placeholder: {
                        ZStack {
                            Image(systemName: "photo.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .opacity(0.3)
                                .frame(width: 32, height: 32)
                            ProgressView()
                        }
                    }
                    Text(item.title ?? "")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .frame(width: 16, height: 16)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    vm.selectedProdId = item.id ?? 0
                }
            }
            
            if !vm.isEOF {
                HStack {
                    Spacer()
                    ActivityIndicator(isAnimating: .constant(true), style: .medium)
                        .task {
                            await vm.getProducts()
                        }
                    Spacer()
                }
            }
        }
        .refreshable {
            await vm.refreshProducts()
        }
    }
}

struct ActivityIndicator: UIViewRepresentable {
    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style
    
    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: style)
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}


#Preview {
    ContentView()
}
