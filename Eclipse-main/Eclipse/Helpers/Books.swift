import Foundation
import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth
import CoreData
let db = Firestore.firestore()

/// Adapter to convert Firestore data into a `BookF` model.
struct BookFAdapter {
    static func fromFirestoreData(_ data: [String: Any]) -> BookF? {
        guard let id = data["id"] as? String,
              let title = data["title"] as? String else {
            return nil
        }
        
        return BookF(
            id: id,
            title: title,
            subtitle: data["subtitle"] as? String,
            authors: data["authors"] as? [String],
            description: data["description"] as? String,
            averageRating: data["averageRating"] as? Double,
            ratingsCount: data["ratingsCount"] as? Int,
            imageLinks: extractImageLinks(from: data["imageURL"]),
            previewLink: data["previewLink"] as? String,
            pageCount: data["pageCount"] as? Int
        )
    }

    private static func extractImageLinks(from value: Any?) -> ImageLinks? {
        guard let imageURL = value as? String else {
            return nil
        }
        return ImageLinks(smallThumbnail: imageURL, thumbnail: imageURL)
    }
}

/// Downloads an image from a given URL.
/// - Parameters:
///   - url: The URL of the image.
///   - completion: A completion handler returning the downloaded `UIImage`.
func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
    URLSession.shared.dataTask(with: url) { data, _, _ in
        completion(data.flatMap { UIImage(data: $0) })
    }.resume()
}

/// Fetches the user's status lists (e.g., "Currently Reading", "Want to Read").
/// - Parameters:
///   - userID: The ID of the user.
///   - completion: A completion handler returning a `Result` with an array of `List` objects or an `Error`.
func fetchStatusLists(userID: String, completion: @escaping (Result<[List], Error>) -> Void) {
    let ref = db.collection("users").document(userID).collection("lists")
    ref.getDocuments { snapshot, error in
        if let error = error {
            completion(.failure(error))
            return
        }

        let statusLists = snapshot?.documents.compactMap { doc -> List? in
            let data = doc.data()
            return List(
                id: doc.documentID,
                title: data["title"] as? String ?? "Untitled",
                bookIDs: data["bookIDs"] as? [String] ?? [],
                isPrivate: data["isPrivate"] as? Bool ?? false,
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            )
        } ?? []
        
        completion(.success(statusLists))
    }
}

/// Fetches the user's custom book lists.
/// - Parameters:
///   - userID: The ID of the user.
///   - completion: A completion handler returning a `Result` with an array of `List` objects or an `Error`.
func fetchCustomLists(userID: String, completion: @escaping (Result<[List], Error>) -> Void) {
    let ref = db.collection("users").document(userID).collection("customLists")
    ref.getDocuments { snapshot, error in
        if let error = error {
            completion(.failure(error))
            return
        }

        let customLists = snapshot?.documents.compactMap { doc -> List? in
            let data = doc.data()
            return List(
                id: doc.documentID,
                title: data["title"] as? String ?? "Untitled",
                bookIDs: data["bookIDs"] as? [String] ?? [],
                isPrivate: data["isPrivate"] as? Bool ?? false,
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            )
        } ?? []

        completion(.success(customLists))
    }
}

/// Adds a new custom list for the user.
/// - Parameters:
///   - userID: The ID of the user.
///   - list: The `List` object to be added.
///   - completion: A completion handler returning a `Result` of success or failure.
func addCustomList(userID: String, list: List, completion: @escaping (Result<Void, Error>) -> Void) {
    let ref = db.collection("users").document(userID).collection("customLists")
    
    let newList = [
        "title": list.title,
        "bookIDs": list.bookIDs,
        "isPrivate": list.isPrivate
    ] as [String: Any]

    ref.document(list.id).setData(newList) { error in
        if let error = error {
            completion(.failure(error))
            return
        }
        completion(.success(()))
    }
}
    // Move a book from one list to another
