//
//  TapBenefitPayView.swift
//  
//
//  Created by Osama Rabie on 05/10/2023.
//

import UIKit
import WebKit
import SharedDataModels_iOS

/// The custom view that provides an interface for the  benefit pay button
internal class BenefitPayButton: PayButtonBaseView {
    /// The scheme prefix used by benefit pay sdk to show the benefit pay popup
    let benefitSDKUrlScheme:String = "https://benefit-checkout"
    /// The scheme prefix used by benefit pay sdk to show the benefit pay popup
    let benefitPayAppUrlScheme:String = "https://tbenefituser.page"
    /// The web view used to render the benefit pay button
    internal var webView: WKWebView = .init()
    /// keeps a hold of the loaded web sdk configurations url
    internal var currentlyLoadedConfigurations:URL?
    /// Keeps a reference to whether or not we should handle the on cancel because it comes directly after onSuccess
    internal var handleOnCancel:Bool = true
    /// Keeps a reference to the gif loader we will display when coming back from pay with benefit pay app
    internal var benefitGifLoader:UIImageView?
    /// Holds a reference to a loader to display on top of the button when clicked until charge api responds
    internal var loadingView:UIActivityIndicatorView = .init(style: .large)
    /// Declares if we recieved an onSuccess
    internal static var onSuccessCalled:Bool = false
    
