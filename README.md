# ChatService

*🤖 Chat with GPT*

ChatService is a Swift package that provides a simple API for chatting with an AI-powered bot based on GPT (Generative Pretrained Transformer) architecture. The package uses OpenAI's GPT models to generate responses to user inputs, and provides an interface for managing chats and chat history.

**[OpenAI API Reference](https://platform.openai.com/docs/api-reference/chat)**


## Usage

To use ChatService in your app, first import the module:

```swift
import ChatService
```

Then, create an instance of ChatService with your OpenAI API key:

```swift
let chatService = ChatService(key: "YOUR_OPENAI_API_KEY")
```

You can then use the completion method to generate a response to a user message:

```swift
let response: String = try await chatService.completion(for: "Hello?")
```

You can access the chat history using the chatHistory property of the Chat object:

```swift
let chatHistory: [ChatService.Chat] = chat.chatHistory
```
