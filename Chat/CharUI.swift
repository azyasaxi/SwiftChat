import SwiftUI
import Foundation

extension String {
    func attributedStringFromMarkdown() -> AttributedString {
        do {
            return try AttributedString(markdown: self)
        } catch {
            print("Markdown parsing error: \(error)")
            return AttributedString(self)
        }
    }
}

extension AttributedString {
    mutating func applyCodeBlockStyle() {
        // 转换为纯文本
        let plainText = String(self.characters)
        
        // 查找所有代码块
        let codeBlockPattern = "```([\\s\\S]*?)```"
        guard let regex = try? NSRegularExpression(pattern: codeBlockPattern, options: []) else { return }
        
        let matches = regex.matches(in: plainText, range: NSRange(plainText.startIndex..., in: plainText))
        
        // 创建一个新的AttributedString
        var newAttributedString = AttributedString(plainText)
        
        // 从后向前应用样式（避免索引变化）
        for match in matches.reversed() {
            guard let matchRange = Range(match.range, in: plainText) else { continue }
            
            // 内容范围（排除```标记）
            let contentStart = plainText.index(matchRange.lowerBound, offsetBy: 3)
            let contentEnd = plainText.index(matchRange.upperBound, offsetBy: -3)
            
            // 在新AttributedString中找到对应位置
            let startPos = plainText.distance(from: plainText.startIndex, to: contentStart)
            let endPos = plainText.distance(from: plainText.startIndex, to: contentEnd)
            
            // 使用安全的索引创建方法
            if startPos >= 0, endPos <= plainText.count, startPos < endPos {
                // 显式指定偏移单位为字符
                let attributedStartIndex = newAttributedString.index(newAttributedString.startIndex, offsetByCharacters: startPos)
                let attributedEndIndex = newAttributedString.index(newAttributedString.startIndex, offsetByCharacters: endPos)
                
                // 应用样式
                if attributedStartIndex < attributedEndIndex {
                    let range = attributedStartIndex..<attributedEndIndex
                    newAttributedString[range].font = .monospacedSystemFont(ofSize: 14, weight: .regular) // 设置等宽字体
                    newAttributedString[range].backgroundColor = .init(.lightGray) // 设置背景颜色
                }
            }
        }
        
        // 替换原来的AttributedString
        self = newAttributedString
    }
}

// 定义 ChatUI 视图，用于实现聊天界面
struct ChatUI: View {
    @State private var messageText = ""
    @State private var messages: [Message] = []
    @State private var isClearing = false // 添加清空动画状态
    
    
    // 外部传入的参数
    private let geminiService: GeminiService // GeminiService 实例
    private let typingSpeed: TimeInterval = 0.02 // 打字速度
    
    // 初始化方法，接受 base URL、API 密钥和模型名称作为参数
    init(baseURL: String, apiKey: String, model: String) {
        self.geminiService = GeminiService(baseURL: baseURL, apiKey: apiKey, model: model)
    }
    
    // 发送消息的方法
    func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = Message(content: messageText, isUser: true, sender: "You", displayContent: messageText)
        messages.append(userMessage)
        
        let userInput = messageText
        messageText = "" // 清空输入框
        
        let aiMessage = Message(content: "", isUser: false, sender: "AI")
        messages.append(aiMessage)
        
