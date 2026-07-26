import Foundation

protocol CategoryRepository {
    func fetchMainCategories() async throws -> [MainCategory]
    func fetchSubCategories(for mainCategoryID: UUID) async throws -> [SubCategory]
    func fetchAllSubCategories() async throws -> [SubCategory]

    func addMainCategory(_ category: MainCategory) async throws
    func updateMainCategory(_ category: MainCategory) async throws
    func deleteMainCategory(_ category: MainCategory) async throws

    func addSubCategory(_ category: SubCategory) async throws
    func updateSubCategory(_ category: SubCategory) async throws
    func deleteSubCategory(_ category: SubCategory) async throws
}
