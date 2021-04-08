//
//  KeyboardLayoutObserver.swift
//  Wasmic
//
//  Created by kateinoigakukun on 2021/04/09.
//

import UIKit

class KeyboardLayoutObserver {
    private let view: UIView
    private var keyboardAppearObserver: Any?
    private var keyboardDisappearObserver: Any?
    typealias UpdateHandler = (UIEdgeInsets, UIViewPropertyAnimator) -> Void
    var onUpdateHandler: UpdateHandler? = nil

    init(for view: UIView, onUpdateHandler: UpdateHandler? = nil) {
        self.view = view
        self.onUpdateHandler = onUpdateHandler
        setupNotifications()
    }

    private func setupNotifications() {
        let notificationCenter = NotificationCenter.default
        
        keyboardAppearObserver = notificationCenter.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: nil) { (notification) in
                self.updateState(notification: notification)
        }
        
        keyboardDisappearObserver = notificationCenter.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: nil) { (notification) in
                self.updateState(notification: notification)
        }
    }
    
    @objc
    private func updateState(notification: Notification) {
        let userInfo = notification.userInfo
        
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardScreenEndFrame = keyboardFrame.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        let keyboardInset: UIEdgeInsets
        if notification.name == UIResponder.keyboardWillHideNotification {
            keyboardInset = .zero
        } else {
            keyboardInset = UIEdgeInsets(top: 0,
                                         left: 0,
                                         bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom,
                                         right: 0)
        }
        
        guard let animationDuration =
                userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey]
                as? Double else {
            fatalError("*** Unable to get the animation duration ***")
        }
        
        guard let curveInt =
                userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int else {
            fatalError("*** Unable to get the animation curve ***")
        }
        
        guard let animationCurve =
                UIView.AnimationCurve(rawValue: curveInt) else {
            fatalError("*** Unable to parse the animation curve ***")
        }
        let animator = UIViewPropertyAnimator(duration: animationDuration, curve: animationCurve)
        onUpdateHandler?(keyboardInset, animator)
    }
}

