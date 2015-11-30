// HTTPClientType.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Zewo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import HTTP

public protocol HTTPClientType {
    var client: TCPClientType { get }
    var serializer: HTTPRequestSerializerType  { get }
    var parser: HTTPResponseParserType { get }
}

extension HTTPClientType {
    public func send(request: HTTPRequest, result: (Void throws -> HTTPResponse) -> Void) {
        client.connect { connectResult in
            do {
                let stream = try connectResult()
                var headers = request.headers
                headers["Host"] = "\(self.client.host):\(self.client.port)"
                let newRequest = HTTPRequest(
                    method: request.method,
                    uri: request.uri,
                    majorVersion: request.majorVersion,
                    minorVersion: request.minorVersion,
                    headers: headers,
                    body: request.body
                )
                self.serializer.serializeRequest(stream, request: newRequest) { serializeResult in
                    do {
                        try serializeResult()
                    } catch {
                        result { throw error }
                    }
                }
                self.parser.parseResponse(stream) { parseResult in
                    do {
                        let response = try parseResult()
                        result { response }
                    } catch {
                        result { throw error }
                    }
                }
            } catch {
                result { throw error }
            }
        }
    }
}