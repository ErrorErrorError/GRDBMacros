//
//  TransientMacro.swift
//
//
//  Created by ErrorErrorError on 1/12/24.
//  
//

import SwiftSyntax
import SwiftSyntaxMacros

// Stub macro
enum TransientMacro {}

extension TransientMacro: PeerMacro {
  public static func expansion(
    of node: SwiftSyntax.AttributeSyntax,
    providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.DeclSyntax] {
    []
  }
}
