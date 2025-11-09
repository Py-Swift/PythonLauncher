//
//  PyLauncherIsolated.swift
//  PythonLauncher
//
import Foundation
import PathKit
import PySwiftKit
//import PySwiftObject
import PySerializing

public protocol PyLauncherIsolated: PyLauncher {
    
}

func PyStatus_Exception(_ status: PyStatus) -> Bool {
    PyStatus_Exception(status) == 1
}

extension PyStatus {
    var error: String {
        .init(cString: err_msg)
    }
}

extension PyLauncherIsolated {
    
    
    
    private func pySwiftImports() {
        // add PySwiftMpdules to Python's import list
        for _import in Self.pyswiftImports {
            #if DEBUG
            print("Importing PySwiftModule:",String(cString: _import.name))
            #endif
            if PyImport_AppendInittab(_import.name, _import.module) == -1 {
                PyErr_Print()
                fatalError()
            }
        }
    }
    
    public func initPython() throws {
        
        let resourcePath = Bundle.main.resourcePath!//.replacingOccurrences(of: " ", with: "\\ ")
        
        var preconfig = PyPreConfig()
        var config = PyConfig()
        
        var wtmp_str: UnsafeMutablePointer<wchar_t>?
        var app_packages_path_str: UnsafeMutablePointer<wchar_t>?
        //var app_module_name: String
        //var app_module_str: UnsafeMutablePointer<CChar>?
        
        //var app_module: PyPointer?
        
        var status: PyStatus
        
        print("Configuring isolated Python...")
        PyPreConfig_InitIsolatedConfig(&preconfig)
        PyConfig_InitIsolatedConfig(&config)
        
        preconfig.utf8_mode = 1
        
        config.buffered_stdio = 0
        
        config.write_bytecode = 0
        
        config.module_search_paths_set = 1
        
        setenv("LC_CTYPE", "UTF-8", 1)
        
        print("Pre-initializing Python runtime...")
        status = Py_PreInitialize(&preconfig)
        if PyStatus_Exception(status) {
            crash_dialog("Unable to pre-initialize Python interpreter: \(status.error)")
            PyConfig_Clear(&config)
            Py_ExitStatusException(status)
        }
        
        
        let python_tag = "3.13"
        let python_home = "\(resourcePath)/python"
        print(python_home, FileManager.default.fileExists(atPath: python_home))
        print("PythonHome: \(python_home)")
        wtmp_str = Py_DecodeLocale(python_home, nil)
        var config_home = config.home
        status = PyConfig_SetString(&config, &config_home, wtmp_str)
        config.home = config_home
        if PyStatus_Exception(status) {
            crash_dialog("Unable to set PYTHONHOME: \(status.error)")
            PyConfig_Clear(&config)
            Py_ExitStatusException(status)
        }
        PyMem_RawFree(wtmp_str)
        
//        guard let app_module_name = Bundle.main.object(forInfoDictionaryKey: "MainModule") as? String else {
//            fatalError("Unable to identify app module name.")
//        }
//        app_module_name.withCString { name in
//            var run_module = config.run_module
//            status = PyConfig_SetBytesString(&config, &run_module, name)
//            config.run_module = run_module
//        }
//        if PyStatus_Exception(status) {
//            crash_dialog("Unable to set app module name: \(status.error)")
//            PyConfig_Clear(&config)
//            Py_ExitStatusException(status)
//        }
        
        status = PyConfig_Read(&config)
        if PyStatus_Exception(status) {
            crash_dialog("Unable to read site config: \(status.error)")
            PyConfig_Clear(&config)
            Py_ExitStatusException(status)
        }
        
        print("PYTHONPATH:")
        var path = "\(python_home)/lib/python\(python_tag)"
        print(" - \(path)")
        wtmp_str = Py_DecodeLocale(path, nil)
        status = PyWideStringList_Append(&config.module_search_paths, wtmp_str)
        if PyStatus_Exception(status) {
            crash_dialog("Unable to set PYTHONHOME: \(status.error)")
            PyConfig_Clear(&config)
            Py_ExitStatusException(status)
        }
        PyMem_RawFree(wtmp_str)
        
        path = "\(python_home)/lib/python\(python_tag)/lib-dynload"
        print(" - \(path)")
        wtmp_str = Py_DecodeLocale(path, nil)
        status = PyWideStringList_Append(&config.module_search_paths, wtmp_str)
        if PyStatus_Exception(status) {
            crash_dialog("Unable to set PYTHONHOME: \(status.error)")
            PyConfig_Clear(&config)
            Py_ExitStatusException(status)
        }
        PyMem_RawFree(wtmp_str)
        
        path = "\(resourcePath)/app"
        print(" - \(path)")
        wtmp_str = Py_DecodeLocale(path, nil)
        status = PyWideStringList_Append(&config.module_search_paths, wtmp_str)
        if PyStatus_Exception(status) {
            crash_dialog("Unable to set app path: \(status.error)")
            PyConfig_Clear(&config)
            Py_ExitStatusException(status)
        }
        PyMem_RawFree(wtmp_str)
        
        pySwiftImports()
        
        print("Initializing Python runtime...")
        status = Py_InitializeFromConfig(&config)
        if PyStatus_Exception(status) {
            crash_dialog("Unable to initialize Python interpreter: \(status.error)")
            PyConfig_Clear(&config)
            Py_ExitStatusException(status)
        }
        
        path = "\(resourcePath)/site_packages"
        app_packages_path_str = Py_DecodeLocale(path, nil)
        print("Adding app_packages as site directory: \(path)")
        
        guard let module = PyImport_ImportModule("site") else {
            crash_dialog("Could not import site module")
            exit(-11)
        }
        
        guard let module_attr = PyObject_GetAttrString(module, "addsitedir"), PyCallable_Check(module_attr) == 1 else {
            crash_dialog("Could not access site.addsitedir")
            exit(-12)
        }
        
        guard let app_packages_path = PyUnicode_FromWideChar(app_packages_path_str, wcslen(app_packages_path_str)) else {
            crash_dialog("Could not convert app_packages path to unicode")
            exit(-13)
        }
        PyMem_RawFree(app_packages_path_str)
        
        try? PythonCall(call: module_attr, app_packages_path)
        
        if let err = PyErr_Occurred() {
            crash_dialog("Could not add app_packages directory using site.addsitedir")
            exit(-15)
        }
        
        
        
        print("---------------------------------------------------------------------------")
    //    var ret: Int32 = 0
    //    //try? PythonCall(call: module_attr, app_module, 0)
    //    on_launch()
    //    Py_Finalize()
    //
    //    exit(ret)
        //PyEval_SaveThread()
    }
}



func crash_dialog(_ details: String) {
    print("Application has crashed!")
    print("========================\n\(details)")
}


fileprivate func PythonCall<A>(call: PyPointer, _ a: A) throws where
    A: PySerialize {
    let arg = a.pyPointer()
    guard let result = PyObject_CallOneArg(call, arg) else {
        PyErr_Print()
        Py_DecRef(arg)
        throw PyStandardException.typeError
    }
    Py_DecRef(arg)
    Py_DecRef(result)
}

fileprivate func PythonCall<A, B>(call: PyPointer, _ a: A, _ b: B) throws where
    A: PySerialize,
    B: PySerialize {
    let args = VectorCallArgs.allocate(capacity: 2)
    args[0] = a.pyPointer()
    args[1] = b.pyPointer()
    guard let result = PyObject_Vectorcall(call, args, 2, nil) else {
        PyErr_Print()
        Py_DecRef(args[0])
        Py_DecRef(args[1])
        args.deallocate()
        throw PyStandardException.typeError
    }
    Py_DecRef(args[0])
    Py_DecRef(args[1])
    args.deallocate()
    Py_DecRef(result)
}
