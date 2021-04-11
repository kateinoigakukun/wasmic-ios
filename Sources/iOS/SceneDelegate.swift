//
//  SceneDelegate.swift
//  Wasmic
//
//  Created by kateinoigakukun on 2021/04/08.
//

import SwiftUI
import UIKit
import os.log

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    let rootViewController = DocumentBrowserViewController(persistentState: PersistentState())

    func scene(
        _ scene: UIScene, willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = rootViewController
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        for urlContext in URLContexts {
            guard urlContext.url.isFileURL else { continue }
            rootViewController.revealDocument(at: urlContext.url, importIfNeeded: true) {
                (url, error) in
                if let error = error {
                    os_log(
                        "Failed to reveal document at URL %@, error: '%@'",
                        log: OSLog.default, type: .error,
                        urlContext.url as CVarArg, error as CVarArg)
                    let alertController = UIAlertController(
                        title: NSLocalizedString("alert.import-error.title", comment: ""),
                        message: NSLocalizedString("alert.reveal-error.message", comment: ""),
                        preferredStyle: .alert)
                    self.rootViewController.present(
                        alertController, animated: true, completion: nil)
                    return
                }
            }
        }
    }
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        print(#function, userActivity)
    }
}
