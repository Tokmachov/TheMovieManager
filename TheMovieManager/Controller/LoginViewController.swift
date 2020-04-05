//
//  LoginViewController.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        emailTextField.text = ""
        passwordTextField.text = ""
    }
    
    @IBAction func loginTapped(_ sender: UIButton) {
        setLogginIn(true)
        TMDBClient.getToken(completion: self.handleGetTokenResponse(is_success:error:))
    }
    
    func handleGetTokenResponse(is_success: Bool, error: Error?) {
        guard is_success else {
            showLoginFalure(message: error!.localizedDescription)
            return
        }
        TMDBClient.login(
            userName: self.emailTextField.text ?? "",
            passWord: self.passwordTextField.text ?? "",
            completion: self.handleLoginResponse(is_success:error:)
        )
    }
    func handleLoginResponse(is_success: Bool, error: Error?) {
        guard is_success else {
            showLoginFalure(message: error!.localizedDescription)
            enableLoginContolls()
            setLogginIn(false)
            return
        }
        TMDBClient.requestSessionId(completion: self.handleRequestSessionIDResponse(is_success:error:))
    }
    func handleRequestSessionIDResponse(is_success: Bool, error: Error?) {
        setLogginIn(false)
        guard is_success else {
            showLoginFalure(message: error!.localizedDescription)
            return
        }
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "completeLogin", sender: nil)
        }
    }
    func setLogginIn(_ loginIn: Bool) {
        if loginIn {
            activityIndicator.startAnimating()
            disableLoginControlls()
        } else {
            activityIndicator.stopAnimating()
            enableLoginContolls()
        }
    }
    func disableLoginControlls() {
        emailTextField.isEnabled = false
        passwordTextField.isEnabled = false
        loginButton.isEnabled = false
    }
    func enableLoginContolls() {
        emailTextField.isEnabled = true
        passwordTextField.isEnabled = true
        loginButton.isEnabled = true
    }
    func showLoginFalure(message: String) {
        let alertVC = UIAlertController(title: "Login failed", message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        show(alertVC, sender: alertVC)
    }
}
