import MacroTesting
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import GRDBMacrosPlugin

final class GRDBMacrosTests: XCTestCase {
  override func invokeTest() {
    withMacroTesting(
      macros: [
        "DatabaseRecord": DatabaseRecordMacro.self,
        "HasMany": HasManyMacro.self
      ]
    ) {
      super.invokeTest()
    }
  }

  func testMacro() throws {
    assertMacro {
      """
      @DatabaseRecord
      struct Author {
        var id: Int64?
        @Column("title") var name: String
        var countryCode: String?

        @Transient var somePropertyToExclude = true

        @HasMany var books: QueryInterfaceRequest<Book>
      }

      @DatabaseRecord
      struct Book {
        var id: Int64?
        var authorId: Int64
        var title: String

        @BelongsTo var author: QueryInterfaceRequest<Author>
      }
      """
    } expansion: {
      """
      struct Author {
        var id: Int64?
        @Column("title") var name: String
        var countryCode: String?

        @Transient var somePropertyToExclude = true

        var books: QueryInterfaceRequest<Book> {
          get {
            request(for: Self.books)
          }
        }

        static let books = hasMany(Book.self)
      }
      struct Book {
        var id: Int64?
        var authorId: Int64
        var title: String

        @BelongsTo var author: QueryInterfaceRequest<Author>
      }

      extension Author: GRDB.FetchableRecord {
        init(row: GRDB.Row) {
           self.id = row[Columns.id]
           self.name = row[Columns.name]
           self.countryCode = row[Columns.countryCode]
        }
      }

      extension Author: GRDB.PersistableRecord {
        func encode(to container: inout GRDB.PersistenceContainer) throws {
           container[Columns.id] = id
           container[Columns.name] = name
           container[Columns.countryCode] = countryCode
        }
      }

      extension Author {
        enum Columns {
          static let id = GRDB.Column("id")
          static let name = GRDB.Column("title")
          static let countryCode = GRDB.Column("countryCode")
        }
      }

      extension Author {
        static let databaseSelection: [any GRDB.SQLSelectable] = [
          Columns.id,
          Columns.name,
          Columns.countryCode
        ]
      }

      extension Book: GRDB.FetchableRecord {
        init(row: GRDB.Row) {
           self.id = row[Columns.id]
           self.authorId = row[Columns.authorId]
           self.title = row[Columns.title]
           self.author = row[Columns.author]
        }
      }

      extension Book: GRDB.PersistableRecord {
        func encode(to container: inout GRDB.PersistenceContainer) throws {
           container[Columns.id] = id
           container[Columns.authorId] = authorId
           container[Columns.title] = title
           container[Columns.author] = author
        }
      }

      extension Book {
        enum Columns {
          static let id = GRDB.Column("id")
          static let authorId = GRDB.Column("authorId")
          static let title = GRDB.Column("title")
          static let author = GRDB.Column("author")
        }
      }

      extension Book {
        static let databaseSelection: [any GRDB.SQLSelectable] = [
          Columns.id,
          Columns.authorId,
          Columns.title,
          Columns.author
        ]
      }
      """
    }
  }
}
