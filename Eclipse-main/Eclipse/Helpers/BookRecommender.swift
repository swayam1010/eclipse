import Foundation
import CoreML

struct BookRecommender {
    
    private let model: BookRecommendationSystem // Replace with your actual model name

    init?() {
        do {
            let config = MLModelConfiguration()
            self.model = try BookRecommendationSystem(configuration: config) // Replace with actual model name
        } catch {
            print("Error loading ML model: \(error)")
            return nil
        }
    }
    
    func recommendBooks(items: [String: Double], numResults: Int64 = 5, restrict: [String]? = nil, exclude: [String]? = nil) -> [(String, Double)] {
        do {
            let input = BookRecommendationSystemInput(
                items: items,
                k: numResults,
                restrict_: restrict, // ✅ `restrict_` with underscore
                exclude: exclude // ✅ `exclude` without underscore
            )
            
            print("Model Input - Items: \(items)")
            print("Model Input - Restrict: \(restrict ?? [])")
            print("Model Input - Exclude: \(exclude ?? [])")
            
            let prediction = try model.prediction(input: input)
            
            print("Model Output - Recommendations: \(prediction.recommendations)")
            print("Model Output - Scores: \(prediction.scores)")
            
            // Combine recommendations with scores
            var results: [(String, Double)] = []
            for recommendation in prediction.recommendations {
                if let score = prediction.scores[recommendation] {
                    results.append((recommendation, score))
                }
            }
            
            return results.sorted { $0.1 > $1.1 } // Sort by highest score
        } catch {
            print("Prediction error: \(error)")
            return []
        }
    }
}


