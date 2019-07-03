//
//  User.swift
//  App
//
//  Created by Meir Rosendorff on 2019/07/03.
//

import Foundation
import Vapor
import FluentSQLite
import Authentication

final class User: Codable {
  
  var id: UUID?
  var email: String
  var username: String
  var passwd: String
  var profilePic: String?
  var isAdmin: Bool?
  
  init(email: String, username: String, passwd: String, profilePic: String? = nil, isAdmin: Bool? = nil) {
    
    self.email = email
    self.username = username
    self.passwd = passwd
    self.profilePic = profilePic
    self.isAdmin = isAdmin ?? false
  }
}

extension User {
  
  final class Public: Codable {
    
    var id: UUID?
    var username: String
    var email: String
    var isAdmin: Bool
    
    init(id: UUID?, username: String, email: String, isAdmin: Bool) {
      
      self.email = email
      self.username = username
      self.id = id
      self.isAdmin = isAdmin
    }
  }

  func getPublic() -> User.Public {
    return User.Public(id: id, username: username, email: email, isAdmin: isAdmin ?? false)
  }
}

extension Future where T: User {
  
  func convertToPublic() -> Future<User.Public> {
    
    return self.map(to: User.Public.self) { user in
      return user.getPublic()
    }
  }
}

extension User: BasicAuthenticatable {
  static let usernameKey: UsernameKey = \User.username
  static let passwordKey: PasswordKey = \User.passwd
}

extension User: SQLiteUUIDModel {}
extension User: Migration {
  static func prepare(on connection: SQLiteConnection) -> Future<Void> {
    return Database.create(self, on: connection) { builder in
      try addProperties(to: builder)
      builder.unique(on: \.username)
    }
  }
}
extension User: Content {}
extension User: Parameter {}
extension User: TokenAuthenticatable {
  typealias TokenType = Token
}

extension User.Public: Content {}
struct AdminUser: Migration {

  typealias Database = SQLiteDatabase
  
  static func prepare(on connection: SQLiteConnection) -> Future<Void> {
    
    let passwrd = try? BCrypt.hash("admin")
    
    guard let hashedPasswd = passwrd else {
      fatalError("Unable to create Admin user")
    }
    
    let user = User(email: "admin@admin.com", username: "admin", passwd: hashedPasswd)
    user.isAdmin = true
    
    return user.save(on: connection).transform(to: ())
  }
  
  static func revert(on connection: SQLiteConnection) -> Future<Void> {
    return .done(on: connection)
  }
}
