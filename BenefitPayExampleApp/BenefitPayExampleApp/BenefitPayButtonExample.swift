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
    @IBOutlet weak var benefitPayButton: PayButtonView!
    @IBOutlet weak var eventsTextView: UITextView!
    
    var selectedButtonType:PayButtonTypeEnum = .BenefitPay
    
    var dictConfig:[String:Any] = [
        "operator": ["publicKey": "pk_live_3zIsCFeStGLv8DNd9m054bYc", "hashString": ""],
        //"debug":true,
        //"data-testid": "TapButton",
        "transaction": [
            "amount": 0.1,
            "currency": "BHD",
            "autoDissmess": true
        ],
        "reference": [
            "order":"ord",
            "transaction":"trans"
        ],
        "merchant": ["id": ""],
        "customer": [
          "id": "",
          "names": [["lang": "en", "first": "TAP", "middle": "", "last": "PAYMENTS"]],
          "contact": [
            "email": "tap@tap.company",
            "phone": ["countryCode": "+965", "number": "88888888"],
          ],
        ],
        "interface": [
          "locale": "en",
          "edges": "curved" // straight
        ],
        //"post": ["url": ""],
        "metadata": ["": ""],
      ] {
        didSet {
            //generateHashString()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBenfitPayButton()
        if let jsonData = try? JSONSerialization.data(withJSONObject: dictConfig, options: .prettyPrinted) {
            print(String(decoding: jsonData, as: UTF8.self))
         }
    }

    func setupBenfitPayButton() {
        //generateHashString()
        benefitPayButton.initPayButton(configDict: self.dictConfig, delegate: self, payButtonType: selectedButtonType)
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
    func updateConfig(config: [String : Any], selectedButtonType: BenefitPay_iOS.PayButtonTypeEnum) {
        self.dictConfig = config
        setupBenfitPayButton()
    }
}

extension BenefitPayButtonExample: PayButtonDelegate {
    
    func onError(data: String) {
        //print("CardWebSDKExample onError \(data)")
        eventsTextView.text = "\n\n========\n\nonError \(data)\(eventsTextView.text ?? "")"
        self.view.isUserInteractionEnabled = true
    }
    
    func onSuccess(data: String) {
        //print("CardWebSDKExample onError \(data)")
        if let json = try? JSONSerialization.jsonObject(with: Data(data.utf8), options: .mutableContainers),
           let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
            eventsTextView.text = "\n\n========\n\nonSuccess \(String(decoding: jsonData, as: UTF8.self))\(eventsTextView.text ?? "")"
        } else {
            eventsTextView.text = "\n\n========\n\nonSuccess \(data)\(eventsTextView.text ?? "")"
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
        self.view.isUserInteractionEnabled = true
    }
    
    func onClick() {
        //print("CardWebSDKExample onFocus")
        eventsTextView.text = "\n\n========\n\nonClicked\(eventsTextView.text ?? "")"
    }
    
    func onCanceled() {
        eventsTextView.text = "\n\n========\n\nonCanceled\(eventsTextView.text ?? "")"
    }
    
    func onBinIdentification(data: String) {
        eventsTextView.text = "\n\n========\n\nonBinIdentification \(data)\(eventsTextView.text ?? "")"
    }
}