func moveBook(_ bookID: String, from currentStatus: String, to newStatus: String, userID: String, completion: @escaping (Error?) -> Void) {
    let userListsRef = db.collection("users").document(userID).collection("lists")
    let batch = db.batch()
    
    // Remove the book from the current list
    let currentStatusRef = userListsRef.document(currentStatus)
    batch.updateData(["bookIDs": FieldValue.arrayRemove([bookID])], forDocument: currentStatusRef)
    
    // Check if the new list exists
    let newStatusRef = userListsRef.document(newStatus)
    newStatusRef.getDocument { document, error in
        if let error = error {
            completion(error)
            return
        }
        
        if let document = document, document.exists {
            // If the document exists, update it
            batch.updateData(["bookIDs": FieldValue.arrayUnion([bookID])], forDocument: newStatusRef)
        } else {
            // If the document does not exist, create it with all required fields
            let newListData: [String: Any] = [
                "bookIDs": [bookID], // Array of book IDs
                "timestamp": FieldValue.serverTimestamp(), // Current server timestamp
                "title": newStatus // Title of the list
            ]
            batch.setData(newListData, forDocument: newStatusRef)
        }
        
        // Commit the batch
        batch.commit { error in
            completion(error)
        }
    }
}

func deleteBook(_ bookID: String, userID: String, completion: @escaping (Error?) -> Void) {
    let userListsRef = db.collection("users").document(userID).collection("lists")
    
    userListsRef.getDocuments { snapshot, error in
        if let error = error {
            completion(error)
            return
        }
        
        let batch = db.batch()
        snapshot?.documents.forEach { document in
            let docRef = userListsRef.document(document.documentID)
            batch.updateData(["bookIDs": FieldValue.arrayRemove([bookID])], forDocument: docRef)
        }
        
        batch.commit { error in
            completion(error)
        }
    }
}
    
func getCurrentStatus(for bookID: String, userID: String, completion: @escaping (String) -> Void) {
    let userStatusListsRef = db.collection("users").document(userID).collection("lists")

    userStatusListsRef.getDocuments { snapshot, error in
        if let error = error {
            print("Error fetching status lists: \(error.localizedDescription)")
            completion("Currently Reading")
            return
        }

        for document in snapshot!.documents {
            if let books = document["bookIDs"] as? [String], books.contains(bookID) {
                completion(document.documentID)
                return
            }
        }

        completion("Currently Reading")
    }
}

/// Fetches book details from Firestore.
/// - Parameters:
///   - bookID: The ID of the book.
///   - completion: A completion handler returning a `BookF` object or `nil` if not found.
func fetchBookDetails(bookID: String, completion: @escaping (BookF?) -> Void) {
    let ref = db.collection("books").document(bookID)
    ref.getDocument { snapshot, error in
        if let error = error {
            print("Error fetching book details: \(error.localizedDescription)")
            completion(nil)
            return
        }
        guard let data = snapshot?.data() else {
            completion(nil)
            return
        }
        completion(BookFAdapter.fromFirestoreData(data))
    }
}

func fetchBookIds(from collection: String, userID: String, completion: @escaping (Result<Set<String>, Error>) -> Void) {
       db.collection("users").document(userID).collection(collection).getDocuments { snapshot, error in
           if let error = error {
               print("Error fetching \(collection): \(error.localizedDescription)")
               completion(.failure(error))
               return
           }
           
           let bookIds = snapshot?.documents.compactMap { document -> [String]? in
               document.data()["bookIDs"] as? [String]
           }.flatMap { $0 } ?? []
           
           completion(.success(Set(bookIds)))
       }
   }

func fetchAllBookIds(userID: String, completion: @escaping (Result<Set<String>, Error>) -> Void) {
       let group = DispatchGroup()
       var allBookIds = Set<String>()

       group.enter()
       fetchBookIds(from: "lists", userID: userID) { result in
           defer { group.leave() }
           if case .success(let ids) = result {
               allBookIds.formUnion(ids)
           }
       }

       group.enter()
       fetchBookIds(from: "customLists", userID: userID) { result in
           defer { group.leave() }
           if case .success(let ids) = result {
               allBookIds.formUnion(ids)
           }
       }

       group.notify(queue: .main) {
           completion(.success(allBookIds))
       }
   }

