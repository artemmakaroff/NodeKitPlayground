import NodeKit
import UIKit

// MARK: - Constants

enum Constants {
  static let url = "https://sentim-api.herokuapp.com/api/v1/"
  static let text = "We have been through much darker times than these, and somehow each generation of Americans carried us through to the other side, he said."
}

enum RequestKeys {
  static let text = "text"
}

// MARK: - Errors

enum CustomError: Error {
  case badURL
}

// MARK: - Extensions

extension URL {
  static func from(string: String) throws -> URL {
    guard let url = URL(string: string) else {
      throw CustomError.badURL
    }
    return url
  }
}

// MARK: - Entities

struct SentimEntity: DTODecodable {
  let result: TextScanEntity
  let sentences: [SentenceEntity]
  
  static func from(dto: SentimEntry) throws -> SentimEntity {
    return try .init(result: .from(dto: dto.result), sentences: dto.sentences.map { try .from(dto: $0) })
  }
}

struct TextScanEntity: DTODecodable {
  let polarity: Double
  let type: String
  
  static func from(dto: TextScanEntry) throws -> TextScanEntity {
    return .init(polarity: dto.polarity, type: dto.type)
  }
}

struct SentenceEntity: DTODecodable {
  let sentence: String
  let sentiment: TextScanEntity
  
  static func from(dto: SentenceEntry) throws -> SentenceEntity {
    return try .init(sentence: dto.sentence, sentiment: .from(dto: dto.sentiment))
  }
}

// MARK: - Entries

struct SentimEntry: Codable, RawMappable {
  typealias Raw = Json
  
  let result: TextScanEntry
  let sentences: [SentenceEntry]
}

struct TextScanEntry: Codable, RawMappable {
  typealias Raw = Json
  
  let polarity: Double
  let type: String
}

struct SentenceEntry: Codable, RawMappable {
  typealias Raw = Json
  
  let sentence: String
  let sentiment: TextScanEntry
}

// MARK: - Provider

enum TextScanProvider: UrlRouteProvider {
  case text
  
  func url() throws -> URL {
    return try .from(string: Constants.url)
  }
}

// MARK: - Request

func scan() -> Observer<SentimEntity> {
  let params = [RequestKeys.text: Constants.text]
  return UrlChainsBuilder()
    .route(.post, TextScanProvider.text)
    .build()
    .process(params)
}

scan().onError { error in
  print("Error - \(error.localizedDescription)")
}.onCompleted { model in
  print("Model - \(model)")
}.onCanceled {
  print("Cancel")
}
