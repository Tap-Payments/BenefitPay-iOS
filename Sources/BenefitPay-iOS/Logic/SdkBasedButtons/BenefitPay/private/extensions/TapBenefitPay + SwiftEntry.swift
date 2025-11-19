//
//  File.swift
//  
//
//  Created by Osama Rabie on 12/10/2023.
//

import UIKit
import WebKit

internal extension BenefitPayButton {
    
   /* /**
     Defines the attributes needed to dislay the full screen modal for the BenefitPay popup
     - Parameter intorAnimation: defines whether or not to apply intro animation
     - Parameter exitAnimation: defines whether or not to apply exit animation
     */
    func entryAttributes(intoAnimation:Bool = true, exitAnimation:Bool = true) -> EKAttributes {
        var attributes = EKAttributes.float
        attributes.entryBackground = .clear
        attributes.screenBackground = .visualEffect(style: .prominent)
        attributes.displayDuration = .infinity
        attributes.name = "TapBenefitQrCodeEntry"
        // Give the entry the width of the screen minus 20pts from each side, the height is decided by the content's contraint's
        attributes.positionConstraints.size = .init(width: .offset(value: 0), height: .offset(value: 0))
//        attributes.positionConstraints.verticalOffset = -100
//        attributes.positionConstraints.safeArea = .overridden
        
        attributes.entranceAnimation = intoAnimation ? .init(
            fade: .init(from: 0.5, to: 1, duration: 0.5)) : .none
        
        attributes.exitAnimation = exitAnimation ? .init(
            fade: .init(from: 1, to: 0, duration: 0.5)) : .none
        
        return attributes
    }
    
    
    /**
     Defines the attributes needed to dislay the full screen modal for the  Pay with BenefitPay App popup
     - Parameter introAnimation: defines whether or not to apply intro animation
     - Parameter exitAnimation: defines whether or not to apply exit animation
     */
    func entryAttributes2(introAnimation:Bool = true, exitAnimation:Bool = true) -> EKAttributes {
        var attributes = EKAttributes.float
        attributes.entryBackground = .clear
        attributes.screenBackground = .visualEffect(style: .prominent)
        attributes.displayDuration = .infinity
        attributes.name = "TapBenefitPayEntry"
        attributes.entryInteraction = .forward
        // Give the entry the width of the screen minus 20pts from each side, the height is decided by the content's contraint's
        attributes.positionConstraints.size = .init(width: .offset(value: 0), height: .offset(value: 0))
//        attributes.positionConstraints.verticalOffset = -100
//        attributes.positionConstraints.safeArea = .overridden
        
        attributes.entranceAnimation = introAnimation ? .init(
            fade: .init(from: 0.5, to: 1, duration: 0.5)) : .none
        
        attributes.exitAnimation = exitAnimation ? .init(
            fade: .init(from: 1, to: 0, duration: 0.5)) : .none
        
        return attributes
    }*/
    
    /// Will create a view that contains a full screen web view to display within the benefit pay modal popup
    /// Also, will add the benefit pay gif loader in the center of the modal screen
    /// - Parameter showBenefitPayLoader: Decides whether or not to show the benefit pay loader
    func createBenefitPayPopUpView() -> UIViewController {
        // The container iew
        let view:UIView = .init()
        view.backgroundColor = .black
        //webView.isHidden = true
        webView.removeFromSuperview()
        view.addSubview(webView)
        
        // The loader image view
        if let _ = benefitGifLoader?.superview {
            benefitGifLoader?.removeFromSuperview()
        }
        benefitGifLoader?.tag = 2
        view.addSubview(benefitGifLoader!)
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        } else {
            // Fallback on earlier versions
        }
        // Define the constrains of the web view to be full screen
        let top  = webView.topAnchor.constraint(equalTo: view.topAnchor)
        let left = webView.leftAnchor.constraint(equalTo: view.leftAnchor)
        let right = webView.rightAnchor.constraint(equalTo: view.rightAnchor)
        let bottom = webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
       
        // Define the constraints of the loader to be centered
        let loaderCenterY  = benefitGifLoader!.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        let loaderCenterX = benefitGifLoader!.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        let loadderWidth = benefitGifLoader!.widthAnchor.constraint(equalToConstant: 90)
        let loaderHeight = benefitGifLoader!.heightAnchor.constraint(equalTo:benefitGifLoader!.widthAnchor)
        
