//
//  ViewController.swift
//  linksaver-ios
//
//  Created by Richey, Alexander on 8/1/20.
//  Copyright © 2020 Linksaver. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController, WKNavigationDelegate {
    let webView = WKWebView()
    var observation: NSKeyValueObservation?
    
    override func loadView() {
        webView.navigationDelegate = self

        self.view = webView
        
        observation = webView.observe(\WKWebView.url, options: .new) { view, change in
            print("observer called")
            guard let url = view.url else { return }
            guard let prefs = UserDefaults(suiteName: "group.io.linksaver") else { return }
            if url.absoluteString.hasSuffix("logout") {
                prefs.set("", forKey: "token")
            } else {
                if prefs.string(forKey: "token")?.isEmpty ?? true {
                    self.webView.evaluateJavaScript("document.querySelector(\"[data-token]\").dataset.token") { (value, error) in
                        if error == nil {
                            if let token = value as? String {
                                prefs.set(token, forKey: "token")
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let url = URL(string: "https://linksaver.io/sessions") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            if !(url.host?.starts(with: "linksaver.io") ?? true) {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
        }
        
        decisionHandler(.allow)
    }
}

