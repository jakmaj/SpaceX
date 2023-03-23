import Foundation
import SwiftUI

struct DestinationWithDismiss<V: View>: View {
    @ViewBuilder var content: () -> V
    @Environment(\.dismiss) var dismiss
    @Binding var isPresented: Bool

    var body: some View {
        content()
            .onChange(of: self.isPresented) { isPresented in
                if !isPresented {
                    // Solves programatical dismiss bug. Inspired by:
                    // https://www.pointfree.co/episodes/ep217-modern-swiftui-effects-part-1#t1478
                    self.dismiss()
                }
            }
    }
}

struct NavigationDestinationViewModifier<V: View>: ViewModifier {
    @Binding var isPresented: Bool
    @ViewBuilder var destination: () -> V

    @State private var isPresentedInternal = false

    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            // Because of bug in navigationDestination, we always have to start with isPresented set to false
            // Inspired by https://www.pointfree.co/episodes/ep212-swiftui-navigation-decoupling
            content.navigationDestination(isPresented: self.$isPresentedInternal, destination: destination)
                .onAppear {
                    self.isPresentedInternal = isPresented
                }
                .onChange(of: self.isPresented) { isPresented in
                    isPresentedInternal = isPresented
                }
                .onChange(of: self.isPresentedInternal) { isActive in
                    self.isPresented = isActive
                }
        } else {
            content.background {
                NavigationLink(isActive: $isPresented, destination: destination) {
                    EmptyView()
                }
            }
        }
    }
}

extension View {
    func universalNavigationDestination<V>(
        isPresented: Binding<Bool>,
        @ViewBuilder destination: @escaping () -> V
    ) -> some View where V: View {
        modifier(NavigationDestinationViewModifier(isPresented: isPresented, destination: destination))
    }

    /// Alternative to universalNavigationDestination. This fixes programatical dismiss bug.
    /// But be aware universalNavigationDestinationWithDismiss cannot be used more than once.
    /// View A universalNavigationDestination -> B universalNavigationDestinationWithDismiss -> C Works
    /// View A universalNavigationDestinationWithDismiss -> B universalNavigationDestinationWithDismiss -> C Doesn't
    func universalNavigationDestinationWithDismiss<V>(
        isPresented: Binding<Bool>,
        @ViewBuilder destination: @escaping () -> V
    ) -> some View where V: View {
        let wrappedBinding: () -> DestinationWithDismiss<V> = {
            DestinationWithDismiss(content: destination, isPresented: isPresented)
        }
        return modifier(NavigationDestinationViewModifier(isPresented: isPresented, destination: wrappedBinding))
    }
}
