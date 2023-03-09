import Plugin
import SwiftUI
import XCTest
@testable import ChatService

final class ChatServiceTests: XCTestCase {
    /// Example ViewModel
    class TestChatViewModel: ObservableObject {
        private let chatService = ChatService(key: "TEST")
        private var chatTask: Task<Void, Never>?

        @Published var isWaitingForResponse: Bool = false
        @Published var chatHistory: [String] = []

        @discardableResult
        func send(message: String) -> Task<Void, Never> {
            let task = Task {
                await MainActor.run {
                    isWaitingForResponse = true
                }

                do {
                    let response = try await chatService.completion(for: message)
                    
                    await MainActor.run {
                        chatHistory.append(response)
                    }
                } catch {
                    // Log error
                }

                await MainActor.run {
                    isWaitingForResponse = false
                }
            }

            chatTask = task

            return task
        }
    }
}