/// Fetches details of a renter.
/// - Parameters:
///   - renterID: The ID of the renter.
///   - completion: A completion handler returning the renter's name or `nil` if not found.
func fetchRenterDetails(renterID: String, completion: @escaping (String?, [String: Double]?) -> Void) {
    db.collection("renters").document(renterID).getDocument { (document, error) in
        if let error = error {
            completion(nil, nil)
            return
        }
        
        guard let document = document, document.exists else {
            completion(nil, nil)
            return
        }
        
        guard let data = document.data() else {
            completion(nil, nil)
            return
        }
        
        // Fetch renter's name
        let name = data["name"] as? String
        
        // Fetch renter's rating dictionary (bookQuality, communication, overallExperience)
        if let renterRating = data["renterRating"] as? [String: Double] {
            // Pass the renter's name and the entire rating dictionary
            completion(name, renterRating)
        } else {
            // If rating doesn't exist, pass nil for the rating
            completion(name, nil)
        }
    }
}



/// Fetches the list of books rented by a renter.
/// - Parameters:
///   - renterID: The ID of the renter.
///   - completion: A completion handler returning an array of `BookF` objects.
func fetchRentedBooks(renterID: String, completion: @escaping ([RentersBook]) -> Void) {
    let db = Firestore.firestore()
    
    db.collection("renters").document(renterID).getDocument { (document, error) in
        if let error = error {
            print("Error fetching rented books: \(error.localizedDescription)")
            completion([])
            return
        }
        
        guard let document = document, document.exists, let data = document.data() else {
            print("No valid data found for renter")
            completion([])
            return
        }
        
        if let rentedBooksData = data["rentedBooks"] as? [[String: Any]] {
            let books = rentedBooksData.compactMap { bookData -> RentersBook? in
                guard let title = bookData["title"] as? String,
                      let authors = bookData["authors"] as? [String],
                      let description = bookData["description"] as? String,
                      let price = bookData["price"] as? Double,
                      let imageURL = bookData["imageURL"] as? String,
                      let id = bookData["id"] as? String,
                      let timestamp = bookData["addedAt"] as? Timestamp else {
                    return nil
                }
                
                return RentersBook(
                    title: title,
                    authors: authors,
                    description: description,
                    price: price,
                    imageURL: imageURL,
                    id: id,
                    addedAt: timestamp.dateValue()
                )
            }
            completion(books)
        } else {
            print("No rentedBooks field in renter document")
            completion([])
        }
    }
}

func fetchRenters(completion: @escaping (Result<[Renter], Error>) -> Void) {
    db.collection("renters").getDocuments { snapshot, error in
        if let error = error {
            completion(.failure(error))
            return
        }

        guard let documents = snapshot?.documents else {
            let error = NSError(domain: "FirestoreError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No renters found."])
            completion(.failure(error))
            return
        }

        var renters: [Renter] = []

        for document in documents {
            let data = document.data()

            guard let name = data["name"] as? String else {
                continue
            }

            // Handling rentedBooks as an array of book objects
            var rentedBooks: [RentersBook] = []

            if let rentedBooksArray = data["rentedBooks"] as? [[String: Any]] {
                for bookData in rentedBooksArray {
                    let book = createRentersBook(from: bookData)
                    rentedBooks.append(book)
                }
            } else {
                print("DEBUG: rentedBooks field is missing or invalid in document \(document.documentID)")
            }

            // Extract renter rating if available
            var renterRating: Rating? = nil
            if let renterRatingData = data["rating"] as? [String: Double] {
                renterRating = Rating.fromDictionary(renterRatingData)
            }

            let renter = Renter(id: document.documentID, name: name, books: rentedBooks, rating: renterRating)
            renters.append(renter)
        }
        completion(.success(renters))
    }
}

