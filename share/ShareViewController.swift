//
//  ShareViewController.swift
//  share
//
//  Created by Richey, Alexander on 8/1/20.
//  Copyright © 2020 Linksaver. All rights reserved.
//

import UIKit
import Social

class ShareViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }

    override func didSelectPost() {
        guard let prefs = UserDefaults(suiteName: "group.io.linksaver") else { return }
        let token = (prefs.string(forKey: "token") ?? "") as String
        
        if token.isEmpty {
            self.showUnauthorizedAlert()
            return
        }
        
        if let item = extensionContext?.inputItems.first as? NSExtensionItem,
            let itemProvider = item.attachments?.first,
            itemProvider.hasItemConformingToTypeIdentifier("public.url") {
            itemProvider.loadItem(forTypeIdentifier: "public.url", options: nil) { (url, error) in
                if let shareURL = url as? URL {
                    let title = item.attributedContentText?.string ?? ""
                    self.sendRequest(url: shareURL, title: title, token: token)
                }
                self.extensionContext?.completeRequest(returningItems: [], completionHandler:nil)
            }
        }
    }

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }
    
    func sendRequest(url: URL, title: String, token: String) {
        struct LinkRequestBody: Codable {
            var url: String
            var favicon: String
            var title: String
        }
        
        var jsonData: Data
        do {
            let body = LinkRequestBody(url: url.absoluteString, favicon: "", title: title)
            jsonData = try JSONEncoder().encode(body)
        } catch {
            return
        }
        
        guard let requestUrl = URL(string: "https://linksaver.io/api/links") else { return }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(String(describing: token))", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error: \(error)")
                return
            }
     
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                print("Response:\n \(dataString)")
            }
            
        }
        task.resume()
    }
    
    func showUnauthorizedAlert() {
        let alert = UIAlertController(title: "Unauthenticated", message: "Please login on the Linksaver app to use the extension.", preferredStyle: UIAlertController.Style.alert)

        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction!) -> () in
            self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
        }))

        self.present(alert, animated: true, completion: nil)
    }
}
