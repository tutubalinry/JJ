//
//  JJ.swift
//  Pods
//
//  Created by Yury Korolev on 5/27/16.
//
//

import Foundation

private let _rfc3339DateFormatter: DateFormatter = _buildRfc3339DateFormatter()
/** - Returns: **RFC 3339** date formatter */
private func _buildRfc3339DateFormatter() -> DateFormatter {
    let formatter = DateFormatter()
    formatter.locale = Locale(localeIdentifier: "en_US")
    formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"
    formatter.timeZone = TimeZone(forSecondsFromGMT: 0)
    return formatter
}

public extension String {
    /**
     Returns a date representation of a given **RFC 3339** string. If dateFromString: can not parse the string, returns `nil`.
     - Returns: A date representation of string.
     */
    func asRFC3339Date() -> Date? {
        return _rfc3339DateFormatter.date(from: self)
    }
}

public extension Date {
    /**
     Returns a **RFC 3339** string representation of a given date formatted.
     - Returns: A **RFC 3339** string representation.
     */
    func toRFC3339String() -> String {
        return _rfc3339DateFormatter.string(from: self)
    }
}

public enum JJError: ErrorProtocol, CustomStringConvertible {
    /** Throws on can't convert value on path */
    case wrongType(v: AnyObject?, path: String, toType: String)
    /** Throws on can't find object on path */
    case notFound(path: String)

    public var description: String {
        switch self {
        case let .wrongType(v: v, path: path, toType: type):
            return "JJError.WrongType: Can't convert \(v) at path: '\(path)' to type '\(type)'"
        case let .notFound(path: path):
            return "JJError.NotFound: No object at path: '\(path)'"
        }
    }
}
/**
 - Parameter v: `AnyObject` to parse
 - Returns: `JJVal`
 */
public func jj(_ v: AnyObject?) -> JJVal { return JJVal(v) }
/**
 - Parameter decoder: `NSCoder` to decode
 - Returns: `JJDec`
 */
public func jj(decoder: NSCoder) -> JJDec { return JJDec(decoder) }
/**
 - Parameter encoder: `NSCoder` to encode
 - Returns: `JJEnc`
 */
public func jj(encoder: NSCoder) -> JJEnc { return JJEnc(encoder) }
/**
 Struct for store parsing `Array` of `AnyObject`
 */
public struct JJArr: CustomDebugStringConvertible {
    private let _path: String
    private let _v: [AnyObject]
    /**
     Init `JJArr`
     - Parameters:
        - v: Array of AnyObject
        - path: path in original object
     - Returns: `JJArr`
     */
    public init(_ v: [AnyObject], path: String) {
        _v = v
        _path = path
    }
    /**
     - Parameter index: Index of element
     - Returns: `JJVal` or `JJVal(nil, path: newPath)` if `index` is out of `Array`
     */
    public subscript (index: Int) -> JJVal {
        return at(index)
    }
    /**
     - Parameter index: Index of element
     - Returns: `JJVal` or `JJVal(nil, path: newPath)` if `index` is out of `Array`
     */
    public func at(_ index: Int) -> JJVal {
        let newPath = _path + "[\(index)]"

        if index >= 0 && index < _v.count {
            return JJVal(_v[index], path: newPath)
        }
        return JJVal(nil, path: newPath)
    }

    // MARK: extension point
    /** Raw value of `Array` of `AnyObject` */
    public var raw: [AnyObject] { return _v }
    /** Path in original object */
    public var path: String { return _path }

    // MARK: Shortcusts
    /** `True` if object exist */
    public var exists: Bool { return true }
    /** The number of elements the `Array` stores */
    public var count:Int { return _v.count }
    /**
     - Parameters:
     - space: space between parent elements of `Array`
     - spacer: space to embedded values
     - Returns: A textual representation of `Array`
     */
    public func prettyPrint(space: String = "", spacer: String = "  ") -> String {
        if _v.count == 0 {
            return "[]"
        }
        var str = "[\n"
        let nextSpace = space + spacer
        for v in _v {
            str += "\(nextSpace)" + jj(v).prettyPrint(space: nextSpace, spacer: spacer) + ",\n"
        }
        str.remove(at: str.index(str.endIndex, offsetBy: -2))
        
        return str + "\(space)]"
    }
    /** A Textual representation of stored `Array` */
    public var debugDescription: String { return prettyPrint() }
}
/** 
 Struct like `JJArr` but raw value is optional 
 */
