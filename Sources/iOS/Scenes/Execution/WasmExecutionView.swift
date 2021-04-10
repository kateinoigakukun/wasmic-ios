//
//  WasmExecutionView.swift
//  Wasmic
//
//  Created by kateinoigakukun on 2021/04/09.
//

import Combine
import SwiftUI
import WasmicWasm

struct WasmExecutionView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UINavigationController
    let executor: WasmExecutor
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIViewControllerType {
        let vc = WasmExecutionViewController(executor: executor) {
            presentationMode.wrappedValue.dismiss()
        }
        let nav = UINavigationController(rootViewController: vc)
        return nav
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}

class WasmExecutionViewController: UIViewController {
    let executor: WasmExecutor
    lazy var textView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .black
        textView.isScrollEnabled = true
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = UIFontMetrics(forTextStyle: .body)
            .scaledFont(for: Brand.codeFont)
        textView.adjustsFontForContentSizeCategory = true
        textView.textColor = .white
        return textView
    }()
    private lazy var doneButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self, action: #selector(dismissPresentation))
        return button
    }()
    let dismissAction: () -> Void
    var cancellables: [AnyCancellable] = []

    init(executor: WasmExecutor, dismissAction: @escaping () -> Void) {
        self.executor = executor
        self.dismissAction = dismissAction
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = textView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = doneButton
        executor.objectWillChange.sink { [weak self] in
            self?.view.setNeedsLayout()
        }
        .store(in: &cancellables)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        textView.text = executor.output
    }

    override func viewDidAppear(_ animated: Bool) {
        executor.startPipeline()
    }

    @objc private func dismissPresentation() {
        self.dismissAction()
    }
}

class WasmExecutor: ObservableObject {
    enum State {
        case executing
        case failed(String)
        case result([WebAssembly.Value])
    }

    let function: String
    let arguments: [String]
    let bytes: [UInt8]
    private let pipelineQueue = DispatchQueue(
        label: "dev.katei.Wasmic.executor-pipeline",
        qos: .default
    )

    var state: State? {
        didSet {
            switch state {
            case .executing:
                output += "Executing..."
            case .failed(let error):
                output += "Execution Failed: \(error)"
            case .result(let results):
                output += "Execution Results: \(results)"
            case .none:
                break
            }
        }
    }
    @Published var output: String = ""

    init(
        function: String,
        arguments: [String],
        bytes: [UInt8]
    ) {
        self.function = function
        self.arguments = arguments
        self.bytes = bytes
        self.state = nil
    }

    func startPipeline() {
        guard state == nil else { return }
        pipelineQueue.async { [weak self] in
            guard let self = self else { return }
            do {
                let args = self.arguments.map { $0.copyCString() }
                defer { args.forEach { $0.deallocate() } }
                let result =
                    try WebAssembly.execute(
                        wasmBytes: self.bytes, function: self.function, args: args)
                DispatchQueue.main.async {
                    self.state = .result(result)
                }
            } catch {
                DispatchQueue.main.async {
                    // FIXME
                    self.state = .failed(String(describing: error))
                }
            }
        }
    }
}

extension String {
    fileprivate func copyCString() -> UnsafePointer<CChar> {
        let cString = utf8CString
        let cStringCopy = UnsafeMutableBufferPointer<CChar>
            .allocate(capacity: cString.count)
        _ = cStringCopy.initialize(from: cString)
        return UnsafePointer(cStringCopy.baseAddress!)
    }
}
