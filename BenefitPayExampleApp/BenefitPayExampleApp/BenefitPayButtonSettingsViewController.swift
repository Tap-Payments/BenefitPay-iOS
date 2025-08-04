//
//  CardSettingsViewController.swift
//  TapCardCheckoutExample
//
//  Created by Osama Rabie on 07/09/2023.
//

import UIKit
import Eureka
import BenefitPay_iOS

protocol BenefitPayButtonSettingsViewControllerDelegate {
    func updateConfig(config: [String:Any], selectedButtonType:PayButtonTypeEnum)
}

class BenefitPayButtonSettingsViewController: FormViewController {

    var config: [String:Any]?
    var delegate: BenefitPayButtonSettingsViewControllerDelegate?
    var selectedButtonType:PayButtonTypeEnum = .BenefitPay
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        form +++ Section("button")
        <<< AlertRow<String>("button.type"){ row in
            row.title = "Button"
            row.options = PayButtonTypeEnum.allCases.map{ $0.toString() }
            row.value = selectedButtonType.toString()
            row.onChange { row in
                self.selectedButtonType = PayButtonTypeEnum.init(rawValue: PayButtonTypeEnum.allCases.map{ $0.toString() }.firstIndex(of: row.value ?? "BENEFITPAY") ?? 0) ?? self.selectedButtonType
                self.update(dictionary: &self.config!, at: ["scope"], with: "charge")
                self.form.rowBy(tag: "scope")?.value = "charge"
                self.form.rowBy(tag: "scope")?.reload()
                self.form.rowBy(tag: "scope")?.updateCell()
                
                var selectedCurrency:String = "KWD"
                switch self.selectedButtonType {
                case .BenefitPay:
                    selectedCurrency = "BHD"
                }
                
                self.update(dictionary: &self.config!, at: ["transaction","currency"], with: selectedCurrency)
                self.form.rowBy(tag: "transaction.currency")?.value = selectedCurrency
                self.form.rowBy(tag: "transaction.currency")?.reload()
                self.form.rowBy(tag: "transaction.currency")?.updateCell()
            }
        }
        
        form +++ Section("operator")
        <<< AlertRow<String>("operator.publicKey"){ row in
            row.title = "Tap public key"
            row.options = ["pk_test_Nfq0mjd8wAL29cJp4kbiEXMF","pk_live_3zIsCFeStGLv8DNd9m054bYc"]
            row.value = (config! as NSDictionary).value(forKeyPath: "operator.publicKey") as? String ?? "pk_test_Nfq0mjd8wAL29cJp4kbiEXMF"
            row.onChange { row in
                self.update(dictionary: &self.config!, at: ["operator","publicKey"], with: row.value ?? "pk_test_Nfq0mjd8wAL29cJp4kbiEXMF")
            }
        }
        
        <<< TextRow("operator.hashString"){ row in
            row.title = "A hashstring to validate"
            row.placeholder = "Leave empty for auto generation"
            row.value = (config! as NSDictionary).value(forKeyPath: "operator.hashString") as? String ?? ""
            row.onChange { row in
                self.update(dictionary: &self.config!, at: ["operator","hashString"], with: row.value ?? "")
            }
        }
        
        
        form +++ Section("scope")
        <<< AlertRow<String>("scope"){ row in
            row.title = "Scope"
            row.options = scopes(for: selectedButtonType)
            row.value = (config! as NSDictionary).value(forKeyPath: "scope") as? String ?? "charge"
            row.onChange { row in
                self.update(dictionary: &self.config!, at: ["scope"], with: row.value ?? "charge")
            }
        }
        .cellUpdate { cell, row in
            row.options = self.scopes(for: self.selectedButtonType)
        }
        