// Helper function to create a RentersBook from Firestore data
private func createRentersBook(from bookData: [String: Any]) -> RentersBook {
    let title = bookData["title"] as? String ?? "Unknown Title"
    let authors = bookData["authors"] as? [String] ?? ["Unknown Author"]
    let description = bookData["description"] as? String ?? "No description available"
    let price = bookData["price"] as? Double ?? 0.0
    let imageURL = bookData["imageURL"] as? String ?? ""
    let id = bookData["id"] as? String ?? UUID().uuidString
    let addedAtString = bookData["addedAt"] as? String ?? ""
    let addedAt = ISO8601DateFormatter().date(from: addedAtString) ?? Date()

    return RentersBook(
        title: title,
        authors: authors,
        description: description,
        price: price,
        imageURL: imageURL,
        id: id,
        addedAt: addedAt
    )
}

/// Fetch Currently Rented Books from Firestore

func fetchCurrentlyRentedBooks(for userID: String, completion: @escaping (Result<[RentersBook], Error>) -> Void) {
    let borrowedBooksRef = db.collection("users").document(userID).collection("borrowedBooks")

    borrowedBooksRef.getDocuments { snapshot, error in
        if let error = error {
            print("Error fetching rented books: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }

        guard let documents = snapshot?.documents, !documents.isEmpty else {
            completion(.failure(NSError(domain: "FirestoreError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No rented books found."])))
            return
        }

        var books: [RentersBook] = []

        for document in documents {
            let data = document.data()

            if let bookArray = data["books"] as? [[String: Any]] { // Extract book array
                for var bookDict in bookArray {
                    // Convert Firestore Timestamp to a format that can be serialized
                    if let timestamp = bookDict["addedAt"] as? Timestamp {
                        bookDict["addedAt"] = timestamp.dateValue().timeIntervalSince1970
                    }
                    
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: bookDict)
                        let decodedBook = try JSONDecoder().decode(RentersBook.self, from: jsonData)
                        books.append(decodedBook)
                    } catch {
                        print("Error decoding RentersBook: \(error)")
                    }
                }
            }
        }
        completion(.success(books))
    }
}

    // Fetch Suggested Books from Firestore
    func fetchSuggestedBooks(completion: @escaping (Result<[String], Error>) -> Void) {
        db.collection("books").limit(to: 5).getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let documents = snapshot?.documents else {
                completion(.failure(NSError(domain: "FirestoreError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No suggested books found."])))
                return
            }

            let bookIDs = documents.compactMap { $0.data()["googleBooksId"] as? String }
            completion(.success(bookIDs))
        }
    }

func updateRenterRating(_ rating: Rating, renterID: String) {
    // Assuming the renter ratings are stored in a collection called "renters" in Firestore
    let renterRef = db.collection("renters").document(renterID)
    
    // Create the rating data using the Rating struct
    let ratingData: [String: Any] = [
        "bookQuality": rating.bookQuality,         // Use the bookQuality from the Rating struct
        "communication": rating.communication,     // Use the communication from the Rating struct
        "overallExperience": rating.overallExperience // Use the overallExperience from the Rating struct
    ]
    
    // Update the renter document with the new rating data
    renterRef.updateData(ratingData) { error in
        if let error = error {
            print("Error updating renter rating: \(error.localizedDescription)")
        } else {
            print("Renter rating updated successfully")
        }
    }
}

