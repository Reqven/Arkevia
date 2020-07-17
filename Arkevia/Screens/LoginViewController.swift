//
//  LoginViewController.swift
//  Arkevia
//
//  Created by Reqven on 11/07/2020.
//  Copyright © 2020 Manu Marchand. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    // MARK: - Properties
    private var stackView = UIStackView()
    private var usernameField = RoundedTextField()
    private var passwordField = RoundedTextField()
    private var loginButton = RoundedButton()
    
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        initialSetup()
    }
    
    @objc private func login() {
        let username = usernameField.text!, password = passwordField.text!
        guard !username.isEmpty, !password.isEmpty else { return }
        
        NetworkManager.shared.login(username: username, password: password) { result in
            if case .failure(_) = result {
                DispatchQueue.main.async {
                    let title = "Authentication failed"
                    let message = "An error occured when checking your credentials. Please try again."
                    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            } else {
                DispatchQueue.main.async {
                    self.saveCredentials()
                    guard let window = self.view.window else { fatalError() }
                    
                    let transition = CATransition()
                    transition.duration = 0.5
                    transition.type = .reveal
                    transition.subtype = .fromBottom
                    transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    
                    window.rootViewController = UINavigationController(rootViewController: FileBrowserViewController())
                    window.layer.add(transition, forKey: kCATransition)
                    window.makeKeyAndVisible()
                }
            }
        }
    }
    
    private func saveCredentials() {
        let username = usernameField.text!, password = passwordField.text!
        KeychainWrapper.standard.set(username, forKey: "username")
        KeychainWrapper.standard.set(password, forKey: "password")
    }
}



// MARK: - Setup
extension LoginViewController {
    
    private func initialSetup() {
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        
        view.backgroundColor = .systemBackground
        view.addGestureRecognizer(tap)
        view.addSubview(stackView)
        
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubviews(usernameField, passwordField, loginButton)
        
        loginButton.setTitle("Login", for: .normal)
        loginButton.backgroundColor = .systemBlue
        loginButton.tintColor = .white
        loginButton.addTarget(self, action: #selector(login), for: .touchUpInside)
        
        usernameField.placeholder = "Username"
        usernameField.textContentType = .username
        usernameField.autocapitalizationType = .none
        usernameField.text = KeychainWrapper.standard.string(forKey: "username")
        
        passwordField.placeholder = "Password"
        passwordField.textContentType = .password
        passwordField.isSecureTextEntry = true
        passwordField.text = KeychainWrapper.standard.string(forKey: "password")
        
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -16),
            
            usernameField.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            passwordField.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            loginButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }
}
