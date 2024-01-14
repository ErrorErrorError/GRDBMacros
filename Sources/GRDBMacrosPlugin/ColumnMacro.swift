//
//  File.swift
//  
//
//  Created by ErrorErrorError on 1/13/24.
//  
//

import SwiftSyntax
import SwiftSyntaxMacros

// Stub macro. Mimics `GRDB.Column` struct.
enum ColumnMacro {}

extension ColumnMacro: PeerMacro {
  public static func expansion(
    of node: SwiftSyntax.AttributeSyntax,
    providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.DeclSyntax] {
    []
  }
}
