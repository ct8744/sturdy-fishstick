import SwiftUI
import SwiftData

struct ExportView: View {
    @State private var exportState: ExportState = .idle
    @State private var exportedURL: URL?
    @State private var showShareSheet = false
    private let modelContext: ModelContext

    enum ExportState {
        case idle
        case exporting
        case success(URL)
        case failed(String)
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    var body: some View {
        List {
            Section("导出范围") {
                Button(action: { Task { await exportAll() } }) {
                    HStack {
                        Image(systemName: "tray.full")
                            .foregroundStyle(.accent)
                        VStack(alignment: .leading) {
                            Text("导出全部")
                            Text("所有账单记录")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if case .exporting = exportState {
                            ProgressView()
                        }
                    }
                }
                .disabled(exporting)

                Button(action: { Task { await exportThisMonth() } }) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundStyle(.accent)
                        VStack(alignment: .leading) {
                            Text("导出本月")
                            Text(Date(), format: .dateTime.year().month())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if case .exporting = exportState {
                            ProgressView()
                        }
                    }
                }
                .disabled(exporting)
            }

            if case .success(let url) = exportState {
                Section {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundStyle(.green)
                        VStack(alignment: .leading) {
                            Text("导出成功")
                            Text(url.lastPathComponent)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        ShareLink(item: url) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }

            if case .failed(let error) = exportState {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.subheadline)
                    }
                }
            }
        }
        .navigationTitle("导出")
    }

    private var exporting: Bool {
        if case .exporting = exportState { return true }
        return false
    }

    private func exportAll() async {
        exportState = .exporting
        let billRepo = BillRepositoryImpl(modelContext: modelContext)
        let exportService = CSVExportService()
        let useCase = ExportUseCase(exportService: exportService, billRepository: billRepo)

        do {
            let url = try await useCase.exportAll()
            exportState = .success(url)
        } catch {
            exportState = .failed(error.localizedDescription)
        }
    }

    private func exportThisMonth() async {
        exportState = .exporting
        let billRepo = BillRepositoryImpl(modelContext: modelContext)
        let exportService = CSVExportService()
        let useCase = ExportUseCase(exportService: exportService, billRepository: billRepo)

        let now = Date()
        let year = Calendar.current.component(.year, from: now)
        let month = Calendar.current.component(.month, from: now)

        do {
            let url = try await useCase.exportMonth(year: year, month: month)
            exportState = .success(url)
        } catch {
            exportState = .failed(error.localizedDescription)
        }
    }
}
