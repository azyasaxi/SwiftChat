import SwiftUI

struct LoginView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var usernameOrEmail = ""
    @State private var password = ""
    @State private var isLoggedIn = false  // 用于跟踪登录状态
    @State private var currentUsername = "" // 当前用户名
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            HStack {
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
            }
            .padding()
            .background(.background)
            
            Spacer()  // 确保登录容器在页面中垂直居中
            
            VStack {
                // 用户名或邮箱输入框
                VStack(alignment: .leading) {
                    Text("Username or Email").font(.caption).foregroundStyle(.secondary)
                    TextField("username or email", text: $usernameOrEmail)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                }
                
                // 密码输入框
                VStack(alignment: .leading) {
                    Text("Password").font(.caption).foregroundStyle(.secondary)
                    SecureField("password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                }
                
                Button(action: {
                    // 登录逻辑
                    if (usernameOrEmail == "3075657646@qq.com" || usernameOrEmail == "wujiafa") && password == "123456789" {
                        isLoggedIn = true
                        currentUsername = "wujiafa" // 设置当前用户名
                        // 可以选择在登录成功后关闭视图
                        // presentationMode.wrappedValue.dismiss()
                    } else {
                        // 登录失败处理
                    }
                }) {
                    Text("Sign in")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)  // 移除默认的蓝色样式
                
                NavigationLink(destination: RegisterView()) {  // 跳转到注册界面
                    Text("Sign up")
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)  // 移除默认的蓝色样式
                
                Spacer()  // 确保底部有间距
            }
            .padding()
            .navigationBarBackButtonHidden(false)
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .fullScreenCover(isPresented: $isLoggedIn) {
            // 登录成功后跳转到 ConversationListView
            ConversationListView(currentUsername: currentUsername)
        }
    }
    
    private func validateUser(usernameOrEmail: String, password: String) -> Bool {
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("users.txt")
        
        if let data = try? String(contentsOf: fileURL, encoding: .utf8) {
            let users = data.split(separator: "\n")
            for user in users {
                let details = user.split(separator: ",")
                if details.count == 3 {
                    let storedUsername = String(details[1])
                    let storedPassword = String(details[2])
                    if (storedUsername == usernameOrEmail || details[0] == usernameOrEmail) && storedPassword == password {
                        return true
                    }
                }
            }
        }
        return false
    }
}
