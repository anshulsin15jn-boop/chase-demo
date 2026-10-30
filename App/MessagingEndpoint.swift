import Foundation
import Security
import DemoCore

enum MessagingEndpoint {
    private static let endpointKey = "demo-sms-endpoint"
    private static let enabledKey = "demo-sms-enabled"
    private static var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: "chase-demo-relay",
         kSecAttrAccount as String: "relay-token"]
    }
    static var address: String { UserDefaults.standard.string(forKey: endpointKey) ?? "" }
    static func validatedURL(_ value: String) -> URL? {
        guard let url = URL(string: value), url.scheme == "https", url.host != nil,
              url.user == nil, url.password == nil, url.query == nil, url.fragment == nil,
              url.path == "/send" else { return nil }
        return url
    }
    private static var token: String? {
        var request = query
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(request as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    static var delivery: DemoMessageDelivery {
        guard UserDefaults.standard.bool(forKey: enabledKey), let url = validatedURL(address),
              let token, token.count >= 32 else { return DisabledDemoMessageDelivery() }
        return HTTPDemoMessageDelivery(endpoint: url, relayToken: token)
    }
    static func save(address: String, token: String) -> Bool {
        let address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard validatedURL(address) != nil, token.count >= 32,
              token.unicodeScalars.allSatisfy({ (33...126).contains(Int($0.value)) }) else { return false }
        let data = Data(token.utf8)
        var status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecItemNotFound {
            var item = query
            item[kSecValueData as String] = data
            item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            status = SecItemAdd(item as CFDictionary, nil)
        }
        guard status == errSecSuccess else { return false }
        UserDefaults.standard.set(address, forKey: endpointKey)
        UserDefaults.standard.set(true, forKey: enabledKey)
        return true
    }
    static func disable() {
        UserDefaults.standard.set(false, forKey: enabledKey)
        SecItemDelete(query as CFDictionary)
    }
}
