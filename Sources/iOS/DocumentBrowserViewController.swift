//
//  DocumentBrowserViewController.swift
//  Wasmic
//
//  Created by kateinoigakukun on 2021/04/09.
//

import UIKit
import os.log
import WasmicWasm

/// - Tag: DocumentBrowserViewController
class DocumentBrowserViewController: UIDocumentBrowserViewController,
    UIDocumentBrowserViewControllerDelegate
{

    /// - Tag: viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self

        allowsDocumentCreation = true
        allowsPickingMultipleItems = false
    }

    // MARK: - UIDocumentBrowserViewControllerDelegate

    // Create a new document.
    func documentBrowser(
        _ controller: UIDocumentBrowserViewController,
        didRequestDocumentCreationWithHandler importHandler: @escaping (
            URL?, UIDocumentBrowserViewController.ImportMode
        ) -> Void
    ) {

        os_log("==> Creating A New Document.", log: .default, type: .debug)

        let doc = WatDocument()
        let url = doc.fileURL

        // Create a new document in a temporary location.
        doc.save(to: url, for: .forCreating) { (saveSuccess) in

            // Make sure the document saved successfully.
            guard saveSuccess else {
                os_log("*** Unable to create a new document. ***", log: .default, type: .error)

                // Cancel document creation.
                importHandler(nil, .none)
                return
            }

            // Close the document.
            doc.close(completionHandler: { (closeSuccess) in

                // Make sure the document closed successfully.
                guard closeSuccess else {
                    os_log("*** Unable to create a new document. ***", log: .default, type: .error)

                    // Cancel document creation.
                    importHandler(nil, .none)
                    return
                }

                // Pass the document's temporary URL to the import handler.
                importHandler(url, .move)
            })
        }
    }

    // Import a document.
    func documentBrowser(
        _ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL,
        toDestinationURL destinationURL: URL
    ) {
        os_log(
            "==> Imported A Document from %@ to %@.",
            log: .default,
            type: .debug,
            sourceURL.path,
            destinationURL.path)

        presentTextDocument(at: destinationURL)
    }

    func documentBrowser(
        _ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL,
        error: Error?
    ) {
        let prefixDescription = NSLocalizedString("alert.ok.import-error.description", comment: "")
        let description: String
        if let error = error {
            description = error.localizedDescription
        } else {
            description = NSLocalizedString("alert.ok.import-error.no-description", comment: "")
        }
        reportError(title: NSLocalizedString("alert.import-error.title", comment: ""),
                    message: String(format: "%@ %@", prefixDescription, description))
    }

    // UIDocumentBrowserViewController is telling us to open a selected a document.
    func documentBrowser(
        _ controller: UIDocumentBrowserViewController, didPickDocumentsAt documentURLs: [URL]
    ) {
        guard let url = documentURLs.first else { return }
        switch url.pathExtension {
        case "wat":
            presentTextDocument(at: url)
        case "wasm":
            presentInvocation(for: url)
        default:
            break
        }
    }

    // MARK: - Document Presentation

    var transitionController: UIDocumentBrowserTransitionController?

    func presentTextDocument(at documentURL: URL) {
        let doc = TextDocument(fileURL: documentURL)

        let documentViewController = TextDocumentViewController(document: doc)
        let docNavController = UINavigationController(rootViewController: documentViewController)

        // Load the document view.
        documentViewController.loadViewIfNeeded()
        docNavController.transitioningDelegate = self

        // Get the transition controller.
        let transitionController = self.transitionController(forDocumentAt: documentURL)
        self.transitionController = transitionController

        transitionController.targetView = documentViewController.textView

        // Set up the loading animation.
        transitionController.loadingProgress = doc.loadProgress

        // Present this document (and it's navigation controller) as full screen.
        docNavController.modalPresentationStyle = .fullScreen

        // Set and open the document.
        doc.open(completionHandler: { success in
            // Errors are handled by TextDocument.handleError
            guard success else { return }
            // Remove the loading animation.
            self.transitionController!.loadingProgress = nil

            os_log("==> Document Opened", log: .default, type: .debug)
            self.present(docNavController, animated: true, completion: nil)
        })
    }

    func presentInvocation(for documentURL: URL) {
        do {
            let bytes = Array(try Data(contentsOf: documentURL))
            let exports = try WebAssembly.getExported(wasmBytes: bytes)
            if let first = exports.first {
                let vc = WasmInvocationViewController(
                    bytes: bytes, exports: exports, selected: first)
                let nav = UINavigationController(rootViewController: vc)
                self.present(nav, animated: true)
            } else {
                reportError(title: NSLocalizedString("error.title", comment: ""),
                            message: NSLocalizedString("no-export-error.message", comment: ""))
            }
        } catch {
            reportError(title: NSLocalizedString("open-error.title", comment: ""),
                        message: error.localizedDescription)
        }
    }

    private func reportError(title: String, message: String) {
        let alert = UIAlertController(
            title: title, message: message,
            preferredStyle: .alert)

        let dismiss = UIAlertAction(
            title: NSLocalizedString("alert.ok", comment: ""), style: .default)
        alert.addAction(dismiss)

        self.present(alert, animated: true, completion: nil)
    }
}

extension DocumentBrowserViewController: UIViewControllerTransitioningDelegate {

    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        return transitionController
    }

    func animationController(forDismissed dismissed: UIViewController)
        -> UIViewControllerAnimatedTransitioning?
    {
        return transitionController
    }

}
