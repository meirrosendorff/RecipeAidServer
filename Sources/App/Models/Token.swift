//
//  Token.swift
//  App
//
//  Created by Meir Rosendorff on 2019/07/03.
//

import Foundation
import Vapor
import FluentSQLite
import Authentication

final class Token: Codable {
  
  var id: UUID?
  var token: String
  var userID: User.ID
  
  init(token: String, userID: User.ID) {
    
    self.token = token
    self.userID = userID
  }
}

extension Token: SQLiteUUIDModel {}

extension Token: Migration {
  
  static func prepare(on connection: SQLiteConnection) -> Future<Void> {
    
    return Database.create(self, on: connection) { builder in
      try addProperties(to: builder)
      builder.reference(from: \.userID, to: \User.id)
    }
  }
}

extension Token: Content {}

extension Token {
  
  static func generate(for user: User) throws -> Token {
    
    let random = try CryptoRandom().generateData(count: 16)
    
    return try Token( token: random.base64EncodedString(), userID: user.requireID())
  }
}

extension Token: Authentication.Token {
  typealias UserType = User
  
  static let userIDKey: UserIDKey = \Token.userID
}

extension Token: BearerAuthenticatable {

   static let tokenKey: TokenKey = \Token.token
}
