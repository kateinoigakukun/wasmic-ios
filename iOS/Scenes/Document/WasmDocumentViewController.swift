
//
//  WasmDocumentViewController.swift
//  Wasmic
//
//  Created by kateinoigakukun on 2021/04/09.
//

import UIKit
import os.log

/// - Tag: textDocumentViewController
class TextDocumentViewController: UIViewController, UITextViewDelegate, TextDocumentDelegate {

    private(set) lazy var textView: UITextView = {
        let textView = UITextView()
        textView.isScrollEnabled = true
        textView.bounces = true
        textView.alwaysBounceVertical = true
        textView.keyboardDismissMode = .interactive
        if #available(iOS 13.0, *) {
            textView.usesStandardTextScaling = true
        }
        let font = UIFont(name: "Menlo-Regular", size: 14)!
        textView.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: font)
        textView.adjustsFontForContentSizeCategory = true
        return textView
    }()
    private lazy var progressBar: UIProgressView = {
        let view = UIProgressView(progressViewStyle: .default)
        return view
    }()
    private lazy var doneButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self, action: #selector(returnToDocuments(_:)))
        return button
    }()

    private var keyboardObserver: KeyboardLayoutObserver?
    
    private let document: TextDocument

    init(document: TextDocument) {
        self.document = document
        super.init(nibName: nil, bundle: nil)
        self.document.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        keyboardObserver = KeyboardLayoutObserver(for: view, onUpdateHandler: adjustForKeyboard(keyboardInset:animator:))
        view.backgroundColor = .white
        navigationItem.leftBarButtonItem = doneButton
        view.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            textView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        view.addSubview(progressBar)
        progressBar.isHidden = true
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressBar.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 4),
            view.rightAnchor.constraint(equalTo: progressBar.rightAnchor, constant: 4),
            progressBar.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        textView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
                
        assert(!document.documentState.contains(.closed), "*** Open the document before displaying it. ***")
        
        assert(!document.documentState.contains(.inConflict), "*** Resolve conflicts before displaying the document. ***")

        textView.text = document.text
        
        // Set the view controller's title to match file document's title.
        let fileAttributes = try? document.fileURL.resourceValues(forKeys: [URLResourceKey.localizedNameKey])
        navigationItem.title = fileAttributes?.localizedName
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        document.close { (success) in
            guard success else { fatalError( "*** Error closing document ***") }
            
            os_log("==> Document saved and closed", log: .default, type: .debug)
        }
    }
    
    // MARK: - Action Methods
    
    @objc func returnToDocuments(_ sender: Any) {
        // Dismiss this view controller.
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UITextViewDelegate

    func textViewDidChange(_ textView: UITextView) {
        document.text = textView.text
        document.updateChangeCount(.done)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        document.text = textView.text
        document.updateChangeCount(.done)
    }
    
    // MARK: - UITextDocumentDelegate Methods
    
    func textDocumentEnableEditing(_ doc: TextDocument) {
        textView.isEditable = true
    }
    
    func textDocumentDisableEditing(_ doc: TextDocument) {
        textView.isEditable = false
    }
    
    func textDocumentUpdateContent(_ doc: TextDocument) {
        textView.text = doc.text
    }
    
    func textDocumentTransferBegan(_ doc: TextDocument) {
        progressBar.isHidden = false
        progressBar.observedProgress = doc.progress
    }
    
    func textDocumentTransferEnded(_ doc: TextDocument) {
        progressBar.isHidden = true
    }
    
    func textDocumentSaveFailed(_ doc: TextDocument) {
        let alert = UIAlertController(
            title: NSLocalizedString("SaveErrorTitle", comment: ""),
            message: NSLocalizedString("SaveErrorTitleMessage", comment: ""),
            preferredStyle: .alert)
        
        let dismiss = UIAlertAction(title: NSLocalizedString("OKTitle", comment: ""), style: .default)
        alert.addAction(dismiss)
        
        present(alert, animated: true, completion: nil)
    }

    func adjustForKeyboard(keyboardInset: UIEdgeInsets, animator: UIViewPropertyAnimator) {
        animator.addAnimations {
            self.textView.contentInset = keyboardInset
            self.textView.scrollIndicatorInsets = keyboardInset
        }
        animator.startAnimation()
    }
}
