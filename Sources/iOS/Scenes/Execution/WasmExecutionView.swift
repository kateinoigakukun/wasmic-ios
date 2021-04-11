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
            barButtonSystemItem: .done,
            target: self, action: #selector(dismissPresentation))
        return button
    }()
    private lazy var actionButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self, action: #selector(showActionSheet))
        return button
    }()
    private lazy var execctingView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        return indicator
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
        title = "Execution"
        navigationItem.leftBarButtonItem = doneButton
        navigationItem.rightBarButtonItem = actionButton
        executor.objectWillChange.sink { [weak self] in
            self?.view.setNeedsLayout()
        }
        .store(in: &cancellables)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let isExecuting = executor.state == .executing
        if isExecuting != execctingView.isAnimating {
            if isExecuting {
                actionButton.customView = execctingView
                execctingView.startAnimating()
            } else {
                actionButton.customView = nil
                execctingView.stopAnimating()
            }
        }
        textView.text = executor.output
    }

    override func viewDidAppear(_ animated: Bool) {
        executor.startPipeline()
    }

    @objc private func dismissPresentation() {
        self.dismissAction()
    }
    @objc private func showActionSheet() {
        let activityViewController = UIActivityViewController(
            activityItems: [
                executor.output
            ], applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
    }
}

class WasmExecutor: ObservableObject {
    enum State: Equatable {
        case executing
        case failed(String)
        case result([WebAssembly.Value])
        case wasiExit(Int)
    }

    let function: String
    let arguments: [String]
    let bytes: [UInt8]
    let runAsWASI: Bool
    private let pipelineQueue = DispatchQueue(
        label: "dev.katei.Wasmic.executor-pipeline",
        qos: .default
    )

    @Published var state: State? {
        didSet {
            switch state {
            case .executing:
                break
            case .failed(let error):
                output += "Execution Failed: \(error)"
            case .result(let results):
                output += "Execution Results: \(results)"
            case .wasiExit(let code):
                output += "Exit with \(code)"
            case .none:
                break
            }
        }
    }

    @Published var output: String = ""

    init(
        function: String,
        arguments: [String],
        bytes: [UInt8],
        runAsWASI: Bool
    ) {
        self.function = function
        self.arguments = arguments
        self.bytes = bytes
        self.runAsWASI = runAsWASI
        self.state = nil
    }

    func startPipeline() {
        guard state == nil else { return }
        pipelineQueue.async { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.state = .executing
            }
            do {
                let newState: State
                if self.runAsWASI {
                    let exitCode = try WebAssembly.startWasiApp(wasmBytes: self.bytes, args: [])
                    newState = .wasiExit(exitCode)
                } else {
                    let result =
                        try WebAssembly.execute(
                            wasmBytes: self.bytes, function: self.function, args: self.arguments)
                    newState = .result(result)
                }
                DispatchQueue.main.async {
                    self.state = newState
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
