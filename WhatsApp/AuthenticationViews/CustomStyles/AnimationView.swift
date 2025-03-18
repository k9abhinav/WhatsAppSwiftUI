import SwiftUI
import Lottie

struct LottieWhatsAppView: View {
    var body: some View {
        LottieView(filename: "whatsappLogo", width: 120, height: 120)
            .frame(width: 120, height: 120) // ✅ Now this works
    }
}

#Preview {
    LottieWhatsAppView()
}

struct LottieView: View {
    var filename: String
    var width: CGFloat
    var height: CGFloat

    @State private var animation: LottieAnimation?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
            } else if let animation {
                LottieAnimationViewRepresentable(animation: animation, width: width, height: height)
                    .frame(width: width, height: height) // ✅ Now it works
            } else if let errorMessage {
                Text("Error: \(errorMessage)").foregroundColor(.red)
            }
        }
        .task {
            loadAnimation()
        }
    }

    private func loadAnimation() {
        guard let path = Bundle.main.path(forResource: filename, ofType: "json") else {
            self.errorMessage = "File not found"
            self.isLoading = false
            return
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let animation = try JSONDecoder().decode(LottieAnimation.self, from: data)
            DispatchQueue.main.async {
                self.animation = animation
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

// ✅ Apply correct constraints inside UIViewRepresentable
struct LottieAnimationViewRepresentable: UIViewRepresentable {
    var animation: LottieAnimation
    var width: CGFloat
    var height: CGFloat

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        let animationView = LottieAnimationView()
        animationView.animation = animation
        animationView.loopMode = .loop
        animationView.contentMode = .scaleAspectFit // ✅ Ensures proper scaling
        animationView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(animationView)

        NSLayoutConstraint.activate([
            animationView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            animationView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            animationView.widthAnchor.constraint(equalToConstant: width),
            animationView.heightAnchor.constraint(equalToConstant: height)
        ])

        animationView.play()

        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
