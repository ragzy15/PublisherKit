//
//  AddUserViewController.swift
//  PublisherKit+Example
//
//  Created by Raghav Ahuja on 25/01/20.
//  Copyright © 2020 Raghav Ahuja. All rights reserved.
//

import UIKit
import PublisherKit

final class AddUserViewController: UIViewController {
    
    @IBOutlet private weak var nameTextField: UITextField!
    @IBOutlet private weak var avatarTextField: UITextField!
    @IBOutlet private weak var emailTextField: UITextField!
    @IBOutlet private weak var submitButton: UIButton!
    
    var viewModel: AddUserViewModel!
    
    private var cancellable: PKAnyCancellable?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateSubmitButton()
        setPublishers()
    }
    
    private func updateSubmitButton() {
        submitButton.layer.borderWidth = 1
        submitButton.layer.borderColor = UIColor.systemBlue.cgColor
        submitButton.layer.cornerRadius = submitButton.frame.height / 2
        submitButton.layer.masksToBounds = true
    }
    
    private func setPublishers() {
        
        let namePublisher = nameTextField.textChangePublisher
            .handleEvents(receiveOutput: { [weak self] (name) in
                self?.viewModel.updateName(name)    // update the value from text field in user model
            })
            .allSatisfy { !$0.isEmpty } // check if name is not empty
        
        
        let avatarPublisher = avatarTextField.textChangePublisher
            .handleEvents(receiveOutput: { [weak self] (avatar) in
                self?.viewModel.updateAvatar(avatar)    // update the value from text field in user model
            })
            .firstMatch(pattern: "((?:http|https)://)?(?:www\\.)?[\\w\\d\\-_]+\\.\\w{2,3}(\\.\\w{2})?(/(?<=/)(?:[\\w\\d\\-./_]+)?)?")   // check if it is a valid url
            .replaceError(with: false)
        
        
        let emailPublisher = emailTextField.textChangePublisher
            .handleEvents(receiveOutput: { [weak self] (email) in
                self?.viewModel.updateEmail(email)   // update the value from text field in user model
            })
            .firstMatch(pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}")   // check if it a valid email
            .replaceError(with: false)
        
        
        // combine results from all 3 text fields and assign the result to `isEnabled` property of submit button.
        cancellable = namePublisher
                        .combineLatest(avatarPublisher, emailPublisher)
                        .allSatisfy { (isNameValid, isAvatarValid, isEmailValid) -> Bool in
                            isNameValid && isAvatarValid && isEmailValid
                        }
                        .assign(to: \.submitButton.isEnabled, on: self)
    }
    
    @IBAction private func submitButtonTapped(_ sender: UIButton) {
        dismiss(animated: true) {
            self.viewModel.submit()
        }
    }
    
    @IBAction private func cancelButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @IBAction private func primaryActionTapped(_ sender: UITextField) {
        // move to next textfield or dismiss keyboard if last textfield is reached.
        if let textField = view.viewWithTag(sender.tag + 1) {
            textField.becomeFirstResponder()
        } else {
            sender.resignFirstResponder()
        }
    }
}
