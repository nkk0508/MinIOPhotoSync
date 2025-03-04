import Foundation
// 共通のモデル定義をインポート

class MinIOXMLParser: NSObject, XMLParserDelegate {
    private var currentElement = ""
    private var currentKey = ""
    private var currentLastModified = ""
    private var currentETag = ""
    private var currentSize = ""
    private var currentChecksum = ""
    
    private var objects: [MinIOObject] = []
    private var isInContents = false
    
    struct MinIOObject {
        let key: String
        let lastModified: Date
        let eTag: String
        let size: Int
        let checksum: String?
    }
    
    func parse(data: Data) -> [MinIOObject] {
        objects = []
        
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        
        return objects
    }
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        
        if elementName == "Contents" {
            isInContents = true
            currentKey = ""
            currentLastModified = ""
            currentETag = ""
            currentSize = ""
            currentChecksum = ""
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Contents" {
            isInContents = false
            
            // Create a MinIOObject from the collected data
            if !currentKey.isEmpty {
                let dateFormatter = ISO8601DateFormatter()
                let lastModified = dateFormatter.date(from: currentLastModified) ?? Date()
                let size = Int(currentSize) ?? 0
                
                let object = MinIOObject(
                    key: currentKey,
                    lastModified: lastModified,
                    eTag: currentETag,
                    size: size,
                    checksum: currentChecksum.isEmpty ? nil : currentChecksum
                )
                
                objects.append(object)
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let data = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if isInContents && !data.isEmpty {
            switch currentElement {
            case "Key":
                currentKey += data
            case "LastModified":
                currentLastModified += data
            case "ETag":
                currentETag += data
            case "Size":
                currentSize += data
            default:
                break
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        if let string = String(data: CDATABlock, encoding: .utf8) {
            // CDATAブロックの内容を文字列として処理
            let data = string.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if isInContents && !data.isEmpty {
                switch currentElement {
                case "Key":
                    currentKey += data
                case "LastModified":
                    currentLastModified += data
                case "ETag":
                    currentETag += data
                case "Size":
                    currentSize += data
                default:
                    break
                }
            }
        }
    }
}

// Extension to convert MinIOObject to MinIOPhoto
extension MinIOXMLParser.MinIOObject {
    func toMinIOPhoto(baseURL: String, bucketName: String) -> MinIOPhoto {
        let id = key.replacingOccurrences(of: ".jpg", with: "")
        let url = URL(string: "\(baseURL)/\(bucketName)/\(key)")!
        
        return MinIOPhoto(
            id: id,
            url: url,
            lastModifiedDate: lastModified,
            checksum: checksum
        )
    }
}
