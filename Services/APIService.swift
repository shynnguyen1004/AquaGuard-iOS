//
//  APIService.swift
//  AquaGuard
//
//  Centralized HTTP client for all backend REST API calls.
//  Automatically attaches JWT token, decodes responses, and handles errors.
//
//  Usage:
//    let user: APIUser = try await APIService.shared.get("/auth/profile")
//    let _: EmptyData = try await APIService.shared.post("/sos", body: formData)
//

import Foundation
import UIKit

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidURL
    case noToken
    case unauthorized          // 401 — token expired or invalid
    case forbidden(String)     // 403 — role mismatch
    case badRequest(String)    // 400 — validation error
    case conflict(String)      // 409 — duplicate resource
    case notFound(String)      // 404
    case rateLimited(String)   // 429
    case serverError(String)   // 500
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:            return "Invalid URL"
        case .noToken:               return "Not authenticated"
        case .unauthorized:          return "Session expired. Please sign in again."
        case .forbidden(let msg):    return msg
        case .badRequest(let msg):   return msg
        case .conflict(let msg):     return msg
        case .notFound(let msg):     return msg
        case .rateLimited(let msg):  return msg
        case .serverError(let msg):  return msg
        case .decodingError(let e):  return "Data error: \(e.localizedDescription)"
        case .networkError(let e):   return "Network error: \(e.localizedDescription)"
        }
    }
}

// MARK: - API Service

class APIService {

    static let shared = APIService()

    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = NetworkConfig.requestTimeout
        config.timeoutIntervalForResource = NetworkConfig.uploadTimeout
        session = URLSession(configuration: config)

        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    // MARK: - Public API (typed convenience methods)

    /// GET request — decodes `data` field from response
    func get<T: Decodable>(_ endpoint: String) async throws -> T {
        return try await request(endpoint, method: "GET")
    }

    /// POST request with JSON body
    func post<T: Decodable>(_ endpoint: String, body: [String: Any]? = nil) async throws -> T {
        return try await request(endpoint, method: "POST", jsonBody: body)
    }

    /// PUT request with JSON body
    func put<T: Decodable>(_ endpoint: String, body: [String: Any]? = nil) async throws -> T {
        return try await request(endpoint, method: "PUT", jsonBody: body)
    }

    /// DELETE request
    func delete<T: Decodable>(_ endpoint: String) async throws -> T {
        return try await request(endpoint, method: "DELETE")
    }

    // MARK: - Public API (raw response — for when you need success/message too)

    /// Returns the full APIResponse wrapper (useful for checking message)
    func getRaw<T: Decodable>(_ endpoint: String) async throws -> APIResponse<T> {
        return try await requestRaw(endpoint, method: "GET")
    }

    func postRaw<T: Decodable>(_ endpoint: String, body: [String: Any]? = nil) async throws -> APIResponse<T> {
        return try await requestRaw(endpoint, method: "POST", jsonBody: body)
    }

    func putRaw<T: Decodable>(_ endpoint: String, body: [String: Any]? = nil) async throws -> APIResponse<T> {
        return try await requestRaw(endpoint, method: "PUT", jsonBody: body)
    }

    func deleteRaw<T: Decodable>(_ endpoint: String) async throws -> APIResponse<T> {
        return try await requestRaw(endpoint, method: "DELETE")
    }

    // MARK: - Multipart Upload (for SOS image upload)

    /// Upload images + form fields as multipart/form-data
    /// Returns decoded `data` from the response
    func uploadMultipart<T: Decodable>(
        _ endpoint: String,
        fields: [String: String],
        images: [(fieldName: String, data: Data, filename: String)]
    ) async throws -> T {
        guard let url = URL(string: "\(NetworkConfig.apiBaseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Attach token
        if let token = TokenManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Build multipart body
        var body = Data()

        // Text fields
        for (key, value) in fields {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }

        // Image files
        for image in images {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(image.fieldName)\"; filename=\"\(image.filename)\"\r\n")
            body.append("Content-Type: image/jpeg\r\n\r\n")
            body.append(image.data)
            body.append("\r\n")
        }

        body.append("--\(boundary)--\r\n")
        request.httpBody = body

        // Extend timeout for uploads
        request.timeoutInterval = NetworkConfig.uploadTimeout

        return try await executeRequest(request)
    }

    // MARK: - No Auth requests (login, register, forgot-password)

    /// POST without requiring JWT token (for auth endpoints)
    func postNoAuth<T: Decodable>(_ endpoint: String, body: [String: Any]? = nil) async throws -> T {
        return try await request(endpoint, method: "POST", jsonBody: body, requiresAuth: false)
    }

    func postNoAuthRaw<T: Decodable>(_ endpoint: String, body: [String: Any]? = nil) async throws -> APIResponse<T> {
        return try await requestRaw(endpoint, method: "POST", jsonBody: body, requiresAuth: false)
    }

    // MARK: - Core Request Engine

    private func request<T: Decodable>(
        _ endpoint: String,
        method: String,
        jsonBody: [String: Any]? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        let response: APIResponse<T> = try await requestRaw(
            endpoint, method: method, jsonBody: jsonBody, requiresAuth: requiresAuth
        )

        guard response.success, let data = response.data else {
            throw APIError.badRequest(response.message ?? "Unknown error")
        }

        return data
    }

    private func requestRaw<T: Decodable>(
        _ endpoint: String,
        method: String,
        jsonBody: [String: Any]? = nil,
        requiresAuth: Bool = true
    ) async throws -> APIResponse<T> {
        guard let url = URL(string: "\(NetworkConfig.apiBaseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Attach JWT token
        if requiresAuth {
            guard let token = TokenManager.shared.getToken() else {
                throw APIError.noToken
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Encode body
        if let body = jsonBody {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        return try await executeRawRequest(request, requiresAuth: requiresAuth)
    }

    // MARK: - Execute & Decode

    private func executeRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let response: APIResponse<T> = try await executeRawRequest(request)

        guard response.success, let data = response.data else {
            throw APIError.badRequest(response.message ?? "Unknown error")
        }

        return data
    }

    private func executeRawRequest<T: Decodable>(_ request: URLRequest, requiresAuth: Bool = true) async throws -> APIResponse<T> {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(
                NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            )
        }

        // Handle HTTP status errors
        switch httpResponse.statusCode {
        case 200...299:
            break // Success — decode below
        case 401:
            if requiresAuth {
                // Token expired — auto-logout
                await MainActor.run { TokenManager.shared.clearSession() }
                throw APIError.unauthorized
            } else {
                // Login/register failed — wrong credentials, NOT session expired
                let msg = extractMessage(from: data)
                throw APIError.badRequest(msg)
            }
        case 403:
            let msg = extractMessage(from: data)
            throw APIError.forbidden(msg)
        case 404:
            let msg = extractMessage(from: data)
            throw APIError.notFound(msg)
        case 409:
            let msg = extractMessage(from: data)
            throw APIError.conflict(msg)
        case 429:
            let msg = extractMessage(from: data)
            throw APIError.rateLimited(msg)
        default:
            let msg = extractMessage(from: data)
            throw APIError.serverError(msg)
        }

        // Decode response
        do {
            let apiResponse = try decoder.decode(APIResponse<T>.self, from: data)
            return apiResponse
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Helpers

    /// Extract `message` field from error response JSON
    private func extractMessage(from data: Data) -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let message = json["message"] as? String {
            return message
        }
        return "Server error"
    }
}

// MARK: - Data Extension for Multipart

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
