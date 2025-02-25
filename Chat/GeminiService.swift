import Foundation

// 定义 GeminiMessage 结构体，表示消息内容，符合 Codable 协议以便序列化和反序列化
struct GeminiMessage: Codable {
    let role: String // 消息的角色（例如 "System"、"user" 或 "assistant"）
    let content: String // 消息的具体内容
}

// 定义 ChatRequest 结构体，表示发送给服务器的请求数据结构
struct ChatRequest: Codable {
    let model: String // 使用的模型名称（例如 "gemini-2.0-pro-exp-02-05"）
    let stream: Bool // 是否以流式方式接收响应
    let messages: [GeminiMessage] // 消息列表，包含系统消息和用户消息
}

// 定义 Delta 结构体，表示响应中增量更新的内容
struct Delta: Codable {
    let role: String? // 增量更新中的角色（可能为空）
    let content: String? // 增量更新中的内容（可能为空）
}

// 定义 Choice 结构体，表示响应中的选择项
struct Choice: Codable {
    let index: Int // 选择项的索引
    let delta: Delta // 增量更新的内容
    let logprobs: String? // 日志概率（可选）
    let finish_reason: String? // 完成原因（例如 "stop" 表示完成）
}

// 定义 ChatResponse 结构体，表示服务器返回的完整响应
struct ChatResponse: Codable {
    let id: String // 响应的唯一标识符
    let choices: [Choice] // 响应中的选择项列表
    let created: Int // 响应创建的时间戳
    let model: String // 使用的模型名称
    let object: String // 响应的对象类型
}

// 定义 GeminiService 类，用于与 Gemini API 进行交互
class GeminiService {
    private let baseURL: String // API 的基础 URL
    private let apiKey: String // API 密钥
    private let model: String // 使用的模型名称
    
    // 初始化方法，接受 base URL、API 密钥和模型名称作为参数
    init(baseURL: String, apiKey: String, model: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.model = model
    }
    
    // 发送消息的方法
    func sendMessage(
        _ userMessage: String, // 用户输入的消息内容
        onReceive: @escaping (String) -> Void, // 接收到部分内容时的回调
        onFinish: @escaping () -> Void, // 流式结束时的回调
        completion: @escaping (Result<String, Error>) -> Void // 最终完成或失败时的回调
    ) {
        // 创建系统消息对象
        let systemMessage = GeminiMessage(role: "System", content: "You are a helpful assistant!")
        // 创建用户消息对象
        let userMessageObj = GeminiMessage(role: "user", content: userMessage)
        
        // 构建 ChatRequest 请求对象
        let request = ChatRequest(
            model: model, // 使用动态传入的模型名称
            stream: true, // 启用流式传输
            messages: [systemMessage, userMessageObj] // 包含系统消息和用户消息
        )
        
        // 检查 URL 是否有效
        guard let url = URL(string: baseURL) else {
            // 如果 URL 无效，返回错误
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        // 创建 URLRequest 对象
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST" // 设置 HTTP 方法为 POST
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type") // 设置请求头为 JSON 格式
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization") // 设置授权头
        
        do {
            // 将请求对象编码为 JSON 数据
            let requestData = try JSONEncoder().encode(request)
            urlRequest.httpBody = requestData // 设置请求体
        } catch {
            // 如果编码失败，返回错误
            completion(.failure(error))
            return
        }
        
        // 创建 URLSession 数据任务
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                // 如果发生网络错误，返回错误
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                // 如果没有接收到数据，返回错误
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            var fullResponse = "" // 用于存储完整的响应内容
            
            if let responseString = String(data: data, encoding: .utf8) {
                // 将响应数据按行分割
                let lines = responseString.components(separatedBy: "\n")
                
                for line in lines {
                    // 跳过空行和不以 "data: " 开头的行
                    guard !line.isEmpty, line.hasPrefix("data: ") else { continue }
                    
                    // 提取 JSON 数据部分
                    let jsonString = String(line.dropFirst(6))
                    if jsonString == "[DONE]" { continue } // 如果是结束标记，跳过
                    
                    if let jsonData = jsonString.data(using: .utf8),
                       let response = try? JSONDecoder().decode(ChatResponse.self, from: jsonData) {
                        // 解码 JSON 数据为 ChatResponse 对象
                        
                        if let content = response.choices.first?.delta.content, !content.isEmpty {
                            // 如果有增量内容，追加到完整响应中
                            fullResponse += content
                            DispatchQueue.main.async {
                                onReceive(content) // 实时传递增量内容
                            }
                        }
                        
                        if let finishReason = response.choices.first?.finish_reason, finishReason == "stop" {
                            // 如果完成原因标记为 "stop"，通知流式结束
                            DispatchQueue.main.async {
                                onFinish()
                            }
                        }
                    }
                }
                
                if !fullResponse.isEmpty {
                    // 如果有完整的响应内容，返回成功结果
                    completion(.success(fullResponse))
                } else {
                    // 如果没有有效内容，返回错误
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response content"])))
                }
            }
        }
        
        task.resume() // 启动数据任务
    }
}