        geminiService.sendMessage(
            userInput,
            onReceive: { content in
                if let lastIndex = messages.indices.last {
                    let wasEmpty = messages[lastIndex].buffer.isEmpty
                    messages[lastIndex].buffer += content
                    if wasEmpty {
                        messages[lastIndex].isTyping = true
                        animateTyping(at: lastIndex)
                    }
                }
            },
            onFinish: {
                if let lastIndex = messages.indices.last {
                    messages[lastIndex].isTyping = false // 停止打字动画
                    messages[lastIndex].content = messages[lastIndex].buffer // 确保内容完整
                }
            },
            completion: { result in
                if case .failure(let error) = result {
                    DispatchQueue.main.async {
                        let errorMessage = Message(
                            content: "Error: \(error.localizedDescription)",
                            isUser: false,
                            sender: "System",
                            displayContent: "Error: \(error.localizedDescription)"
                        )
                        messages.append(errorMessage)
                    }
                }
            }
        )
    }
    
    // 打字动画函数
    private func animateTyping(at index: Int) {
        guard index < messages.count else { return }
        
        if !messages[index].buffer.isEmpty {
            // 每次取一个字符并添加到 displayContent
            let firstChar = String(messages[index].buffer.prefix(1))
            messages[index].displayContent += firstChar
            messages[index].buffer = String(messages[index].buffer.dropFirst())
            
            DispatchQueue.main.asyncAfter(deadline: .now() + typingSpeed) {
                self.animateTyping(at: index)
            }
        } else if !messages[index].isTyping {
            return // 当 buffer 为空且 isTyping 为 false 时停止
        }
    }
    
    // 清空聊天记录的方法
    func clearChat() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isClearing = true
        }
        
        // 延迟后清空消息并重置动画状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            messages.removeAll()
            withAnimation(.easeInOut(duration: 0.2)) {
                isClearing = false
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            HStack {
                NavigationLink(destination: ConversationListView(currentUsername: "wujiafa")) {
                    Image(systemName: "line.horizontal.3")
                        .font(.system(size: 24))
                        .tint(.primary)
                }
                .transition(.move(edge: .trailing))
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("Azyasaxi")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text("beta")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.secondary.opacity(0.2))
                        .cornerRadius(10)
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                Button(action: clearChat) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 24))
                        .tint(.primary)
                }
            }
            .padding()
            .background(.background)
            
            // 聊天区域
            ScrollViewReader { proxy in
                ScrollView {
                    if messages.isEmpty {
                        // 当没有消息时显示标题
                        VStack(spacing: 4) {
                            Text("Azyasaxi")
                                .font(.system(size: 30))
                                .fontWeight(.semibold)
                            Text("beta")
                                .font(.system(size: 20))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.secondary.opacity(0.2))
                                .cornerRadius(10)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 280)
                        .padding(.bottom, UIScreen.main.bounds.height * 0.4)
                    } else {
                        // 显示消息列表
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(messages) { message in
                                HStack(alignment: .top, spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .foregroundColor(message.isUser ? .white : .blue)
                                        if message.isUser {
                                            Circle()
                                                .strokeBorder(.secondary, lineWidth: 1)
                                        }
                                    }
                                    .frame(width: 18, height: 18)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(message.sender)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        
                                        // 使用 Text 的 AttributedString 构造器
                                        Text(message.formattedContent)
                                            .textSelection(.enabled) // 允许文本选择
                                            .opacity(message.isTyping ? 0.7 : 1)
                                    }
                                }
                                .padding(.horizontal)
                                .opacity(isClearing ? 0 : 1)
                                .animation(.easeInOut(duration: 0.3), value: isClearing)
                                .id(message.id) // 为每个消息添加唯一的 ID
                            }
                        }
                        .padding(.vertical)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onChange(of: messages.count) { oldValue, newValue in
                            // 打印旧值和新值（可选）
                            print("Old value: \(oldValue), New value: \(newValue)")
                            
                            // 当消息数量发生变化时，滚动到最新消息
                            withAnimation {
                                proxy.scrollTo(messages.last?.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            // 底部输入栏
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 15) {
                    HStack {
                        TextField("向az提问任何问题", text: $messageText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .accessibilityIdentifier("messageTextField")
                        
                        Button(action: sendMessage) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 20))
                                .tint(.primary)
                        }
                        .accessibilityIdentifier("sendButton")
                    }
                    .background(.secondary.opacity(0.1))
                    .cornerRadius(20)
                }
                .padding()
                .background(.background)
            }
        }
        .navigationBarBackButtonHidden()
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

// 定义 Message 结构体，表示单条消息
struct Message: Identifiable {
    let id = UUID()
    var content: String // 原始 Markdown 内容
    let isUser: Bool
    let sender: String
    var displayContent: String = "" // 用于动画显示的内容
    var isTyping: Bool = false
    var buffer: String = ""
    
    // 计算属性，获取格式化的富文本
    var formattedContent: AttributedString {
        displayContent.attributedStringFromMarkdown()
    }
}