    //MARK: - Init methods
    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    //MARK: - Private methods
    /// Used as a consolidated method to do all the needed steps upon creating the view
    private func commonInit() {
        // Set the button type
        payButtonType = .BenefitPay
        // Set the loader color
        loadingView.alpha = 0
        loadingView.color = .clear
        loadingView.startAnimating()
        // Setuo the web view contais the web sdk
        setupWebView()
        // setup the constraint to put each view in its correct positiob
        setupConstraints()
        // we will need to be notified when the user moves outside the app, to move him back to the benefitpay popup
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovingTForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    /// A notificationfunction will be called once the app is moved to backgorund
    /// We will need to show back the benefitpay button, this will only be fired, if the user is showing the middle page that displays the benefitpay app afterwards
    @objc private func appMovingTForeground() {
        // First, check if the current screen is the paywithebenefitpayapp popup, then we remove it and show the loader on the pay qith benefit qr popup
        if !removeBenefitPayAppEntry() {
            // This means, we are already in the pay with benefit qr ode and we only need to how the loader maybe the chrge will be updated
            //showGifLoader(show: true)
        }
        /*
         // SWIPE Now let us check if the benefitpay app popup is displayed
         if SwiftEntryKit.isCurrentlyDisplaying(entryNamed: "TapBenefitPayEntry") {
             // let us close it and display the benefitay pay popup again
             removeBenefitPayAppEntry()
         */
    }
    
    /// Used to open a url inside the Tap button web sdk.
    /// - Parameter url: The url needed to load.
    internal func openUrl(url: URL?) {
        // Store it for further usages
        currentlyLoadedConfigurations = url
        handleOnCancel = true
        // instruct the web view to load the needed url
        let request = URLRequest(url: url!)
        
        
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.load(request)
    }
    
    /// used to setup the constraint of the Tap button sdk view
    private func setupWebView() {
        // Creates needed configuration for the web view
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.preferredContentMode = .desktop
        configuration.setURLSchemeHandler(self, forURLScheme: "tapBenefitPayWebSDK");

        webView = WKWebView(frame: .zero, configuration: configuration)
        // Let us make sure it is of a clear background and opaque, not to interfer with the merchant's app background
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        webView.scrollView.backgroundColor = UIColor.clear
        webView.scrollView.bounces = false
        webView.isHidden = false
        // Let us add it to the view
        self.backgroundColor = .clear
        self.addSubview(webView)
        
        self.addSubview(loadingView)
        
        benefitGifLoader = benefitPayLoaderGif()
    }
    
    /// Setup Constaraints for the sub views.
    private func setupConstraints() {
        // Preprocessing needed setup
        webView.translatesAutoresizingMaskIntoConstraints = false
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        // Define the web view constraints
        let top  = webView.topAnchor.constraint(equalTo: self.topAnchor)
        let left = webView.leftAnchor.constraint(equalTo: self.leftAnchor)
        let right = webView.rightAnchor.constraint(equalTo: self.rightAnchor)
        let bottom = webView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        let buttonHeight = self.heightAnchor.constraint(greaterThanOrEqualToConstant: 48)
        // SWIPE let buttonHeight = self.heightAnchor.constraint(greaterThanOrEqualToConstant: 48)
        
        // Define the loader constraints
        let centerX = loadingView.centerXAnchor.constraint(equalTo: self.centerXAnchor)
        let centerY = loadingView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        let loaderHeight = loadingView.heightAnchor.constraint(equalToConstant: 42)
        let loaderWidth = loadingView.widthAnchor.constraint(equalToConstant: 42)
        
        // Activate the constraints
        NSLayoutConstraint.activate([left, right, top, bottom, buttonHeight, centerX, centerY, loaderHeight, loaderWidth])
        webView.layoutIfNeeded()
        webView.updateConstraints()
        loadingView.layoutIfNeeded()
        loadingView.updateConstraints()
        self.layoutIfNeeded()
    }
    
    /// Will add the web view again to the normal view after removing it from the popup screen we presented to show the benefitpay popup
    internal func addWebViewToContainerView() {
        DispatchQueue.main.async {
            self.webView.removeFromSuperview()
            self.webView.frame = .zero
            self.addSubview(self.webView)
            self.setupConstraints()
        }
    }
    
    /// A function responsible for closing the pay with benefitpay app popup and displays back the beneftpay QR code popup
    /// - Parameter onDosmiss: a callback if needed to do some logic post closeing
    /// - Returns: true if the top controller was the payw tihbenefitpayapp popup and it is dismissed now
    internal func removeBenefitPayAppEntry(onDismiss:@escaping()->() = {}) -> Bool {
        // First let us check that when the user left the app, he was at the BenefitPayAPp redirection page
        guard let topMostVC:UIViewController = UIApplication.shared.topViewController(),
              topMostVC.restorationIdentifier == "TapBenefitPayEntry" else { return false } // nothing to do
        
        // If this is the pay with benefitpayapp popup page, we need to go back to the benefitPay page and show the loader
        topMostVC.dismiss(animated: true) {
            //self.showGifLoader(show: true)
            onDismiss()
        }
        return true
    }
    
    
    
    
    
    /// Call it when you want to remove the benefitpay entry and get back to the merchant app
    /// - Parameter handleOnCancel: Whether or not, we should listen to the onCancel coming after this event or not.
    /// - Parameter onDismiss: a callback if needed to do some logic post closeing
    internal func removeBenefitPayPopupEntry(handleOnCancel:Bool = false,  onDismiss:@escaping()->()) -> Bool {
        guard let viewController:UIViewController = UIApplication.shared.topViewController(),
              viewController.restorationIdentifier == "BenefitQRVC" else { return false }
        benefitGifLoader?.isHidden = true
        self.addWebViewToContainerView()
        viewController.dismiss(animated: true) {
            onDismiss()
        }
        return true
    }
    
    
    //MARK: - Public init methods
    ///  configures the benefit pay button with the needed configurations for it to work
    ///  - Parameter config: The configurations dctionary. Recommended, as it will make you able to customly add models without updating
    ///  - Parameter delegate:A protocol that allows integrators to get notified from events fired from benefit pay button
    internal override func initPayButton(configDict: [String : Any], delegate: PayButtonDelegate? = nil) {
        self.delegate = delegate
        //let operatorModel:Operator = .init(publicKey: configDict["publicKey"] as? String ?? "", metadata: generateApplicationHeader())
        var updatedConfigurations:[String:Any] = configDict
        URL.baseUrl = payButtonType.baseUrl()
        
        // We will first need to try to load the latest base url from the CDN to make sure our backend doesn't want us to look somewhere else
        if let url = URL(string: "https://tap-sdks.b-cdn.net/mobile/benefitpay/1.0.0/base_url.json") {
            var cdnRequest = URLRequest(url: url)
            cdnRequest.timeoutInterval = 2
            cdnRequest.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            URLSession.shared.dataTask(with: cdnRequest) { data, response, error in
                 if let data = data {
                     do {
                         if let cdnResponse:[String:String] = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String],
                            let cdnBaseUrlString:String = cdnResponse["baseURL"], cdnBaseUrlString != "",
                            let cdnBaseUrl:URL = URL(string: cdnBaseUrlString),
                            let sandboxEncryptionKey:String = cdnResponse["testEncKey"],
                            let productionEncryptionKey:String = cdnResponse["prodEncKey"] {
                             URL.headersEncryptionPublicKey = productionEncryptionKey
                             URL.baseUrl = cdnBaseUrlString
                         }
                     } catch {}
                  }
                self.postInit(configDict: configDict)
              }.resume()
        }else{
            postInit(configDict: configDict)
        }
    }
    
    
    private func postInit(configDict: [String : Any]) {
        var updatedConfigurations:[String:Any] = configDict
        DispatchQueue.main.async {
            do {
                self.currentlyLoadedConfigurations = try URL(string:UrlBasedUtils.generatePayButtonSdkURL(from: updatedConfigurations, payButtonType: self.payButtonType)) ?? nil
                updatedConfigurations["headers"] = UrlBasedUtils.generateApplicationHeader(headersEncryptionPublicKey: URL.headersEncryptionPublicKey)
                updatedConfigurations["redirect"] = ["url":self.payButtonType.tapRedirectionSchemeUrl()]
                try self.openUrl(url: URL(string: UrlBasedUtils.generatePayButtonSdkURL(from: updatedConfigurations, payButtonType: self.payButtonType)))
            }
            catch {
                self.delegate?.onError?(data: "{error:\(error.localizedDescription)}")
            }
        }
    }
}


extension BenefitPayButton:WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
           print("Function: \(#function), line: \(#line)")
           print("==> \(urlSchemeTask.request.url?.absoluteString ?? "")\n")

       // You can find the url pattern by using urlSchemeTask.request.url. and create NSData from your local resource and send the data using 3 delegate method like done below.
       // You can also call server api from this native code and return the data to the task.
       // You can also cache the data coming from server and use it during offline access of this html.
       // When you are returning html the the mime type should be 'text/html'. When you are trying to return Json data then we should change the mime type to 'application/json'.
       // For returning json data you need to return NSHTTPURLResponse which has base classs of NSURLResponse with status code 200.

       // Handle WKURLSchemeTask delegate methods
          
       }

       func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
           print("Function: \(#function), line: \(#line)")
           print("==> \(urlSchemeTask.request.url?.absoluteString ?? "")\n")
       }
    
    
}