func fetchRecommendedLists(completion: @escaping ([RecommendedList], Error?) -> Void) {
    print("🔍 fetchRecommendedLists called")
    let db = Firestore.firestore()
    
    guard let userID = Auth.auth().currentUser?.uid else {
        print("👤 User is not logged in, fetching curated lists...")
        db.collection("curatedLists")
            .order(by: "title")
            .limit(to: 5)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching curated lists: \(error.localizedDescription)")
                    completion([], error)
                    return
                }
                print("📄 Firestore query for curated lists completed")
                
                let recommendedLists = snapshot?.documents.compactMap { document -> RecommendedList? in
                    let data = document.data()
                    guard let title = data["title"] as? String,
                          let subtitle = data["subtitle"] as? String,
                          let bookIDs = data["bookIds"] as? [String],
                          let tags = data["tags"] as? [String] else {
                        print("⚠️ Skipping document due to missing fields: \(data)")
                        return nil
                    }
                    return RecommendedList(title: title, subtitle: subtitle, books: bookIDs, tags: tags)
                } ?? []
                
                print("✅ Successfully fetched \(recommendedLists.count) curated lists for non-logged-in user.")
                completion(recommendedLists, nil)
            }
        return
    }

    print("👤 User is logged in, fetching genre preferences...")
    let userRef = db.collection("users").document(userID).collection("userData").document("details")
    userRef.getDocument { userSnapshot, error in
        if let error = error {
            print("❌ Error fetching user preferences: \(error.localizedDescription)")
            completion([], error)
            return
        }
        print("📄 Firestore query for user preferences completed")
        
        guard let userData = userSnapshot?.data(),
              let preferredGenres = userData["genrePreferences"] as? [String] else {
            print("⚠️ No genre preferences found for user.")
            completion([], nil)
            return
        }
        
        let lowercaseGenres = preferredGenres.map { $0.lowercased() }
        
        db.collection("curatedLists").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error fetching curated lists: \(error.localizedDescription)")
                completion([], error)
                return
            }
            print("📄 Firestore query for curated lists completed")
            
            let recommendedLists = snapshot?.documents.compactMap { document -> RecommendedList? in
                let data = document.data()
                
                guard let title = data["title"] as? String,
                      let subtitle = data["subtitle"] as? String,
                      let bookIDs = data["bookIds"] as? [String],
                      let tags = data["tags"] as? [String] else {
                    print("⚠️ Skipping document due to missing fields: \(data)")
                    return nil
                }
                
                let listTagsLower = tags.map { $0.lowercased() }
                if listTagsLower.contains(where: lowercaseGenres.contains) {
                    return RecommendedList(title: title, subtitle: subtitle, books: bookIDs, tags: tags)
                } else {
                    return nil
                }
            } ?? []
            
            print("✅ Successfully fetched \(recommendedLists.count) curated lists for user with preferred genres: \(preferredGenres).")
            completion(recommendedLists, nil)
        }
    }
}

/// Caching books from Google Books API

// MARK: - 1. Search for Books (Cache or API)

func searchBooks(query: String, completion: @escaping (Result<[BookF], Error>) -> Void) {
    // Check if books are available in Core Data cache
    if let cachedBooks = CoreDataManager.shared.fetchBooks(for: query), !cachedBooks.isEmpty {
        completion(.success(cachedBooks))
        return
    }

    // Encode the query and construct the API URL
    guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
          let url = URL(string: "https://www.googleapis.com/books/v1/volumes?q=\(encodedQuery)&key=\(apiKey)") else {
        completion(.failure(NSError(domain: "com.app.invalidURL", code: 400, userInfo: nil)))
        return
    }

    // Fetch data from API
    URLSession.shared.dataTask(with: url) { data, _, error in
        if let error = error {
            completion(.failure(error))
            return
        }

        guard let data = data else {
            completion(.failure(NSError(domain: "com.app.noData", code: 404, userInfo: nil)))
            return
        }

        do {
            // Decode the API response
            let response = try JSONDecoder().decode(BookResponse.self, from: data)
            
            // Map BookItem to BookF using the adapter
            let books = response.items?.compactMap { BookAdapter.adapt($0) } ?? []
            
            DispatchQueue.main.async {
                // Save fetched books to Core Data for future caching
                CoreDataManager.shared.saveBooks(books, for: query)
                completion(.success(books))
            }
        } catch {
            completion(.failure(error))
        }
    }.resume()
}