public struct JJMaybeArr {
    private let _path: String
    private let _v: JJArr?

    public init(_ v: JJArr?, path: String) {
        _v = v
        _path = path
    }

    public func at(_ index: Int) -> JJVal {
        return _v?.at(index) ?? JJVal(nil, path: _path + "<nil>[\(index)]")
    }

    public subscript (index: Int) -> JJVal { return at(index) }

    public var exists: Bool { return _v != nil }

    // MARK: extension point
    public var raw: [AnyObject]? { return _v?.raw }
    public var path: String { return _path }

}
/**
 Struct for store parsing `Dictionary`
 */
public struct JJObj: CustomDebugStringConvertible {
    private let _path: String
    private let _v: [String: AnyObject]
    /**
     Init `JJObj`
     - Parameters:
        - v: `Dictionary` [`String` : `AnyObject`]
        - path: path in original object
     - Returns: `JJArr`
     */
    public init(_ v: [String: AnyObject], path: String) {
        _v = v
        _path = path
    }
    /**
     - Parameter key: Key of element of `Dictionary`
     - Returns: `JJVal`
     */
    public func at(_ key: String) -> JJVal {
        let newPath = _path + ".\(key)"
        #if DEBUG
            if let msg = _v["$\(key)__depricated"] {
                debugPrint("WARNING:!!!!. Using depricated field \(newPath): \(msg)")
            }
        #endif
        return JJVal(_v[key], path: newPath)
    }
    /**
     - Parameter key: Key of element of `Dictionary`
     - Returns: `JJVal`
     */
    public subscript (key: String) -> JJVal { return at(key) }

    // MARK: extension point
    /** Raw value of [`String` : `AnyObject`] */
    public var raw: [String: AnyObject] { return _v }
    /** Path in original object */
    public var path: String { return _path }

    // Shortcusts
    /** `True` if object exist */
    public var exists: Bool { return true }
    /** The number of elements the `Dictionary` stores */
    public var count:Int { return _v.count }
    /**
     - Parameters:
     - space: space between parent elements of `Dictionary`
     - spacer: space to embedded values
     - Returns: A textual representation of [Dictionary]()
     */
    public func prettyPrint(space: String = "", spacer: String = "  ") -> String {
        if _v.count == 0 {
            return "{}"
        }
        var str = "{\n"
        for (k, v) in _v {
            let nextSpace = space + spacer
            str += "\(nextSpace)\"\(k)\": \(jj(v).prettyPrint(space: nextSpace, spacer: spacer)),\n"
        }
        str.remove(at: str.index(str.endIndex, offsetBy: -2))
        return str + "\(space)}"
    }
    /** A Textual representation of stored `Dictionary` */
    public var debugDescription: String { return prettyPrint() }
}
/**
 Struct like `JJObj` but raw value is optional
 */
public struct JJMaybeObj {
    private let _path: String
    private let _v: JJObj?

    public init(_ v: JJObj?, path: String) {
        _v = v
        _path = path
    }

    public func at(_ key: String) -> JJVal {
        return _v?.at(key) ?? JJVal(nil, path: _path + "<nil>.\(key)")
    }

    public subscript (key: String) -> JJVal { return at(key) }


    // MARK: extension point
    public var raw: [String: AnyObject]? { return _v?.raw }
    public var path: String { return _path }

    // MARK: shortcusts

    public var exists: Bool { return _v != nil }
}

public struct JJVal: CustomDebugStringConvertible {
    private let _path: String
    private let _v: AnyObject?

    public init(_ v: AnyObject?, path: String = "<root>") {
        _v = v
        _path = path
    }

    // MARK: Bool

    public var asBool: Bool? { return _v as? Bool }

    public func toBool(_ defaultValue:  @autoclosure() -> Bool = false) -> Bool {
        return asBool ?? defaultValue()
    }


