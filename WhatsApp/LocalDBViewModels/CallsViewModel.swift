
import Foundation

@Observable class CallsViewModel {
     var calls: [Call] = [
        Call(
            contactName: "John Doe",
            profileImage: "person.circle.fill",
            callType: .audio,
            callDirection: .incoming,
            timestamp: Date().addingTimeInterval(-3600),
            missedCall: true,
            callCount: 3
        ),
        Call(
            contactName: "Jane Smith",
            profileImage: "person.circle.fill",
            callType: .video,
            callDirection: .outgoing,
            timestamp: Date().addingTimeInterval(-7200),
            missedCall: false,
            callCount: 5
        ),
        Call(
            contactName: "Alice Johnson",
            profileImage: "person.circle.fill",
            callType: .audio,
            callDirection: .incoming,
            timestamp: Date().addingTimeInterval(-10800),
            missedCall: true,
            callCount: 1
        )
    ]
}
