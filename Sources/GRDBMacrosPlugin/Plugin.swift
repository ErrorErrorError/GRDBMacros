//
//  Plugin.swift
//
//
//  Created by ErrorErrorError on 1/12/24.
//
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct GRDBMacrosPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    DatabaseRecordMacro.self,
    ColumnMacro.self,
    TransientMacro.self,
    HasManyMacro.self
  ]
}