    public func bool() throws -> Bool {
        if let x = _v as? Bool {
            return x
        }
        throw JJError.wrongType(v: _v, path: _path, toType: "Bool")
    }

    // MARK: Int

    public var asInt: Int? { return _v as? Int }

    public func toInt(_ defaultValue:  @autoclosure() -> Int = 0) -> Int {
        return asInt ?? defaultValue()
    }

    public func int() throws -> Int {
        if let x = asInt {
            return x
        }
        throw JJError.wrongType(v: _v, path: _path, toType: "Int")
    }

    // MARK: UInt

    public var asUInt: UInt? { return _v as? UInt }

    public func toUInt(_ defaultValue:  @autoclosure() -> UInt = 0) -> UInt {
        return asUInt ?? defaultValue()
    }

    public func uInt() throws -> UInt {
        if let x = asUInt {
            return x
        }
        throw JJError.wrongType(v: _v, path: _path, toType: "UInt")
    }

    // MARK: Number

    public var asNumber: NSNumber? { return _v as? NSNumber }

    public func toNumber(_ defaultValue:  @autoclosure() -> NSNumber = 0) -> NSNumber {
        return asNumber ?? defaultValue()
    }

    public func number() throws -> NSNumber {
        if let x = asNumber {
            return x
        }
        throw JJError.wrongType(v: _v, path: _path, toType: "Number")
    }

    // MARK: Float

    public var asFloat: Float? { return _v as? Float }

    public func toFloat(_ defaultValue:  @autoclosure() -> Float = 0) -> Float {
        return asFloat ?? defaultValue()
    }

    public func float() throws -> Float {
        if let x = asFloat {
            return x
        }
        throw JJError.wrongType(v: _v, path: _path,toType: "Float")
    }

    // MARK: Double

    public var asDouble: Double? { return _v as? Double }

    public func toDouble(_ defaultValue:  @autoclosure() -> Double = 0) -> Double {
        return asDouble ?? defaultValue()
    }

    public func double() throws -> Double {
        if let x = asDouble {
            return x
        }
        throw JJError.wrongType(v: _v, path: _path,toType: "Double")
    }


    // MARK: Object

    public var asObj: JJObj? {
        if let obj = _v as? [String: AnyObject] {
            return JJObj(obj, path: _path)
        }

        return nil
    }

    public func toObj() -> JJMaybeObj {
        return JJMaybeObj(asObj, path: _path)
    }

    public func obj() throws -> JJObj {
        if let obj = _v as? [String: AnyObject] {
            return JJObj(obj, path: _path)
        }

        throw JJError.wrongType( v: _v, path: _path, toType: "[String: AnyObject]")
    }

    // MARK: Array

    public var asArr: JJArr? {
        if let arr = _v as? [AnyObject] {
            return JJArr(arr, path: _path)
        }
        return nil
    }

    public func toArr() -> JJMaybeArr {
        return JJMaybeArr(asArr, path: _path)
    }

    public func arr() throws -> JJArr {
        guard let arr = _v as? [AnyObject] else {
            throw JJError.wrongType( v: _v, path: _path, toType: "[AnyObject]")
        }
        return JJArr(arr, path: _path)
    }

    // MARK: String

    public var asString: String? { return _v as? String }

    public func toString(_ defaultValue:  @autoclosure() -> String = "") -> String {
        return asString ?? defaultValue()
    }

    public func string() throws -> String {
        if let x = asString {
            return x
        }
        throw JJError.wrongType(v: _v, path: _path, toType: "String")
    }

    // MARK: Date

    public var asDate: Date? { return asString?.asRFC3339Date() }

    public func date() throws -> Date {
        if let d = asString?.asRFC3339Date() {
            return d
        } else {
            throw JJError.wrongType(v: _v, path: _path, toType: "Date")
        }
    }

    // MARK: URL

    public var asURL: URL? {
        if let s = asString, d = URL(string: s) {
            return d
        } else {
            return nil
        }
    }

    public func toURL(_ defaultValue:  @autoclosure() -> URL = URL(string: "")!) -> URL {
        return asURL ?? defaultValue()
    }

