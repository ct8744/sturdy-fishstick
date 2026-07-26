import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportView: View {
    @State private var viewModel: ImportViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showFilePicker = false
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        let billRepo = BillRepositoryImpl(modelContext: modelContext)
        let categoryRepo = CategoryRepositoryImpl(modelContext: modelContext)
        let keywordRepo = KeywordMapRepositoryImpl(modelContext: modelContext)
        let autoCategorize = AutoCategorizeUseCase(keywordRepo: keywordRepo)
        _viewModel = State(initialValue: ImportViewModel(
            billRepository: billRepo,
            categoryRepo: categoryRepo,
            autoCategorizeUseCase: autoCategorize
        ))
    }

    var body: some View {
        Group {
            switch viewModel.stage {
            case .selectSource:
                SourceSelectionView { format in
                    viewModel.selectSource(format)
                    showFilePicker = true
                }
            case .selectFile:
                ProgressView("选择文件中...")
            case .parsing:
                importingProgress
            case .mapping, .autoCategorizing:
                importingProgress
            case .manualCategorize:
                ManualCategorizeView(viewModel: viewModel)
            case .completed:
                ImportCompleteView(recordCount: viewModel.parsedRecords.count) {
                    dismiss()
                }
            case .failed(let error):
                importFailedView(error)
            }
        }
        .navigationTitle("导入账单")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.commaSeparatedText, UTType(filenameExtension: "xlsx") ?? .data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    viewModel.selectFile(url: url)
                }
            case .failure(let error):
                viewModel.stage = .failed(error.localizedDescription)
            }
        }
        .interactiveDismissDisabled(viewModel.stage != .selectSource && viewModel.stage != .completed)
    }

    private var importingProgress: some View {
        VStack(spacing: 20) {
            ProgressView(value: viewModel.importProgress)
                .progressViewStyle(.linear)
                .padding(.horizontal, 40)

            Text(importingStatus)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("取消", role: .destructive) {
                viewModel.cancelImport()
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var importingStatus: String {
        switch viewModel.stage {
        case .parsing:          return "正在解析文件..."
        case .autoCategorizing: return "正在自动分类..."
        default:                return "处理中..."
        }
    }

    private func importFailedView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("导入失败")
                .font(.title2.weight(.semibold))

            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("返回") {
                viewModel.cancelImport()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxHeight: .infinity)
    }
}