// MARK: - Fetch Books by Subject
func fetchBooks(query: String, completion: @escaping (Result<[BookF], Error>) -> Void) {
    // Check if books are available in Core Data cache
    if let cachedBooks = CoreDataManager.shared.fetchBooks(for: query), !cachedBooks.isEmpty {
        completion(.success(cachedBooks))
        return
    }

    // Encode the query and construct the API URL
    guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
          let url = URL(string: "https://www.googleapis.com/books/v1/volumes?q=subject:\(encodedQuery)&key=\(apiKey)") else {
        completion(.failure(NSError(domain: "com.app.invalidURL", code: 400, userInfo: nil)))
        return
    }

    // Fetch data from API
    URLSession.shared.dataTask(with: url) { data, _, error in
        if let error = error {
            completion(.failure(error))
            return
        }

        guard let data = data else {
            completion(.failure(NSError(domain: "com.app.noData", code: 404, userInfo: nil)))
            return
        }

        do {
            // Decode the API response
            let response = try JSONDecoder().decode(BookResponse.self, from: data)
            
            // Map BookItem to BookF using the adapter
            let books = response.items?.compactMap { BookAdapter.adapt($0) } ?? []
            
            DispatchQueue.main.async {
                // Save fetched books to Core Data for future caching
                CoreDataManager.shared.saveBooks(books, for: query)
                completion(.success(books))
            }
        } catch {
            completion(.failure(error))
        }
    }.resume()
}


// MARK: - Fetch Single Book by ID

func fetchBooksByIDs(bookIDs: [String], completion: @escaping (Result<[BookF], Error>) -> Void) {
    print("📢 Fetching books for IDs: \(bookIDs)")

    var fetchedBooks: [BookF] = []
    var missingBookIDs: [String] = []

    // Check Core Data for cached books
    for bookID in bookIDs {
        if let cachedBook = CoreDataManager.shared.fetchBookByID(bookID) {
            print("✅ Found book in Core Data: \(cachedBook.title)")
            fetchedBooks.append(cachedBook)
        } else {
            print("❌ Book not found in Core Data: \(bookID), marking for API fetch")
            missingBookIDs.append(bookID)
        }
    }

    // If all books are found in Core Data, return immediately
    if missingBookIDs.isEmpty {
        DispatchQueue.main.async {
            completion(.success(fetchedBooks))
        }
        return
    }

    let dispatchGroup = DispatchGroup()

    for bookID in missingBookIDs {
        dispatchGroup.enter()

        guard let url = URL(string: "https://www.googleapis.com/books/v1/volumes/\(bookID)?key=\(apiKey)") else {
            dispatchGroup.leave()
            continue
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            defer { dispatchGroup.leave() }

            if let error = error {
                return
            }

            guard let data = data else {
                print("❌ No data received from API for book \(bookID)")
                return
            }

            do {
                let apiResponse = try JSONDecoder().decode(GoogleBooksAPIResponse.self, from: data)

                let bookF = BookF(
                    id: apiResponse.id,
                    title: apiResponse.volumeInfo.title,
                    subtitle: apiResponse.volumeInfo.subtitle,
                    authors: apiResponse.volumeInfo.authors,
                    description: apiResponse.volumeInfo.description,
                    averageRating: apiResponse.volumeInfo.averageRating,
                    ratingsCount: apiResponse.volumeInfo.ratingsCount ?? 0,
                    imageLinks: ImageLinks(
                        smallThumbnail: apiResponse.volumeInfo.imageLinks?.smallThumbnail ?? "",
                        thumbnail: apiResponse.volumeInfo.imageLinks?.thumbnail ?? ""
                    ),
                    previewLink: apiResponse.volumeInfo.previewLink,
                    pageCount: apiResponse.volumeInfo.pageCount ?? 0
                )

                print("💾 Saving book to Core Data: \(bookF.id)")
                CoreDataManager.shared.saveBook(bookF, for: "singleBook")

                fetchedBooks.append(bookF)
            } catch {
                print("❌ JSON Decoding Error for book \(bookID): \(error.localizedDescription)")
            }
        }.resume()
    }

    dispatchGroup.notify(queue: .main) {
        completion(.success(fetchedBooks))
    }
}
