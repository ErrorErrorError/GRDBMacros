//
//  TableMacro.swift
//
//
//  Created by ErrorErrorError on 1/12/24.
//
//

import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

enum DatabaseRecordMacro {
  static let packageName = "GRDB"

  static let recordType = "DatabaseRecord"
  static let fetchableType = "FetchableRecord"
  static let persistableType = "PersistableRecord"
  static let columnType = "Column"

  static func qualified(_ type: DeclSyntax) -> TypeSyntax { "\(raw: packageName).\(raw: type)" }

  enum Error: Swift.Error, CustomStringConvertible {
    case onlyClassOrStructs

    var description: String {
      switch self {
      case .onlyClassOrStructs:
        "@\(recordType) macro can only be attached to classes or structs."
      }
    }
  }

  struct MemberColumn {
    let name: TokenSyntax
    let columnAttribute: AttributeSyntax?
  }

  struct ExtensionWithBody {
    let name: TypeSyntax
    let body: () -> MemberBlockItemListSyntax
  }
}

extension DatabaseRecordMacro: ExtensionMacro {
  static func expansion(
    of node: SwiftSyntax.AttributeSyntax,
    attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
    providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
    conformingTo protocols: [SwiftSyntax.TypeSyntax],
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
    guard declaration.is(StructDeclSyntax.self) || declaration.is(ClassDeclSyntax.self) else {
      throw Error.onlyClassOrStructs
    }

    let isPublic = declaration.modifiers.map(\.name.tokenKind).contains(.keyword(.public))
    let isClass = declaration.is(ClassDeclSyntax.self)

    let access = if isPublic {
      TokenSyntax(.keyword(.public), trailingTrivia: [.spaces(1)], presence: .present)
    } else {
      TokenSyntax(.stringSegment(""), presence: .missing)
    }

    let inherited = declaration.inheritanceClause?.inheritedTypes ?? []

    let args: [MemberColumn] = declaration.memberBlock.members
      .compactMap(MemberColumn.init)

    let needsExtImpl: [ExtensionWithBody] = [
      .init(name: fetchableType) {
        isClass ? "" :
        """
        \(raw: access)init(row: \(raw: qualified("Row"))) {
        \(raw: args.map(\.fetchableDecl.trimmedDescription).joined(separator: "\n"))
        }
        """
      },
      .init(name: persistableType) {
        """
        \(raw: access)func encode(to container: inout \(raw: qualified("PersistenceContainer"))) throws {
        \(raw: args.map(\.encodeDecl.trimmedDescription).joined(separator: "\n"))
        }
        """
      }
    ]
    .filter { ext in
      !inherited
        .map(\.type)
        .contains {
          $0.trimmedDescription == ext.name.trimmedDescription ||
            $0.trimmedDescription == ext.qualifiedTypeName.trimmedDescription
        }
    }

    let columns: ExtensionDeclSyntax? = if !args.isEmpty {
      ExtensionDeclSyntax(extendedType: type.trimmed) {
        """
        \(raw: access)enum Columns {
        \(raw: args.map(\.columnDecl.trimmedDescription).joined(separator: "\n"))
        }
        """
      }
    } else {
      nil
    }

    let databaseSelection: ExtensionDeclSyntax? = if !args.isEmpty {
      ExtensionDeclSyntax(extendedType: type.trimmed) {
        """
        \(raw: access)static let databaseSelection: [any \(raw: qualified("SQLSelectable"))] = [
        \(raw: args.map(\.columnProperty.trimmedDescription).joined(separator: ",\n"))
        ]
        """
      }
    } else {
      nil
    }

    let extensions = [columns, databaseSelection]
      .compactMap { $0 }

    return needsExtImpl.map { $0.decl(for: type.trimmed) } + extensions
  }
}

extension DatabaseRecordMacro: MemberMacro {
  static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    if declaration.is(StructDeclSyntax.self) {
      return []
    }
    guard let declaration = declaration.as(ClassDeclSyntax.self) else {
      throw Error.onlyClassOrStructs
    }

    let isPublic = declaration.modifiers.map(\.name.tokenKind).contains(.keyword(.public))