        form +++ Section("transaction")
        <<< TextRow("transaction.reference"){ row in
            row.title = "Trx ref"
            row.placeholder = "Enter your trx ref"
            row.value = (config! as NSDictionary).value(forKeyPath: "transaction.reference") as? String ?? ""
            row.onChange { row in
                self.update(dictionary: &self.config!, at: ["transaction","reference"], with: row.value ?? "")
            }
        }
        <<< DecimalRow("transaction.amount"){ row in
            row.title = "transaction amount"
            row.placeholder = "Enter transaction's amount"
            row.value = (config?["transaction"] as? [String:Any])?["amount"] as? Double ?? 1.0
            row.onChange { row in
                self.update(dictionary: &self.config!, at: ["transaction","amount"], with: row.value ?? 1.0)
            }
        }
        <<< SwitchRow("transaction.autoDissmess"){ row in
            row.title = "autoDissmess"
            row.value = (config! as NSDictionary).value(forKeyPath: "transaction.autoDissmess") as? Bool ?? false
            row.onChange { row in
                self.update(dictionary: &self.config!, at: ["transaction","autoDissmess"], with: row.value ?? "")
            }
        }
        
        form +++ Section("merchant")
        <<< TextRow("merchant.id"){ row in
            row.title = "Tap merchant id"
            row.placeholder = "Enter your tap merchnt id"
            row.value = (config! as NSDictionary).value(forKeyPath: "merchant.id") as? String ?? ""
            row.onChange { row in
                self.update(dictionary: &self.config!, at: ["merchant","id"], with: row.value ?? "")
            }
        }
        form +++ Section("customer")
       
       <<< TextRow("customer.id"){ row in
           row.title = "Customer id"
           row.placeholder = "Enter customer's id"
           row.value = (config! as NSDictionary).value(forKeyPath: "customer.id") as? String ?? ""
           row.onChange { row in
               self.update(dictionary: &self.config!, at: ["customer","id"], with: row.value ?? "")
           }
       }
        
        form +++ Section("Reference")
       
       <<< TextRow("reference.order"){ row in
           row.title = "Reference order"
           row.placeholder = "Enter order's reference"
           row.value = (config! as NSDictionary).value(forKeyPath: "reference.order") as? String ?? ""
           row.onChange { row in
               self.update(dictionary: &self.config!, at: ["reference","order"], with: row.value ?? "")
           }
       }
        
        <<< TextRow("reference.transaction"){ row in
            row.title = "Reference transaction"
            row.placeholder = "Enter transaction's reference"
            row.value = (config! as NSDictionary).value(forKeyPath: "reference.transaction") as? String ?? ""
            row.onChange { row in
                self.update(dictionary: &self.config!, at: ["reference","transaction"], with: row.value ?? "")
            }
        }
        
        form +++ Section("interface")
        <<< AlertRow<String>("interface.locale"){ row in
            row.title = "locale"
            row.options = ["en","ar","dynamic"]
            row.value = (config! as NSDictionary).value(forKeyPath: "interface.locale") as? String ?? "en"
            row.onChange { row in
                self.update(dictionary: &self.config!, at: ["interface","locale"], with: row.value ?? "en")
            }
        }
        <<< AlertRow<String>("interface.edges"){ row in
            row.title = "edges"
            row.options = ["circular","flat"]
            row.value = (config! as NSDictionary).value(forKeyPath: "interface.edges") as? String ?? "circular"
            row.onChange { row in
                self.update(dictionary: &self.config!, at: ["interface","edges"], with: row.value ?? "circular")
            }
        }
    }
    
    
    func scopes(for button:PayButtonTypeEnum) -> [String] {
        switch button {
        case .BenefitPay:
            return ["charge"]
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.updateConfig(config: config!, selectedButtonType: selectedButtonType)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    func update(dictionary dict: inout [String: Any], at keys: [String], with value: Any) {

        if keys.count < 2 {
            for key in keys { dict[key] = value }
            return
        }

        var levels: [[AnyHashable: Any]] = []

        for key in keys.dropLast() {
            if let lastLevel = levels.last {
                if let currentLevel = lastLevel[key] as? [AnyHashable: Any] {
                    levels.append(currentLevel)
                }
                else if lastLevel[key] != nil, levels.count + 1 != keys.count {
                    break
                } else { return }
            } else {
                if let firstLevel = dict[keys[0]] as? [AnyHashable : Any] {
                    levels.append(firstLevel )
                }
                else { return }
            }
        }

        if levels[levels.indices.last!][keys.last!] != nil {
            levels[levels.indices.last!][keys.last!] = value
        } else { return }

        for index in levels.indices.dropLast().reversed() {
            levels[index][keys[index + 1]] = levels[index + 1]
        }

        dict[keys[0]] = levels[0]
    }

}

