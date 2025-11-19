//
//  TapCardView+WebDelegate.swift
//  TapCardCheckOutKit
//
//  Created by Osama Rabie on 12/09/2023.
//

import Foundation
import UIKit
import WebKit
import SharedDataModels_iOS
import Robin
import UserNotifications
import UserNotificationsUI

/// An extension to take care of the notifications being sent from the web view through the url schemes
extension BenefitPayButton:WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let url = webView.url else { return }
        
        if url.absoluteString.hasPrefix(BenefitPayButton.benefitPayFireBaseURL) {
            // This means, BenefitPay popup wil be displayed and we need to make our weview full screen
            DispatchQueue.main.async {
                webView.evaluateJavaScript(BenefitPayButton.javaScriptCodeToSkipManInTheMiddle, completionHandler: { _, error in
                    print(error?.localizedDescription)
                })
            }
        }
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        var action: WKNavigationActionPolicy?
        
        defer {
            decisionHandler(action ?? .allow)
        }
        
        guard let url = navigationAction.request.url else { return }
        
        let lowercasedAbsolute = url.absoluteString.lowercased()
        if let scheme = url.scheme?.lowercased(),
           scheme != "http",
           scheme != "https" {
            action = .cancel
            DispatchQueue.main.async {
                print("BenefitPay deep link:", url.absoluteString)
                _ = UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            return
        }
        
        if lowercasedAbsolute.hasPrefix(payButtonType.webSdkScheme()) {
            print("navigationAction1", url.absoluteString)
            return
        }else{
            print("navigationAction2", url.absoluteString)
        }
                
        
        // In all cases when we get a feedback from the web view we will need to hide the loader if it is being displayed
        // Let us see if the web sdk is telling us something
        if( url.absoluteString.lowercased().contains(payButtonType.webSdkScheme())) {
            switch url.absoluteString {
            case _ where url.absoluteString.contains(CallBackSchemeEnum.onError.rawValue):
                self.handleOnError(data: tap_extractDataFromUrl(url, for: "data", shouldBase64Decode: true))
                self.loadingView.isHidden = true
                break
            case _ where url.absoluteString.contains(CallBackSchemeEnum.onOrderCreated.rawValue):
                delegate?.onOrderCreated?(data: tap_extractDataFromUrl(url, for: "data", shouldBase64Decode: false))
                break
            case _ where url.absoluteString.contains(CallBackSchemeEnum.onChargeCreated.rawValue):
                delegate?.onChargeCreated?(data: tap_extractDataFromUrl(url, for: "data", shouldBase64Decode: true))
                break
            case _ where url.absoluteString.contains(CallBackSchemeEnum.onSuccess.rawValue):
                self.handleOnSuccess(url:url)
                break
            case _ where url.absoluteString.contains(CallBackSchemeEnum.onReady.rawValue):
                self.loadingView.isHidden = true
                delegate?.onReady?()
                break
            case _ where url.absoluteString.contains(CallBackSchemeEnum.onClick.rawValue):
                self.handleOnClick()
                break
            case _ where url.absoluteString.contains(CallBackSchemeEnum.onCancel.rawValue):
                self.loadingView.isHidden = true
                self.removeBenefitPayPopupEntry(handleOnCancel: true) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                        guard !BenefitPayButton.onSuccessCalled else {
                            return
                        }
                        self.delegate?.onCanceled?()
                    }
                }
                break
            default:
                break
            }
        }else if url.absoluteString.hasPrefix(benefitSDKUrlScheme) {
            // This means, BenefitPay popup wil be displayed and we need to make our weview full screen
            let viewContoller:UIViewController = createBenefitPayPopUpView()
            self.benefitGifLoader?.isHidden = true
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) {
                if let topMost:UIViewController = UIApplication.shared.topViewController() {
                    topMost.present(viewContoller, animated: true)
                }
            }
        }
    }
    
    
    /// For the on click we need to display the loader view until we get a response back from the web view
    func handleOnClick() {
        // Make sure it is on top & visible
        self.bringSubviewToFront(loadingView)
        self.loadingView.isHidden = false
        // Handle the on cancel and inform the consumer app that on click is triggered
        self.handleOnCancel = true
        BenefitPayButton.onSuccessCalled = false
        delegate?.onClick?()
    }
    
    func handleOnSuccess(url:URL) {
        BenefitPayButton.onSuccessCalled = true
        self.webView.isHidden = false
        if !self.removeBenefitPayAppEntry(onDismiss: {
            self.removeBenefitPayPopupEntry(handleOnCancel: false) {
                self.delegate?.onSuccess?(data: tap_extractDataFromUrl(url, for: "data", shouldBase64Decode: true))
                //self.openUrl(url: self.currentlyLoadedConfigurations)
            }
        }) {
            self.delegate?.onSuccess?(data: tap_extractDataFromUrl(url, for: "data", shouldBase64Decode: true))
            self.removeBenefitPayPopupEntry(handleOnCancel: false) {
                //self.openUrl(url: self.currentlyLoadedConfigurations)
            }
        }
    }
    
    
    func handleOnError(data:String) {
        self.webView.isHidden = false
        
        
        if !self.removeBenefitPayAppEntry(onDismiss: {
            if (self.removeBenefitPayPopupEntry(handleOnCancel: false, onDismiss: {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                    guard !BenefitPayButton.onSuccessCalled else {
                        return
                    }
                    self.delegate?.onError?(data:data)
                }
                self.webView.isUserInteractionEnabled = true
            })){} else{
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                    guard !BenefitPayButton.onSuccessCalled else {
                        return
                    }
                    self.delegate?.onError?(data:data)
                }
                self.webView.isUserInteractionEnabled = true
            }
        }) {
            if (self.removeBenefitPayPopupEntry(handleOnCancel: false) {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                    guard !BenefitPayButton.onSuccessCalled else {
                        return
                    }
                    self.delegate?.onError?(data:data)
                }
                self.webView.isUserInteractionEnabled = true
                //self.openUrl(url: self.currentlyLoadedConfigurations)
            }){}else{
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                    guard !BenefitPayButton.onSuccessCalled else {
                        return
                    }
                    self.delegate?.onError?(data:data)
                }
                self.webView.isUserInteractionEnabled = true
            }
        }
    }
}



extension BenefitPayButton:WKUIDelegate {
   
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // BenefitPay web SDK triggers window.open to initiate the app redirect. Instead of
        // presenting our own popup WKWebView, just load the request inside the existing web view.
        guard navigationAction.targetFrame == nil else { return nil }
        webView.load(navigationAction.request)
        return nil
    }
}
