//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Mazeev Roman on 6.06.17.
//  Copyright © 2017 Mazeev Roman. All rights reserved.
//

import Foundation

struct CalculatorBrain {
    
    private enum OpStack {
        case operand(Double)
        case operation(String)
        case variable(String)
        
    }
    
    private var internalProgram = [OpStack]()
    
    mutating func setOperand (_ operand: Double){
        internalProgram.append(OpStack.operand(operand))
    }
    
    mutating func setOperand(variable named: String) {
        internalProgram.append(OpStack.variable(named))
    }
    
    mutating func performOperation(_ symbol: String) {
        internalProgram.append(OpStack.operation(symbol))
    }
    
    mutating func clear() {
        internalProgram.removeAll()
    }
    
    mutating func undo() {
        if !internalProgram.isEmpty {
            internalProgram = Array(internalProgram.dropLast())
        }
    }
    
    private enum Operation {
        case constant (Double)
        case unaryOperation ((Double) -> Double,((String) -> String)?, ((Double) -> String?)?)
        case binaryOperation ((Double, Double) -> Double, ((String, String) -> String)?,
            ((Double, Double) -> String?)?, Int)
        case equals
        
    }
    
    
    private var operations : Dictionary <String,Operation> = [
        "π": Operation.constant(Double.pi),
        "±": Operation.unaryOperation({ -$0 }, nil , nil),
        "√": Operation.unaryOperation(sqrt,nil, { $0 < 0 ? "√ of a negative" : nil }),
        "%": Operation.unaryOperation({$0/100}, nil, nil),
        "cos": Operation.unaryOperation(cos,nil, nil),
        "sin": Operation.unaryOperation(sin,nil, nil),
        "tg": Operation.unaryOperation(tan,nil, nil),
        "x²" : Operation.unaryOperation({$0 * $0}, { "(" + $0 + ")²"}, nil),
        "×": Operation.binaryOperation(*, nil, nil, 1),
        "÷": Operation.binaryOperation(/, nil,
                                        { $1 == 0.0 ? "Devide by zero" : nil }, 1),
        "+": Operation.binaryOperation(+, nil, nil, 0),
        "-": Operation.binaryOperation(-, nil, nil, 0),
        "=": Operation.equals
    ]
    
    struct PendingBinaryOperation {
        let function: (Double,Double) -> Double
        let firstOperand: Double
        var descriptionFunction: (String, String) -> String
        var descriptionOperand: String
        var validator: ((Double, Double) -> String?)?
        var prevPrecedence: Int
        var precedence: Int
        
        
        func perform (with secondOperand: Double) -> Double {
            return function (firstOperand, secondOperand)
        }
        
        func performDescription (with secondOperand: String) -> String {
            var descriptionOperandNew = descriptionOperand
            if prevPrecedence < precedence {
                descriptionOperandNew = "(" +  descriptionOperandNew + ")"
            }
            return descriptionFunction (  descriptionOperandNew, secondOperand)
        }
        
        func validate (with secondOperand: Double) -> String? {
            guard let validator = validator  else {return nil}
            return validator (firstOperand, secondOperand)
        }
    }
    
    // MARK: - Evaluate
    
    func evaluate(using variables: Dictionary<String,Double>? = nil) ->
        (result: Double?, isPending: Bool, description: String, error: String?){
            
            // MARK: - Local variables evaluate
            
            var cache: (accumulator: Double?, descriptionAccumulator: String?)
            var error: String?
            
            var prevPrecedence = Int.max
            
            var pendingBinaryOperation: PendingBinaryOperation?
            
            var resultIsPending: Bool {
                get {
                    return pendingBinaryOperation != nil
                }
            }
            
            var description: String? {
                get {
                    if !resultIsPending {
                        return cache.descriptionAccumulator
                    } else {
                        return  pendingBinaryOperation!.descriptionFunction(
                            pendingBinaryOperation!.descriptionOperand,
                            cache.descriptionAccumulator ?? "")
                    }
                }
            }
            
            var result: Double? {
                get {
                    return cache.accumulator
                }
            }
            
            // MARK: - Nested function evaluate
            
            func setOperand (_ operand: Double){
                cache.accumulator = operand
                if let value = cache.accumulator {
                    cache.descriptionAccumulator =
                        formatter.string(from: NSNumber(value:value)) ?? ""
                    prevPrecedence = Int.max
                }
            }
            
            func setOperand (variable named: String) {
                cache.accumulator = variables?[named] ?? 0
                cache.descriptionAccumulator = named
                prevPrecedence = Int.max
            }
            
            func performOperation(_ symbol: String) {
                if let operation = operations[symbol]{
                    error = nil
                    switch operation {
                        
                    case .constant(let value):
                        cache = (value,symbol)
                        
                    case .unaryOperation (let function, var descriptionFunction, let validator):
                        if cache.accumulator != nil {
                            error = validator?(cache.accumulator!)
                            cache.accumulator = function (cache.accumulator!)
                            if  descriptionFunction == nil{
                                descriptionFunction = {symbol + "(" + $0 + ")"}
                            }
                            cache.descriptionAccumulator =
                                descriptionFunction!(cache.descriptionAccumulator!)
                        }
                        
                    case .binaryOperation (let function, var descriptionFunction,
                                           let validator, let precedence):
                        performPendingBinaryOperation()
                        if cache.accumulator != nil {
                            
                            if  descriptionFunction == nil{
                                descriptionFunction = {$0 + " " + symbol + " " + $1}
                            }
                            
                            pendingBinaryOperation = PendingBinaryOperation (function: function, firstOperand: cache.accumulator!, descriptionFunction: descriptionFunction!, descriptionOperand: cache.descriptionAccumulator!, validator: validator, prevPrecedence: prevPrecedence, precedence:precedence )
                            
                            cache = (nil, nil)
                        }
                        
                    case .equals:
                        performPendingBinaryOperation()
                    }
                }
            }
            
            func  performPendingBinaryOperation() {
                if resultIsPending && cache.accumulator != nil{
                    
                    error = pendingBinaryOperation!.validate(with: cache.accumulator!)
                    
                    cache.accumulator =  pendingBinaryOperation!.perform(with: cache.accumulator!)
                    cache.descriptionAccumulator =
                        pendingBinaryOperation!.performDescription(with: cache.descriptionAccumulator!)
                    
                    prevPrecedence = pendingBinaryOperation!.precedence
                    
                    pendingBinaryOperation = nil
                }
            }
            
            
            // MARK: - Body evaluate
            
            guard !internalProgram.isEmpty else {return (nil,false," ", nil)}
            prevPrecedence = Int.max
            pendingBinaryOperation = nil
            for op in internalProgram {
                switch op{
                case .operand(let operand):
                    setOperand(operand)
                case .operation(let operation):
                    performOperation(operation)
                case .variable(let symbol):
                    setOperand (variable:symbol)
                    
                }
            }
            return (result, resultIsPending, description ?? " ", error)
    }
    
    @available(iOS, deprecated, message: "No longer needed")
    var description: String {
        get {
            return evaluate().description
        }
    }
    @available(iOS, deprecated, message: "No longer needed")
    var result: Double? {
        get {
            return evaluate().result
        }
    }
    
    @available(iOS, deprecated, message: "No longer needed")
    var resultIsPending: Bool {
        get {
            return evaluate().isPending
        }
    }
}

// MARK: - NumberFromatter

let formatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 6
    formatter.notANumberSymbol = "Error"
    formatter.groupingSeparator = " "
    formatter.locale = Locale.current
    return formatter
} ()
