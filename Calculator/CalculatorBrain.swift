//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Mazeev Roman on 06.06.17.
//  Copyright © 2017 Mazeev Roman. All rights reserved.
//

import Foundation

struct CalculatorBrain {
    
    private var cache: (accumulator: Double?, descriptionAccumulator: String?)
    
    var description: String? {
        get {
            if !resultIsPending {
                return cache.descriptionAccumulator
            } else {
                return pendingBinaryOperation!.descriptionFunction(pendingBinaryOperation!.descriptionFirstOperand, cache.descriptionAccumulator ?? "")
            }
        }
    }
    
    var result: Double? {
        get {
            return cache.accumulator
        }
    }
    
    var resultIsPending: Bool {
        get {
            return pendingBinaryOperation != nil
        }
    }
    
    private enum Operation {
        case nullaryOperation(() -> Double, String)
        case constant (Double)
        case unaryOperation ((Double) -> Double, ((String) -> String)?)
        case binaryOperation ((Double, Double) -> Double, ((String, String) -> String)?)
        case equals
    }
    private var operations : Dictionary <String,Operation> =
        [
            "Rand": Operation.nullaryOperation({Double(arc4random())/Double(UInt32.max)}, "rand()"),
            "π": Operation.constant(Double.pi),
            "e": Operation.constant(M_E),
            "√": Operation.unaryOperation(sqrt, nil),
            "%": Operation.unaryOperation({$0/100}, nil),
            "cos": Operation.unaryOperation(cos, nil),
            "sin": Operation.unaryOperation(sin, nil),
            "tg": Operation.unaryOperation(tan, nil),
            "±": Operation.unaryOperation({-$0}, nil),
            "x²": Operation.unaryOperation({$0 * $0}, {"(" + $0 + ")²"}),
            "×": Operation.binaryOperation({$0 * $1}, nil),
            "÷": Operation.binaryOperation({$0 / $1}, nil),
            "+": Operation.binaryOperation({$0 + $1}, nil),
            "-": Operation.binaryOperation({$0 - $1}, nil),
            "=": Operation.equals,
            ]
    
    mutating func performOperation(_ symbol: String) {
        if let operation = operations[symbol]{
            switch operation {
                
            case .nullaryOperation(let function, let descriptionValue):
                cache = (function(), descriptionValue)
                
            case .constant(let value):
                cache = (value, symbol)
                
            case .unaryOperation (let function, var descriptionFunction):
                if cache.accumulator != nil {
                    cache.accumulator = function (cache.accumulator!)
                    if descriptionFunction == nil {
                        descriptionFunction = {symbol + "(" + $0 + ")"}
                    }
                    cache.descriptionAccumulator = descriptionFunction!(cache.descriptionAccumulator!)
                }
                
                
            case .binaryOperation (let function, var descriptionFunction):
                performPendingBinaryOperation()
                if cache.accumulator != nil {
                    if descriptionFunction == nil {
                        descriptionFunction = {$0 + " " + symbol + " " + $1}
                    }
                    pendingBinaryOperation = PendingBinaryOperation (function: function, firstOperand: cache.accumulator!, descriptionFunction: descriptionFunction!, descriptionFirstOperand: cache.descriptionAccumulator!)
                    cache = (nil, nil)
                }
                
            case .equals:
                performPendingBinaryOperation()
                
            }
        }
    }
    
    private mutating func  performPendingBinaryOperation() {
        if resultIsPending && cache.accumulator != nil {
            cache.accumulator =  pendingBinaryOperation!.perform(with: cache.accumulator!)
            cache.descriptionAccumulator = pendingBinaryOperation?.performDescription(with: cache.descriptionAccumulator!)
            pendingBinaryOperation = nil
        }
    }
    
    private var pendingBinaryOperation: PendingBinaryOperation?
    
    private struct PendingBinaryOperation {
        let function: (Double,Double) -> Double
        let firstOperand: Double
        
        var descriptionFunction: (String, String) -> String
        var descriptionFirstOperand: String
        
        func perform (with secondOperand: Double) -> Double {
            return function (firstOperand, secondOperand)
        }
        
        func performDescription(with descriptionSecondOperand: String) -> String {
            return descriptionFunction (descriptionFirstOperand, descriptionSecondOperand)
        }
    }
    
    mutating func setOperand (_ operand: Double){
        cache.accumulator = operand
        if let value = cache.accumulator {
            cache.descriptionAccumulator = formatter.string(from: NSNumber(value: value)) ?? ""
        }
    }
    
    mutating func clear () {
        cache = (nil, " ")
        pendingBinaryOperation = nil
    }
}

let formatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 6
    formatter.notANumberSymbol = "Error"
    formatter.groupingSeparator = " "
    formatter.locale = Locale.current
    return formatter
}()
