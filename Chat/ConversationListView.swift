import SwiftUI

// 用户设置结构体
struct UserSettings {
    var hobbies: String
    var position: String
    var income: String
    
    // 转换为字典格式
    func toDictionary() -> [String: Any] {
        return [
            "hobbies": hobbies,
            "position": position,
            "income": income
        ]
    }
}

struct ConversationListView: View {
    @State private var searchText = ""
    @State private var showSettings = false  // 控制设置界面的显示
    @State private var hobbies = "吃辣"  // 默认爱好
    @State private var selectedPosition = "学生"  // 默认职位
    @State private var income = "1500"  // 默认生活费
    let positions = ["学生", "白领", "其他"]  // 职位选项
    
    var currentUsername: String  // 接收当前用户名
    
    // 用于返回用户设置
    @State private var userSettings: UserSettings? = nil
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 搜索栏
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("搜索", text: $searchText)
                    }
                    .padding(8)
                    .background(.secondary.opacity(0.1))
                    .cornerRadius(8)
                    let baseURL = "https://azyasaxi.cloudns.org/v1/chat/completions"
                    let apiKey = "AIzaSyAsmG9yGsqS08hUmpGoGzM2AH-gmdk05p8"
                    let model = "gemini-2.0-pro-exp-02-05"
                    NavigationLink(destination: ChatUI(baseURL: baseURL, apiKey: apiKey, model: model)) {
                        Text(">>")
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)  // 添加这行来移除默认的蓝色样式
                    .navigationBarBackButtonHidden()
                }
                
                // 标题栏
                HStack {
                    Text("对话")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    Spacer()
                    let baseURL = "https://azyasaxi.cloudns.org/v1/chat/completions"
                    let apiKey = "AIzaSyAsmG9yGsqS08hUmpGoGzM2AH-gmdk05p8"
                    let model = "gemini-2.0-pro-exp-02-05"
                    NavigationLink(destination: ChatUI(baseURL: baseURL, apiKey: apiKey, model: model)) {  // 将 Button 改为 NavigationLink
                        HStack(spacing: 4) {
                            Text("新建")
                            Image(systemName: "plus")
                        }
                        .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // 会话列表
                ScrollView {
                    VStack(spacing: 0) {
                        ConversationRow(
                            title: "简单中文对话示例",
                            time: "7:38下午"
                        )
                    }
                }
                
                Spacer()
                
                // 底部用户信息
                HStack {
                    // 用户头像
                    NavigationLink(destination: LoginView()) {  // 点击头像进入登录界面
                        Circle()
                            .fill(.white)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .strokeBorder(.secondary, lineWidth: 1)
                            )
                    }
                    
                    Text(currentUsername)  // 显示当前用户名
                        .foregroundStyle(.primary)
    
                    Spacer()
                    
                    // 设置按钮
                    Button(action: {
                        withAnimation {
                            showSettings.toggle()  // 切换设置界面的显示
                        }
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20))
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .overlay(
                // 设置界面
                VStack {
                    if showSettings {
                        VStack(spacing: 20) {
                            Text("Setting")
                                .font(.title)
                                .padding()
                                .foregroundColor(.primary)
                            
                            TextField("爱好", text: $hobbies)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding()
                                .foregroundColor(.primary)
                            
                            Picker("职位", selection: $selectedPosition) {
                                ForEach(positions, id: \.self) { position in
                                    Text(position).foregroundColor(.primary)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding()
                            
                            if selectedPosition == "学生" {
                                TextField("生活费", text: $income)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding()
                            } else {
                                TextField("工资/存款", text: $income)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding()
                            }
                            
                            Button(action: {
                                // 处理保存设置逻辑
                                userSettings = UserSettings(hobbies: hobbies, position: selectedPosition, income: income)
                                let settingsDict = userSettings?.toDictionary() ?? [:]
                                print("用户设置: \(settingsDict)")
                                showSettings = false  // 关闭设置界面
                            }) {
                                Text("保存设置")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .foregroundColor(.primary)
                                    .cornerRadius(8)
                            }
                            .padding()
                        }
                        .background(Color(UIColor.systemBackground))  // 自适应背景色
                        .cornerRadius(20)
                        .shadow(radius: 10)
                        .padding()
                        .transition(.move(edge: .bottom))  // 从下往上出现
                    }
                }
            )
        }
    }
}

// 会话列表项组件
struct ConversationRow: View {
    let title: String
    let time: String
    
    var body: some View {
        let baseURL = "https://azyasaxi.cloudns.org/v1/chat/completions"
        let apiKey = "AIzaSyAsmG9yGsqS08hUmpGoGzM2AH-gmdk05p8"
        let model = "gemini-2.0-pro-exp-02-05"
        NavigationLink(destination: ChatUI(baseURL: baseURL, apiKey: apiKey, model: model)) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .foregroundStyle(.primary)
                    Text(time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)  // 这里也添加 plain 样式
    }
}