    public func url() throws -> URL {
        if let s = asString, d = URL(string: s) {
            return d
        } else {
            throw JJError.wrongType(v: _v, path: _path, toType: "URL")
        }
    }

    // MARK: Null

    public var isNull: Bool { return _v === NSNull() }


    // MARK: TimeZone

    public var asTimeZone: TimeZone? {
        if let s = asString, d = TimeZone(name: s) {
            return d
        } else {
            return nil
        }
    }

    // MARK: Navigation as Object

    public func at(_ key: String) -> JJVal {
        return toObj()[key]
    }

    public subscript (key: String) -> JJVal {
        return at(key)
    }

    // MARK: Navigation as Array

    public func at(_ index: Int) -> JJVal {
        return toArr()[index]
    }

    public subscript (index: Int) -> JJVal {
        return at(index)
    }

    public var exists: Bool { return _v != nil }

    // MARK: extension point

    public var path: String { return _path }
    public var raw: AnyObject? { return _v }

    // MARK: pretty print

    public func prettyPrint(space: String = "", spacer: String = "  ") -> String {
        if let arr = asArr {
            return arr.prettyPrint(space: space, spacer: spacer)
        } else if let obj = asObj {
            return obj.prettyPrint(space: space, spacer: spacer)
        } else if let s = asString {
            return "\"\(s)\""
        } else if isNull {
            return "null"
        } else if let v = _v {
            return v.description
        } else {
            return "nil"
        }
    }

    // MARK: CustomDebugStringConvertible

    public var debugDescription: String {
        return prettyPrint()
    }
}

public struct JJEnc {
    private let _enc: NSCoder

    public init(_ enc: NSCoder) {
        _enc = enc
    }

    public func put(int v:Int, at: String) {
        _enc.encode(Int32(v), forKey: at)
    }

    public func put(bool v:Bool, at: String) {
        _enc.encode(v, forKey: at)
    }

    public func put(_ v:AnyObject?, at: String) {
        _enc.encode(v, forKey: at)
    }
}

public struct JJDecVal {
    private let _key: String
    private let _dec: NSCoder

    public init(dec: NSCoder, key: String) {
        _key = key
        _dec = dec
    }

    public func string() throws -> String {
        let v = _dec.decodeObject(forKey: _key)
        if let x = v as? String {
            return x
        }
        throw JJError.wrongType(v: v, path: _key, toType: "String")
    }

    public var asString: String? { return _dec.decodeObject(forKey: _key) as? String }

    public func int() throws -> Int { return Int(_dec.decodeInt32(forKey: _key)) }

    public var asInt: Int? { return _dec.decodeObject(forKey: _key) as? Int }

    public var asDate: Date? { return _dec.decodeObject(forKey: _key) as? Date }

    public var asURL: URL? { return _dec.decodeObject(forKey: _key) as? URL }

    public var asTimeZone: TimeZone? { return _dec.decodeObject(forKey: _key) as? TimeZone }

    public func bool() throws -> Bool { return _dec.decodeBool(forKey: _key) }

    public func toBool() -> Bool { return _dec.decodeBool(forKey: _key) }

    public func decodeAs<T: NSCoding>() -> T? { return _dec.decodeObject(forKey: _key) as? T }
    
    public func decode<T: NSCoding>() throws -> T {
        let obj = _dec.decodeObject(forKey: _key)
        if let v:T = obj as? T {
            return v
        }
       
        // TODO: find a way to get type
        throw JJError.wrongType(v: obj, path: _key, toType: "T")
    }

    public func date() throws -> Date {
        let v = _dec.decodeObject(forKey: _key)
        if let x = v as? Date {
            return x
        }
        throw JJError.wrongType(v: v, path: _key, toType: "Date")
    }
    
    // extension point
    public var decoder: NSCoder { return _dec }
    public var key: String { return _key }
}

public struct JJDec {
    private let _dec: NSCoder

    public init(_ dec: NSCoder) {
        _dec = dec
    }

    public subscript (key: String) -> JJDecVal {
        return JJDecVal(dec: _dec, key: key)
    }
}
