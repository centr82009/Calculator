//
//  ViewController.swift
//  Calculator
//
//  Created by Mazeev Roman on 6.06.17.
//  Copyright © 2017 Mazeev Roman. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var display: UILabel!
    @IBOutlet weak var historyDisplay: UILabel!
    @IBOutlet weak var decimalSeparatorButton: UIButton! {
        didSet {
            decimalSeparatorButton.setTitle(decimalSeparator, for: UIControlState())
        }
    }
    @IBOutlet weak var displayM: UILabel!
    
    let decimalSeparator = formatter.decimalSeparator ?? "."
    
    var userInTheMiddleOfTyping = false
    
    @IBAction func touchDigit(_ sender: UIButton) {
        let digit = sender.currentTitle!
        let textCurrentlyInDisplay = display.text!
        if userInTheMiddleOfTyping && !(textCurrentlyInDisplay == "0") {
            if (digit != decimalSeparator) || !(textCurrentlyInDisplay.contains(decimalSeparator)) {
                display.text = textCurrentlyInDisplay + digit
            }
        } else if sender.titleLabel?.text == "." {
            display.text = "0."
            userInTheMiddleOfTyping = true
        } else {
            display.text = digit
            userInTheMiddleOfTyping = true
        }
    }
    
    var displayValue: Double? {
        get {
            if let text = display.text, let value = Double(text) {
                return value
            }
            return nil
        }
        set {
            if let value = newValue {
                let extractedExpr: NSNumber = NSNumber(value: value)
                display.text = formatter.string(from: extractedExpr)
            }
        }
    }
    
    var displayResult: (result: Double?, isPending: Bool,
        description: String, error: String?) = (nil, false," ", nil){
        
        didSet {
            switch displayResult {
            case (nil, _, " ", nil) : displayValue = 0
            case (let result, _,_,nil): displayValue = result
            case (_, _,_,let error): display.text = error!
            }
            
            historyDisplay.text = displayResult.description != " " ?
                displayResult.description + (displayResult.isPending ? " …" : " =") : " "
            if let value = variableValues["M"] {
                displayM.text = formatter.string(from: NSNumber(value:value))
            } else {
                displayM.text = " "
            }
            
        }
    }
    
    // MARK: - Model
    private var brain = CalculatorBrain ()
    private var variableValues = [String: Double]()
    
    @IBAction func performOPeration(_ sender: UIButton) {
        if userInTheMiddleOfTyping {
            if let value = displayValue {
                brain.setOperand(value)
            }
            userInTheMiddleOfTyping = false
        }
        if  let mathematicalSymbol = sender.currentTitle {
            brain.performOperation(mathematicalSymbol)
        }
        displayResult = brain.evaluate(using: variableValues)
    }
    
    @IBAction func clearButton(_ sender: UIButton) {
        userInTheMiddleOfTyping = false
        brain.clear()
        variableValues = [:]
        displayResult = brain.evaluate()
    }
    
    @IBAction func undoButton(_ sender: UIButton) {
        if userInTheMiddleOfTyping {
            guard !display.text!.isEmpty else {return }
            display.text = String (display.text!.characters.dropLast())
            if display.text!.isEmpty{
                display.text = "0"
                userInTheMiddleOfTyping = false
                displayResult = brain.evaluate(using: variableValues)
            }
        } else {
            brain.undo()
            displayResult = brain.evaluate(using: variableValues)
        }
    }
    
    @IBAction func setM(_ sender: UIButton) {
        userInTheMiddleOfTyping = false
        let symbol = String((sender.currentTitle!).characters.dropFirst())
        
        variableValues[symbol] = displayValue
        displayResult = brain.evaluate(using: variableValues)
    }
    
    @IBAction func pushM(_ sender: UIButton) {
        brain.setOperand(variable: sender.currentTitle!)
        displayResult = brain.evaluate(using: variableValues)
    }
}
