import Cache
import Network
import Plugin
import SwiftUI

/// A class that interacts with OpenAI's API to generate chat responses.
open class ChatService: Pluginable, ObservableObject {
    /// The available chat models.
    public enum ChatModel {
        public static let gpt = "gpt-3.5-turbo"
    }

    /// The errors that can occur while using the `ChatService`.
    public enum ChatError: String, LocalizedError {
        case noData = "No Data"
        case noChoices = "No AI Choices"

        public var errorDescription: String? {
            rawValue
        }
    }

    /**
     The keys used to parse the JSON response from the API.
     ```
     {
       "id": "chatcmpl-123",
       "object": "chat.completion",
       "created": 1677652288,
       "choices": [{
         "index": 0,
         "message": {
           "role": "assistant",
           "content": "\n\nHello there, how may I assist you today?",
         },
         "finish_reason": "stop"
       }],
       "usage": {
         "prompt_tokens": 9,
         "completion_tokens": 12,
         "total_tokens": 21
       }
     }
     ```
     */
    public enum JSONKeys {
        public enum Root: String {
            case id, object, created, choices, usage
        }

        public enum Choices: String {
            case index, message, finish_reason
        }

        public enum Message: String {
            case role, content
        }

        public enum Usage: String {
            case prompt_tokens, completion_tokens, total_tokens
        }
    }

    /// The chat message.
    public struct Chat: Codable {
        public let role: String
        public let content: String

        public init(role: String, content: String) {
            self.role = role
            self.content = content
        }
    }

    /// The payload used to send messages to the API.
    public struct Payload: Codable {
        public let model: String
        public let messages: [Chat]
    }

    /// A type of payload expected by plugins.
    public typealias ChatServicePluginPayload = JSON<JSONKeys.Root>

    /// The API key used to authenticate with the OpenAI API.
    public let key: String

    /// The chat model to use for generating responses.
    public let model: String

    /// The list of plugins that can modify the API response.
    public var plugins: [any Plugin]

    /// The chat history, which is a published array of `Chat`s.
    @Published open var chatHistory: [Chat]

    /// Initializes a new `ChatService` instance.
    /// - Parameters:
    ///   - key: The API key used to authenticate with the OpenAI API.
    ///   - model: The chat model to use for generating responses. Defaults to `ChatModel.gpt`.
    ///   - plugins: The list of plugins that can modify the API response. Defaults to an empty array.
    public init(
        key: String,
        model: String = ChatModel.gpt,
        plugins: [any Plugin] = []
    ) {
        self.key = key
        self.model = model
        self.plugins = plugins
        self.chatHistory = []
    }

    /**
     Sends a request to the OpenAI API to generate a chat response for the given prompt.
        - Parameter prompt: The prompt to use for generating a chat response.
        - Returns: The generated chat response as a `String`.

     ```
     curl https://api.openai.com/v1/chat/completions \
       -H 'Content-Type: application/json' \
       -H 'Authorization: Bearer YOUR_API_KEY' \
       -d '{
       "model": "gpt-3.5-turbo",
       "messages": [{"role": "user", "content": "Hello!"}]
     }'
     ```
     */
    open func completion(for prompt: String) async throws -> String {
        await appendChatHistory(with: Chat(role: "user", content: prompt))

        let body = try JSONEncoder().encode(
            Payload(
                model: model,
                messages: chatHistory
            )
        )

        let dataResponse = try await Network.post(
            url: URL(string: "https://api.openai.com/v1/chat/completions")!,
            body: body,
            headerFields: [
                "Content-Type": "application/json",
                "Authorization": "Bearer \(key)"
            ]
        )

        guard
            let data = dataResponse.data
        else {
            throw ChatError.noData
        }

        let json = JSON<JSONKeys.Root>(data: data)

        try await handle(value: json)

        guard
            let choices = json.array(.choices, keyed: JSONKeys.Choices.self),
            let firstMessage = choices.first?.json(.message, keyed: JSONKeys.Message.self),
            let message = firstMessage.get(.content, as: String.self)
        else {
            throw ChatError.noChoices
        }

        await appendChatHistory(
            with: Chat(
                role: try firstMessage.resolve(.role),
                content: message
            )
        )

        return message
    }

    /// Appends a new `Chat` object to the `chatHistory` array.
    ///
    /// The function uses `MainActor.run` to ensure that the code inside the closure is executed on the main thread.
    ///
    /// - Parameter chat: The `Chat` object to be appended to the `chatHistory`
    open func appendChatHistory(with chat: Chat) async {
        await MainActor.run {
            chatHistory.append(chat)
        }
    }
}
