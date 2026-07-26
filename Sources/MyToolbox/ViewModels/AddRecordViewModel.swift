import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
class AddRecordViewModel {
    var amount: String = ""
    var type: TransactionType = .expense
    var selectedMainCategory: MainCategory?
    var selectedSubCategory: SubCategory?
    var selectedIncomeCategory: IncomeCategory?
    var availableSubCategories: [SubCategory] = []
    var tag: String = ""
    var transactionTime: Date = Date()

    var isSaving: Bool = false
    var saveError: String?
    var didSaveSuccessfully: Bool = false

    var mainCategories: [MainCategory] = []

    var isFormValid: Bool {
        guard !amount.isEmpty, (Decimal(string: amount) ?? 0) > 0 else { return false }
        switch type {
        case .expense:
            return selectedSubCategory != nil
        case .income:
            return selectedIncomeCategory != nil
        }
    }

    private let billRepository: BillRepository
    private let categoryRepo: CategoryRepository

    init(billRepository: BillRepository, categoryRepo: CategoryRepository) {
        self.billRepository = billRepository
        self.categoryRepo = categoryRepo
    }

    func onAppear() async {
        mainCategories = (try? await categoryRepo.fetchMainCategories()) ?? []
        if let first = mainCategories.first {
            selectMainCategory(first)
        }
        selectedIncomeCategory = IncomeCategory.salary
    }

    func selectMainCategory(_ category: MainCategory) {
        selectedMainCategory = category
        selectedSubCategory = nil
        Task {
            availableSubCategories = (try? await categoryRepo.fetchSubCategories(for: category.id)) ?? []
            selectedSubCategory = availableSubCategories.first
        }
    }

    func selectSubCategory(_ category: SubCategory) {
        selectedSubCategory = category
    }

    func save() async {
        guard isFormValid else { return }

        isSaving = true
        saveError = nil

        defer { isSaving = false }

        guard let amountValue = Decimal(string: amount) else {
            saveError = "金额格式不正确"
            return
        }

        let record = BillRecord(
            transactionTime: transactionTime,
            type: type,
            amount: amountValue,
            mainCategoryID: type == .expense ? selectedMainCategory?.id : nil,
            subCategoryID: type == .expense ? selectedSubCategory?.id : nil,
            incomeCategory: type == .income ? selectedIncomeCategory?.rawValue : nil,
            tag: tag
        )

        do {
            try await billRepository.add(record)
            didSaveSuccessfully = true
        } catch {
            saveError = "保存失败：\(error.localizedDescription)"
        }
    }
}
