import CoreData
import UIKit

class CoreDataManager {
    static let shared = CoreDataManager()

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "CachedBook") // Match your .xcdatamodeld filename
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("❌ Failed to load Core Data: \(error)")
            }
        }
        return container
    }()

    private var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // MARK: - Save or Update Multiple Books
    func saveBooks(_ books: [BookF], for query: String) {
        context.performAndWait {
            for book in books {
                if let existingBook = fetchCachedBookByID(book.id) {
                    print("🔄 Updating existing book in Core Data: \(book.id)")
                    updateCachedBook(existingBook, with: book, query: query)
                } else {
                    print("🆕 Saving new book to Core Data: \(book.id)")
                    let cachedBook = CachedBook(context: context)
                    setCachedBookData(cachedBook, with: book, query: query)
                }
            }
            saveContext()
        }
    }
    
    func saveBook(_ book: BookF, for query: String) {
         context.performAndWait {
             if let existingBook = fetchCachedBookByID(book.id) {
                 print("🔄 Updating existing book in Core Data: \(book.id)")
                 updateCachedBook(existingBook, with: book, query: query)
             } else {
                 print("🆕 Saving new book to Core Data: \(book.id)")
                 let cachedBook = CachedBook(context: context)
                 setCachedBookData(cachedBook, with: book, query: query)
             }
             saveContext()
         }
     }

    // MARK: - Fetch Books by Query
    func fetchBooks(for query: String) -> [BookF]? {
        let request: NSFetchRequest<CachedBook> = CachedBook.fetchRequest()
        request.predicate = NSPredicate(format: "query == %@", query.lowercased())

        do {
            let results = try context.fetch(request)
            print("🔎 Fetched \(results.count) books for query: \(query)")
            return results.map { $0.toBookF() }
        } catch {
            print("❌ Error fetching books for query \(query): \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Fetch Single Book by ID
    func fetchBookByID(_ bookID: String) -> BookF? {
        guard let cachedBook = fetchCachedBookByID(bookID) else {
            print("🚨 No book found in Core Data for ID: \(bookID)")
            return nil
        }
        return cachedBook.toBookF()
    }

    // MARK: - Fetch Cached Book by ID (Core Data)
    private func fetchCachedBookByID(_ bookID: String) -> CachedBook? {
        let request: NSFetchRequest<CachedBook> = CachedBook.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", bookID)

        do {
            let results = try context.fetch(request)
            print("🔎 Fetched \(results.count) books for ID: \(bookID)")
            return results.first
        } catch {
            print("❌ Error fetching book by ID \(bookID): \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Helper Method: Update Existing CachedBook
    private func updateCachedBook(_ cachedBook: CachedBook, with book: BookF, query: String) {
        setCachedBookData(cachedBook, with: book, query: query)
    }

    // MARK: - Helper Method: Set CachedBook Data
    private func setCachedBookData(_ cachedBook: CachedBook, with book: BookF, query: String) {
        cachedBook.id = book.id
        cachedBook.title = book.title
        cachedBook.subtitle = book.subtitle
        cachedBook.authors = book.authors?.joined(separator: ", ")
        cachedBook.bookDescription = book.description
        cachedBook.averageRating = book.averageRating ?? 0
        cachedBook.ratingsCount = Int64(book.ratingsCount ?? 0)
        cachedBook.imageURL = book.imageLinks?.thumbnail
        cachedBook.previewLink = book.previewLink
        cachedBook.pageCount = Int64(book.pageCount ?? 0)
        cachedBook.query = query.lowercased()
    }

    // MARK: - Save Context
    private func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
                print("✅ Core Data saved successfully!")
            } catch {
                print("❌ Failed to save Core Data: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Debug: Print Database Location
    func printDatabaseLocation() {
        if let storeURL = persistentContainer.persistentStoreCoordinator.persistentStores.first?.url {
            print("📂 Core Data SQLite file location: \(storeURL)")
        }
    }
}

// MARK: - CachedBook to BookF Conversion
extension CachedBook {
    func toBookF() -> BookF {
        return BookF(
            id: self.id ?? "",
            title: self.title ?? "Unknown",
            subtitle: self.subtitle,
            authors: self.authors?.components(separatedBy: ", "),
            description: self.bookDescription,
            averageRating: self.averageRating,
            ratingsCount: Int(self.ratingsCount),
            imageLinks: ImageLinks(smallThumbnail: self.imageURL ?? "", thumbnail: self.imageURL ?? ""),
            previewLink: self.previewLink,
            pageCount: Int(self.pageCount)
        )
    }
}

