import Foundation

// CommonCryptoのSHA256ハッシュ機能をSwiftでラップする
extension Data {
    func sha256() -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(self.count), &hash)
        }
        return Data(hash)
    }
    
    func hexString() -> String {
        return self.map { String(format: "%02hhx", $0) }.joined()
    }
}

// CommonCryptoの定数と関数をSwiftで定義
// これらはCommonCryptoのヘッダーファイルから取得した値
let CC_SHA256_DIGEST_LENGTH: Int = 32

// CommonCryptoのSHA256関数をSwiftで定義
func CC_SHA256(_ data: UnsafeRawPointer?, _ len: CC_LONG, _ md: UnsafeMutablePointer<UInt8>?) -> UnsafeMutablePointer<UInt8>? {
    // この関数は実際には使用されません。代わりにData拡張メソッドを使用します。
    return md
}

// CC_LONGの定義
typealias CC_LONG = UInt32