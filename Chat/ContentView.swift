import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            let baseURL = "https://azyasaxi.cloudns.org/v1/chat/completions"
            let apiKey = "AIzaSyAsmG9yGsqS08hUmpGoGzM2AH-gmdk05p8"
            let model = "gemini-2.0-pro-exp-02-05"
            ChatUI(baseURL: baseURL, apiKey: apiKey, model: model)
        }
    }
}