        // Activate the constraints
        NSLayoutConstraint.activate([left, right, top, bottom, loaderCenterY, loaderCenterX, loadderWidth, loaderHeight])
        
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        benefitGifLoader?.translatesAutoresizingMaskIntoConstraints = false
        
        
        let ctr:UIViewController = .init()
        ctr.view.backgroundColor = .red
        ctr.modalPresentationStyle = .fullScreen
        ctr.view.addSubview(view)
        ctr.restorationIdentifier = "BenefitQRVC"
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let vtop  = view.topAnchor.constraint(equalTo: ctr.view.topAnchor)
        let vleft = view.leftAnchor.constraint(equalTo: ctr.view.leftAnchor)
        let vright = view.rightAnchor.constraint(equalTo: ctr.view.rightAnchor)
        let vbottom = view.bottomAnchor.constraint(equalTo: ctr.view.bottomAnchor,constant: 60)
        
        // Activate the constraints
        NSLayoutConstraint.activate([left, right, top, bottom, vtop, vleft, vright, vbottom])
        
        return ctr
    }
    
    
    /// Responsible for creating the modal view that will display the middle page reqiured to display before navigating the user to BenefitPayApp
    /// - Returns: The view, the webview within and the back button
    func createBenefitPayWithAppPopupView() -> (UIViewController,WKWebView,UIButton) {
        // Create the web view and its configuations
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.preferredContentMode = .desktop
        let web:WKWebView = .init(frame: .zero,configuration: configuration)
        web.uiDelegate = self
        web.navigationDelegate = self
        // Create the view itself that will hold the web view + the back button
        let view:UIView = .init()
        view.backgroundColor = .clear
        // The back button that will dismiss the paywithbenefitapp popup
        let backButton:UIButton = .init()
        backButton.setTitle("", for: .normal)
        backButton.setImage(UIImage(named: "Close",in: Bundle.currentBundle, with: nil), for: .normal)
        backButton.backgroundColor = .clear
        backButton.addAction {
            let _ = self.removeBenefitPayAppEntry()
        }
        view.addSubview(web)
        view.addSubview(backButton)
        web.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Setyo the web view constraint to be full screen
        let top  = web.topAnchor.constraint(equalTo: view.topAnchor)
        let left = web.leftAnchor.constraint(equalTo: view.leftAnchor)
        let right = web.rightAnchor.constraint(equalTo: view.rightAnchor)
        let bottom = web.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        
        // Setup the back button position
        let btop  = backButton.topAnchor.constraint(equalTo: web.topAnchor, constant: 60)
        let bright = backButton.rightAnchor.constraint(equalTo: web.rightAnchor, constant: -20)
        let bwidth = backButton.widthAnchor.constraint(equalToConstant: 32)
        let bheight = backButton.heightAnchor.constraint(equalToConstant: 32)
        
        // Activate the constraints
        NSLayoutConstraint.activate([left, right, top, bottom, btop, bright, bwidth, bheight])
        
        let ctr:UIViewController = .init()
        ctr.view.backgroundColor = .clear
        ctr.modalPresentationStyle = .overCurrentContext
        ctr.view.addSubview(view)
        ctr.restorationIdentifier = "TapBenefitPayEntry"
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let vtop  = view.topAnchor.constraint(equalTo: ctr.view.topAnchor)
        let vleft = view.leftAnchor.constraint(equalTo: ctr.view.leftAnchor)
        let vright = view.rightAnchor.constraint(equalTo: ctr.view.rightAnchor)
        let vbottom = view.bottomAnchor.constraint(equalTo: ctr.view.bottomAnchor,constant: 60)
        
        // Activate the constraints
        NSLayoutConstraint.activate([left, right, top, bottom, vtop, vleft, vright, vbottom])
        
        return (ctr,web,backButton)
    }
    
    /// Creates a UIImageView od the BenefitPay gif asset
    func benefitPayLoaderGif() -> UIImageView {
        let imageData:Data? = .init()// try? Data(contentsOf: Bundle.currentBundle.url(forResource: "BenefitLoader", withExtension: "gif")!)
        let loaderImageView = UIImageView(image:  UIImage.gifImageWithData(imageData!))
        return loaderImageView
    }
    
    func getVisibleViewController(_ rootViewController: UIViewController?) -> UIViewController? {

        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first

        if var topController = keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }

            return topController
        }
        return nil
    }
    
    /*func showGifLoader(show:Bool) {
        if(show) {
            self.webView.isUserInteractionEnabled = false
            self.benefitGifLoader?.isHidden = false
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                self.benefitGifLoader?.isHidden = true
                self.webView.isUserInteractionEnabled = true
                if let onSuccessURL = self.onSuccessURL {
                    self.handleOnSuccess(url: onSuccessURL)
                    self.onSuccessURL = nil
                }
            }
        }else{
            self.benefitGifLoader?.isHidden = true
            self.webView.isUserInteractionEnabled = true
        }
    }*/
}
