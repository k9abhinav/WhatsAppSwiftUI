
//import Combine
//import SwiftUI
//
//struct KeyBoardViewModifier: ViewModifier {
//    @State private var keyboardHeight: CGFloat = 0
//    @State private var isKeyboardVisible: Bool = false
//    
//    func body(content: Content) -> some View {
//        content
//            .safeAreaInset(edge: .bottom) {
//                if isKeyboardVisible {
//                    Color.clear.frame(height: max(0,keyboardHeight)) // Add space only when the keyboard is visible
//                }
//            }
//            .onAppear {
//                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
//                    if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
//                        keyboardHeight = keyboardFrame.height - 350 // Reduce the height to avoid too much space
//                        isKeyboardVisible = true
//                    }
//                }
//                
//                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
//                    keyboardHeight = 0
//                    isKeyboardVisible = false
//                }
//            }
//    }
//}



