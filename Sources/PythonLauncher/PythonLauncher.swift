// The Swift Programming Language
// https://docs.swift.org/swift-book


import Foundation
import PathKit
import PySwiftKit
import PySwiftObject


public protocol PyLauncher: AnyObject {
    
    static var shared: Self { get }
    
    var PYTHON_VERSION: String { get }
    
    //var program: String? { get }
    
    //var python_library: Path { get }
    
    //var site_packages: Path { get }
    
    //var other_site_packages: [Path] { get }
    
    static var pyswiftImports: [PySwiftModuleImport] { get }
    
    var env: PyEnvironment { get }
    func initPython() throws
    func preLaunch() throws
    func onLaunch() throws -> Int32 
    func onExit() throws
    
}


extension PyLauncher {
    
    public static func run(_ argc: Int32, _ argv: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>) {
        let cls = Self.shared
        do {
            try cls.preLaunch()
            try cls.initPython()
            try cls.onLaunch()
            try cls.onExit()
        } catch let py_err as PyException {
            print(py_err.localizedDescription)
        } catch let other_err {
            print(other_err.localizedDescription)
        }
    }
    
}
