//
//  CardWebSDKExample.swift
//  TapCardCheckoutExample
//
//

import UIKit
import BenefitPay_iOS
import Toast
import CryptoKit

class BenefitPayButtonExample: UIViewController {
    @IBOutlet weak var benefitPayButton: BenefitPayButton!
    @IBOutlet weak var eventsTextView: UITextView!
    
    
    
    var dictConfig:[String:Any] = ["operator":["publicKey":"pk_test_HJN863LmO15EtDgo9cqK7sjS","hashString":BenefitPayButtonExample.generateTapHashString(publicKey: "pk_test_HJN863LmO15EtDgo9cqK7sjS", secretKey: "sk_test_Iep2c1RCtrTE8BMPVwzi4UxF", amount: 0.1, currency: "BHD", postUrl: "", transactionReference: "trx")],
                                   "scope":"charge",
                                   "transaction":["reference":"trx",
                                                  "authorize":[
                                                    "type":"VOID",
                                                    "time":12
                                                  ]],
                                   "order":["id":"",
                                            "amount":0.1,
                                            "currency":"BHD",
                                            "description": "Authentication description",
                                            "reference":"ordRef",
                                            "metadata":[:]],
                                   "invoice":["id":""],
                                   "merchant":["id":""],
                                   "customer":["id":"",
                                               "name":[["lang":"en","first":"TAP","middle":"","last":"PAYMENTS"]],
                                               "contact":["email":"tap@tap.company",
                                                          "phone":["countryCode":"+965","number":"88888888"]]],
                                   "interface":["locale": "en",
                                                "theme": UIView().traitCollection.userInterfaceStyle == .dark ? "dark": "light",
                                                "edges": "curved",
                                                "colorStyle":UIView().traitCollection.userInterfaceStyle == .dark ? "monochrome": "colored",
                                                "loader": true],
                                   "post":["url":""]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBenfitPayButton()
    }

    func setupBenfitPayButton() {
        benefitPayButton.initBenefitPayButton(configDict: self.dictConfig, delegate: self)
    }
    
    @IBAction func optionsClicked(_ sender: Any) {
        let alertController:UIAlertController = .init(title: "Options", message: "Select one please", preferredStyle: .actionSheet)
        alertController.addAction(.init(title: "Copy logs", style: .default, handler: { _ in
            UIPasteboard.general.string = self.eventsTextView.text
        }))
        
        alertController.addAction(.init(title: "Clear logs", style: .default, handler: { _ in
            self.eventsTextView.text = ""
        }))
        
        alertController.addAction(.init(title: "Configs", style: .default, handler: { _ in
            self.configClicked()
        }))
        
        alertController.addAction(.init(title: "Cancel", style: .cancel))
        present(alertController, animated: true)
    }
    
    func configClicked() {
        let configCtrl:BenefitPayButtonSettingsViewController = storyboard?.instantiateViewController(withIdentifier: "BenefitPayButtonSettingsViewController") as! BenefitPayButtonSettingsViewController
        configCtrl.config = dictConfig
        configCtrl.delegate = self
        //present(configCtrl, animated: true)
        self.navigationController?.pushViewController(configCtrl, animated: true)
        
    }
    
    
    /**
         This is a helper method showing how can you generate a hash string when performing live charges
         - Parameter publicKey:             The Tap public key for you as a merchant pk_.....
         - Parameter secretKey:             The Tap secret key for you as a merchant sk_.....
         - Parameter amount:                The amount you are passing to the SDK, ot the amount you used in the order if you created the order before.
         - Parameter currency:              The currency code you are passing to the SDK, ot the currency code you used in the order if you created the order before. PS: It is the capital case of the 3 iso country code ex: SAR, KWD.
         - Parameter post:                  The post url you are passing to the SDK, ot the post url you pass within the Charge API. If you are not using postUrl please pass it as empty string
         - Parameter transactionReference:  The reference.trasnsaction you are passing to the SDK(not all SDKs supports this,) or the reference.trasnsaction  you pass within the Charge API. If you are not using reference.trasnsaction please pass it as empty string
         */
        static func generateTapHashString(publicKey:String, secretKey:String, amount:Double, currency:String, postUrl:String = "", transactionReference:String = "") -> String {
            // Let us generate our encryption key
            let key = SymmetricKey(data: Data(secretKey.utf8))
            // For amounts, you will need to make sure they are formatted in a way to have the correct number of decimal points. For BHD we need them to have 3 decimal points
            // We will need to format it based on the currency's decimal points
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .currency
            numberFormatter.currencySymbol = ""
            numberFormatter.currencyCode = currency
            let formattedAmount:String = numberFormatter.string(for: amount) ?? ""
            // Let us format the string that we will hash
            let toBeHashed = "x_publickey\(publicKey)x_amount\(formattedAmount)x_currency\(currency)x_transaction\(transactionReference)x_post\(postUrl)"
            // let us generate the hash string now using the HMAC SHA256 algorithm
            let signature = HMAC<SHA256>.authenticationCode(for: Data(toBeHashed.utf8), using: key)
            let hashedString = Data(signature).map { String(format: "%02hhx", $0) }.joined()
            return hashedString
        }
    
    /*func setConfig(config: CardWebSDKConfig) {
        self.config = config
    }*/
}


extension BenefitPayButtonExample: BenefitPayButtonSettingsViewControllerDelegate {
    
    func updateConfig(config: [String:Any]) {
        self.dictConfig = config
        setupBenfitPayButton()
    }
}

extension BenefitPayButtonExample: BenefitPayButtonDelegate {
    
    func onError(data: String) {
        //print("CardWebSDKExample onError \(data)")
        eventsTextView.text = "\n\n========\n\nonError \(data)\(eventsTextView.text ?? "")"
    }
    
    func onSuccess(data: String) {
        //print("CardWebSDKExample onError \(data)")
        eventsTextView.text = "\n\n========\n\nonSuccess \(data)\(eventsTextView.text ?? "")"
        if let json = try? JSONSerialization.jsonObject(with: Data(data.utf8), options: .mutableContainers),
           let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
            let controller:OnSuccessViewController = storyboard?.instantiateViewController(withIdentifier: "OnSuccessViewController") as! OnSuccessViewController
            controller.string = String(decoding: jsonData, as: UTF8.self)
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.present(controller, animated: true, completion: nil)
            }
        } else {
            print("json data malformed")
        }
    }
    
    func onOrderCreated(data: String) {
        //print("CardWebSDKExample onError \(data)")
        eventsTextView.text = "\n\n========\n\nonOrderCreated \(data)\(eventsTextView.text ?? "")"
    }
    
    func onChargeCreated(data: String) {
        //print("CardWebSDKExample onError \(data)")
        eventsTextView.text = "\n\n========\n\nonChargeCreated \(data)\(eventsTextView.text ?? "")"
    }
    
    func onReady(){
        //print("CardWebSDKExample onReady")
        eventsTextView.text = "\n\n========\n\nonReady\(eventsTextView.text ?? "")"
    }
    
    func onClicked() {
        //print("CardWebSDKExample onFocus")
        eventsTextView.text = "\n\n========\n\nonClicked\(eventsTextView.text ?? "")"
    }
    
    func onCanceled() {
        eventsTextView.text = "\n\n========\n\nonCanceled\(eventsTextView.text ?? "")"
    }
}


