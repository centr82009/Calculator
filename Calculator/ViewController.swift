//
//  ViewController.swift
//  Calculator
//
//  Created by Mazeev Roman on 06.06.17.
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

    
    let decimalSeparator = formatter.decimalSeparator ?? "."
    
    var userInTheMiddleOfTyping = false
    
    @IBAction func touchDigit(_ sender: UIButton) {
        let digit = sender.currentTitle!
        if userInTheMiddleOfTyping {
            let textCurrentlyInDisplay = display.text!
            if (digit != decimalSeparator) || !(textCurrentlyInDisplay.contains(decimalSeparator)){
                display.text = textCurrentlyInDisplay + digit
            }
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
                display.text = formatter.string(from: NSNumber(value: value))
            }
            if let description = brain.description {
                historyDisplay.text = description + (brain.resultIsPending ? " …" : " =")
            }
        }
    }
    
    private var brain = CalculatorBrain ()
    
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
        displayValue = brain.result
    }
    
    @IBAction func cancelButton(_ sender: UIButton) {
        brain.clear()
        displayValue = 0
        historyDisplay.text = " "
        userInTheMiddleOfTyping = false
    }
    
    @IBAction func backspaceButton(_ sender: UIButton) {
        guard userInTheMiddleOfTyping && !display.text!.isEmpty else {
            return
        }
        display.text = String(display.text!.characters.dropLast())
        if display.text!.isEmpty {
            displayValue = 0
        }
    }
}
