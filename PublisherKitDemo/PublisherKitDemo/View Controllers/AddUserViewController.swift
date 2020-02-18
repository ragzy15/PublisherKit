//
//  AddUserViewController.swift
//  PublisherKit+Example
//
//  Created by Raghav Ahuja on 25/01/20.
//

import UIKit
import PublisherKit

final class AddUserViewController: UIViewController {
    
    @IBOutlet private weak var nameTextField: UITextField!
    @IBOutlet private weak var avatarTextField: UITextField!
    @IBOutlet private weak var emailTextField: UITextField!
    @IBOutlet private weak var submitButton: UIButton!
    
    var viewModel: AddUserViewModel!
    
    private var cancellable: AnyCancellable?
    
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
        
        let namePublisher = getPublisher(for: nameTextField, saveIn: viewModel.updateName)
            .allSatisfy { !$0.isEmpty } // check if name is not empty
        
        
        let avatarPublisher = getPublisher(for: avatarTextField, saveIn: viewModel.updateAvatar)
            .firstMatch(pattern: "((?:http|https)://)?(?:www\\.)?[\\w\\d\\-_]+\\.\\w{2,3}(\\.\\w{2})?(/(?<=/)(?:[\\w\\d\\-./_]+)?)?")   // check if it is a valid url
            .replaceError(with: false)
        
        
        let emailPublisher = getPublisher(for: emailTextField, saveIn: viewModel.updateEmail)
            .firstMatch(pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}")   // check if it a valid email
            .replaceError(with: false)
        
        
        // combine results from all 3 text fields and assign the result to `isEnabled` property of submit button.
        cancellable = namePublisher
            .combineLatest(avatarPublisher, emailPublisher) { (isNameValid, isAvatarValid, isEmailValid) -> Bool in
                isNameValid && isAvatarValid && isEmailValid
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.submitButton.isEnabled, on: self)
    }
    
    private func getPublisher(for textField: UITextField, saveIn method: @escaping (String) -> Void) -> AnyPublisher<String, Never> {
        textField.textChangePublisher
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .handleEvents(receiveOutput: method)  // update value for field in view model
            .eraseToAnyPublisher()
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
