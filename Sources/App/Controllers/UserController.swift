//
//  UserController.swift
//  App
//
//  Created by Meir Rosendorff on 2019/07/03.
//

import Foundation
import Vapor
import Fluent
import Crypto
import Authentication

struct UserController: RouteCollection {
  
  func boot(router: Router) throws {
    
    let userRoutes = router.grouped("auth", "users")
    
    userRoutes.post(use: addUser)
    
    let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
    let guardAuthMiddleware = User.guardAuthMiddleware()
    let protected = userRoutes.grouped(basicAuthMiddleware, guardAuthMiddleware)
    
    protected.post("login", use: login)
    
    let tokenAuthMiddleware = User.tokenAuthMiddleware()
    
    let tokenAuthGroup = userRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
    tokenAuthGroup.post("login", "token", use: loginWithToken)
    tokenAuthGroup.get("profilePic", use: fetchProfilePic)
    tokenAuthGroup.post("makeAdmin", use: makeAdmin)
    tokenAuthGroup.get(use: allUsers)
    tokenAuthGroup.get("details", use: fetchUserDetails)
  }
  
  func addUser(_ req: Request) throws -> Future<User.Public> {
    
    return try req.content.decode(User.self).flatMap(to: User.Public.self) { newUser in
      newUser.passwd = try BCrypt.hash(newUser.passwd)
      return newUser.save(on: req).convertToPublic()
    }
  }
  
  func allUsers(_ req: Request) throws -> Future<[User.Public]> {
    
    return User.query(on: req).all().map { userSet in
      
      return userSet.map { user in return user.getPublic() }
    }
  }
  
  func login(_ req: Request) throws -> Future<Token> {
    
    let user = try req.requireAuthenticated(User.self)
    
    let token = try Token.generate(for: user)
    
    return token.save(on: req)
  }
  
  func loginWithToken(_ req: Request) throws -> Future<HTTPStatus> {
    
    return req.future(HTTPStatus.ok)
  }
  
  func fetchProfilePic(_ req: Request) throws -> String {
    
    let user = try req.requireAuthenticated(User.self)
    
    if let pic = user.profilePic {
      return pic
    } else {
      return ""
    }
  }
  
  func fetchUserDetails(_ req: Request) throws -> User.Public {
    
    return try req.requireAuthenticated(User.self).getPublic()
  }
  
  func makeAdmin(_ req: Request) throws -> Future<HTTPStatus> {
    
        let user = try req.requireAuthenticated(User.self)
    
        guard let adminStatus = user.isAdmin, adminStatus != false else {
          return req.future(HTTPStatus.forbidden)
        }
    
    guard let username = req.query[String.self, at: "name"] else {
      return req.future(HTTPStatus.badRequest)
    }

    return User.query(on: req).filter(\User.username == username).all().flatMap { users in
      
      users[0].isAdmin = true
      
      return users[0].save(on: req).transform(to: HTTPStatus.ok)
    }
  }
}

