import Foundation

public final class ImageCommentsMapper {
    private struct Root: Decodable {
        private let items: [Item]
        
        private struct Item: Decodable{
            let id: UUID
            let message: String
            let created_at: Date
            let author: Author
        }
        
        private struct Author: Decodable {
            let username: String
        }
        
        var comments: [ImageComment] {
            items.map { item in
                ImageComment(id: item.id, message: item.message, createdAt: item.created_at, username: item.author.username)
            }
        }
    }

    
    public static func map(_ data: Data, from response: HTTPURLResponse) throws -> [ImageComment] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        guard isOk(response),
              let root = try? decoder.decode(Root.self, from: data)
        else {
            throw RemoteImageCommentsLoader.Error.invalidData
        }

        return root.comments
    }
    
    private static func isOk(_ response: HTTPURLResponse) -> Bool {
        (200...299).contains(response.statusCode)
    }
}
