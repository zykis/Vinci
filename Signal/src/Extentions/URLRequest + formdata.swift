//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation

extension URLRequest {
    static func createFormDataBody(parameters: [String: String],
                                            boundary: String,
                                            dataKey: String,
                                            data: Data,
                                            mimeType: String,
                                            filename: String) -> Data {
        let body = NSMutableData()
        let boundaryPrefix = "--\(boundary)\r\n"
        
        for (key, value) in parameters {
            body.append(boundaryPrefix.data(using: .utf8)!)
            body.append("Content-Disposition:form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        body.append(boundaryPrefix.data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(dataKey)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        let d = body as Data
        let s = String(data: d, encoding: .utf8)
        print(s!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--".data(using: .utf8)!)
        
        return body as Data
    }
}
