import SwiftUI

struct RegisterView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var registrationMessage = ""  // 用于显示注册消息
    
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
            
            Spacer()  // 确保注册容器在页面中垂直居中
            
            VStack {
                // 邮箱输入框
                VStack(alignment: .leading) {
                    Text("Email").font(.caption).foregroundStyle(.secondary)
                    TextField("email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .onTapGesture {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                }
                
                // 用户名输入框
                VStack(alignment: .leading) {
                    Text("Username").font(.caption).foregroundStyle(.secondary)
                    TextField("username", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .onTapGesture {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                }
                
                // 密码输入框
                VStack(alignment: .leading) {
                    Text("Password").font(.caption).foregroundStyle(.secondary)
                    SecureField("password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .onTapGesture {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                }
                
                // 确认密码输入框
                VStack(alignment: .leading) {
                    Text("Confirm Password").font(.caption).foregroundStyle(.secondary)
                    SecureField("confirm password", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .onTapGesture {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                }
                
                Button(action: {
                    // 注册逻辑
                    if email.isEmpty || username.isEmpty || password.isEmpty || confirmPassword.isEmpty {
                        registrationMessage = "所有字段都是必填的"
                    } else if password != confirmPassword {
                        registrationMessage = "密码不匹配"
                    } else {
                        saveUserData(email: email, username: username, password: password)
                        registrationMessage = "注册成功！"
                        // 可以选择在注册成功后关闭视图
                        // presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Text("Sign up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)  // 移除默认的蓝色样式
                
                // 显示注册消息
                Text(registrationMessage)
                    .foregroundColor(.red)
                    .padding()
                
                Spacer()  // 确保底部有间距
            }
            .padding()
            .navigationBarBackButtonHidden(false)
        }
    }
    
    private func saveUserData(email: String, username: String, password: String) {
        let userData = "\(email),\(username),\(password)\n"
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("users.txt")
        
        if let data = userData.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                // 追加到文件
                if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                // 创建新文件
                try? data.write(to: fileURL)
            }
        }
    }
}
