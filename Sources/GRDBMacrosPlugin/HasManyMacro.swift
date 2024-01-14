//
//  HasManyMacro.swift
//
//
//  Created by ErrorErrorError on 1/13/24.
//
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

enum HasManyMacro {
  enum Error: Swift.Error, CustomStringConvertible {
    case onlyVariable
    case nonStaticValues
    case requiresMemberName
    case requiresTypeAnnotation
    case requiresGenericType

    var description: String {
      switch self {
      case .onlyVariable:
        "@HasMany macro can only be used on members of a class or struct"
      case .nonStaticValues:
        "@HasMany macro can only be used as a non-static member"
      case .requiresMemberName:
        "@HasMany macry requires member name."
      case .requiresTypeAnnotation, .requiresGenericType:
        "@HasMany macro requires annotation of type QueryInterfaceRequest<Destination>"
      }
    }
  }
}

extension HasManyMacro: PeerMacro {
  static func expansion(
    of node: SwiftSyntax.AttributeSyntax,
    providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.DeclSyntax] {
    guard let variable = declaration.as(VariableDeclSyntax.self) else {
      // Not a variable declaration
      throw Error.onlyVariable
    }

    guard let binding = variable.bindings.first,
          let memberName = binding.pattern.as(IdentifierPatternSyntax.self)
    else {
      throw Error.requiresMemberName
    }

    guard !variable.modifiers.map(\.name.tokenKind).contains(.keyword(.static)) else {
      throw Error.nonStaticValues
    }

    guard let type = binding.typeAnnotation else {
      throw Error.requiresTypeAnnotation
    }

    guard type.type.trimmedDescription.contains("QueryInterfaceRequest") else {
      throw Error.requiresTypeAnnotation
    }

    guard let identifier = type.type.as(IdentifierTypeSyntax.self) else {
      throw Error.requiresTypeAnnotation
    }

    guard let genericArgument = identifier.genericArgumentClause?.arguments.first else {
      throw Error.requiresTypeAnnotation
    }

    return [
      """
      static let \(raw: memberName.trimmed) = hasMany(\(raw: genericArgument).self)
      """
    ]
  }
}

extension HasManyMacro: AccessorMacro {
  static func expansion(
    of node: SwiftSyntax.AttributeSyntax,
    providingAccessorsOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.AccessorDeclSyntax] {
    guard let variable = declaration.as(VariableDeclSyntax.self) else {
      // Not a variable declaration
      return []
    }

    guard let binding = variable.bindings.first,
          let memberName = binding.pattern.as(IdentifierPatternSyntax.self)
    else {
      return []
    }

    return [
      """
      get {
        request(for: Self.\(raw: memberName.trimmed))
      }
      """
    ]
  }
}