    let access = if isPublic {
      TokenSyntax(.keyword(.public), trailingTrivia: [.spaces(1)], presence: .present)
    } else {
      TokenSyntax(.stringSegment(""), presence: .missing)
    }

    let inherited = declaration.inheritanceClause?.inheritedTypes ?? []
    
    if inherited.map(\.type).contains(where: {
      $0.trimmedDescription == fetchableType ||
      $0.trimmedDescription == qualified(DeclSyntax(stringLiteral: fetchableType)).trimmedDescription
    }) {
      return []
    }

    let args: [MemberColumn] = declaration.memberBlock.members
      .compactMap(MemberColumn.init)

    return [
        """
        \(raw: access)required init(row: \(raw: qualified("Row"))) {
        \(raw: args.map(\.fetchableDecl.trimmedDescription).joined(separator: "\n"))
        }
        """
    ]
  }
}

// MARK: - MemberColumn + init & properties

extension DatabaseRecordMacro.MemberColumn {
  var fetchableDecl: DeclSyntax {
    "   self.\(raw: name) = row[\(raw: columnProperty)]"
  }

  var encodeDecl: DeclSyntax {
    "   container[\(raw: columnProperty)] = \(raw: name)"
  }

  var columnDecl: DeclSyntax {
    "   static let \(raw: name) = \(raw: columnInit)"
  }

  var columnProperty: DeclSyntax { "Columns.\(raw: name)" }

  private var columnInit: TypeSyntax {
    if let attr = columnAttribute {
      DatabaseRecordMacro.qualified(
        """
        \(raw: attr.attributeName)(\(attr.arguments ?? .argumentList([])))
        """
      )
    } else {
      DatabaseRecordMacro.qualified(
        """
        \(raw: DatabaseRecordMacro.columnType)("\(raw: name)")
        """
      )
    }
  }

  init?(_ member: MemberBlockItemSyntax) {
    guard let variable = member.decl.as(VariableDeclSyntax.self) else {
      // Not a variable declaration
      return nil
    }

    guard !variable.modifiers.map(\.name.tokenKind).contains(.keyword(.static)) else {
      // Ignore static properties
      return nil
    }

    let memberAttrs = variable.attributes.compactMap { element in
      if case let .attribute(attr) = element {
        return attr
      }
      return nil
    }

    // Check if property has transient, or any associated properties. If so, omit member.
    guard !memberAttrs.map(\.attributeName.trimmedDescription).contains(
      where: { 
        $0 == "Transient" ||
        $0 == "HasMany"
      }
    ) else {
      // Contains transient, so should not add to database
      return nil
    }

    guard let binding = variable.bindings.first,
          let memberName = binding.pattern.as(IdentifierPatternSyntax.self) else {
      // Does not have a variable name, so should not add to database
      return nil
    }

    // Do not support computed properties. Only allow accessors `willSet` and `didSet`
    let hasAccessors = if let accessors = binding.accessorBlock?.accessors {
      switch accessors {
      case let .accessors(arr):
        !arr.filter {
          $0.accessorSpecifier.tokenKind != .keyword(.willSet) &&
            $0.accessorSpecifier.tokenKind != .keyword(.didSet)
        }
        .isEmpty
      case .getter:
        true
      }
    } else {
      false
    }

    guard !hasAccessors else {
      return nil
    }

    self.init(
      name: memberName.identifier.trimmed,
      columnAttribute: memberAttrs.first { $0.attributeName.trimmedDescription == "Column" }
    )
  }
}

extension DatabaseRecordMacro.ExtensionWithBody {
  var qualifiedTypeName: TypeSyntax { "\(raw: DatabaseRecordMacro.packageName).\(raw: name)" }

  init(
    name: String,
    @MemberBlockItemListBuilder body: @escaping () -> MemberBlockItemListSyntax = { [] }
  ) {
    self.name = .init(stringLiteral: name).trimmed
    self.body = body
  }

  func decl(for type: some TypeSyntaxProtocol) -> ExtensionDeclSyntax {
    ExtensionDeclSyntax(
      extendedType: type,
      inheritanceClause: .init(inheritedTypes: [.init(type: qualifiedTypeName)]),
      memberBlockBuilder: body
    )
  }
}
