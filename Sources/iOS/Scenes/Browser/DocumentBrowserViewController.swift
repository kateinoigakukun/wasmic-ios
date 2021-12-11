//
//  DocumentBrowserViewController.swift
//  Wasmic
//
//  Created by kateinoigakukun on 2021/04/09.
//

import Intents
import UIKit
import WasmicKit
import WasmicWasm
import os.log

/// - Tag: DocumentBrowserViewController
class DocumentBrowserViewController: UIDocumentBrowserViewController,
    UIDocumentBrowserViewControllerDelegate
{
    private var persistentState: PersistentState!
    private let shortcutsStorage = ShortcutsStorage()
    private lazy var useInShortcutsAction: UIDocumentBrowserAction = {
        let action = UIDocumentBrowserAction(
            identifier: "dev.katei.wasmic.use-in-shortcuts",
            localizedTitle: NSLocalizedString("use-in-shortcuts.title", comment: ""),
            availability: [.menu, .navigationBar]
        ) { urls in
            do {
                for url in urls {
                    let inStorageURL = try self.shortcutsStorage.importDocument(url)
                    self.donateInteraction(documentURL: inStorageURL, export: nil)
                }
                let vc = ShortcutsNoteViewController(openShortcutsApp: {
                    UIApplication.shared.open(
                        URL(string: "shortcuts://")!, options: [:], completionHandler: nil)
                })
                self.present(vc, animated: true)
            } catch {
                self.reportError(
                    title: NSLocalizedString("error.title", comment: ""),
                    message: error.localizedDescription)
            }
        }
        action.supportsMultipleItems = true
        action.supportedContentTypes = ["dev.katei.wasmic.wasm"]
        return action
    }()

    convenience init(persistentState: PersistentState) {
        self.init()
        self.persistentState = persistentState
    }

    /// - Tag: viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self

        allowsDocumentCreation = true
        allowsPickingMultipleItems = false
        customActions = [
            useInShortcutsAction
        ]
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !persistentState.isWelcomeDone {
            let vc = WelcomeNoteViewController(completion: { [persistentState] in
                persistentState?.isWelcomeDone = true
            })
            present(vc, animated: true)
        }
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

        presentDocument(at: destinationURL)
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
        reportError(
            title: NSLocalizedString("alert.import-error.title", comment: ""),
            message: String(format: "%@ %@", prefixDescription, description))
    }

    // UIDocumentBrowserViewController is telling us to open a selected a document.
    func documentBrowser(
        _ controller: UIDocumentBrowserViewController, didPickDocumentsAt documentURLs: [URL]
    ) {
        guard let url = documentURLs.first else { return }
        presentDocument(at: url)
    }

    // MARK: - Document Presentation

    func presentDocument(at url: URL) {
        switch url.pathExtension {
        case "wat":
            presentTextDocument(at: url)
        case "wasm":
            presentInvocation(for: url)
        default:
            break
        }
    }

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
            #if targetEnvironment(macCatalyst)
            self.view.window?.rootViewController = docNavController
            #else
            self.present(docNavController, animated: true)
            #endif
        })
    }

    func presentInvocation(for documentURL: URL) {
        do {
            let didStartAccessing = documentURL.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    documentURL.stopAccessingSecurityScopedResource()
                }
            }
            let bytes = Array(try Data(contentsOf: documentURL))
            let exports = try WebAssembly.getExported(wasmBytes: bytes)
            if let first = exports.functions.first {
                if let inStorageURL = try? self.shortcutsStorage.importDocument(documentURL) {
                    donateInteraction(documentURL: inStorageURL, export: first)
                }
                let vc = WasmInvocationViewController(
                    bytes: bytes, exports: exports.functions, selected: first,
                    isWASI: exports.isWASI)
                let nav = UINavigationController(rootViewController: vc)
                #if targetEnvironment(macCatalyst)
                self.view.window?.rootViewController = nav
                #else
                self.present(nav, animated: true)
                #endif
            } else {
                reportError(
                    title: NSLocalizedString("error.title", comment: ""),
                    message: NSLocalizedString("no-export-error.message", comment: ""))
            }
        } catch {
            reportError(
                title: NSLocalizedString("open-error.title", comment: ""),
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

    private func donateInteraction(documentURL: URL, export: WebAssembly.Export?) {
        let intent = RunWasmFileIntent()
        intent.file = INFile(
            fileURL: documentURL, filename: documentURL.lastPathComponent,
            typeIdentifier: "dev.katei.wasmic.wasm")
        intent.functionName = export?.name ?? "Function Name"
        intent.arguments = [0]
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.donate { error in
            guard let error = error else { return }
            os_log(
                "Failed to donate interaction for document at URL %@, error: '%@'",
                log: OSLog.default, type: .error,
                documentURL as CVarArg, error as CVarArg)
        }
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
