//
//  Macros.swift
//
//
//  Created by ErrorErrorError on 1/13/24.
//
//

import GRDB

@attached(
  extension,
  conformances: FetchableRecord, PersistableRecord,
  names: named(init(row:)), named(encode(to:)), named(Columns), named(databaseSelection)
)
@attached(
  member,
  names: named(init(row:))
)
public macro DatabaseRecord() = #externalMacro(module: "GRDBMacrosPlugin", type: "DatabaseRecordMacro")

@attached(peer)
public macro Transient() = #externalMacro(module: "GRDBMacrosPlugin", type: "TransientMacro")

@attached(peer)
public macro Column(_ name: String) = #externalMacro(module: "GRDBMacrosPlugin", type: "ColumnMacro")

@attached(accessor, names: arbitrary)
@attached(peer, names: arbitrary)
public macro HasMany() = #externalMacro(module: "GRDBMacrosPlugin", type: "HasManyMacro")
