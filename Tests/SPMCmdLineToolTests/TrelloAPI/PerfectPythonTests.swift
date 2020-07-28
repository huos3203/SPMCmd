//
//  PerfectPythonTests.swift
//  Perfect-Python
//
//  Created by Rockford Wei on 2017-08-18.
//  Copyright © 2017 PerfectlySoft. All rights reserved.
//
//===----------------------------------------------------------------------===//
//
// This source file is part of the Perfect.org open source project
//
// Copyright (c) 2017 - 2018 PerfectlySoft Inc. and the Perfect project authors
// Licensed under Apache License v2.0
//
// See http://perfect.org/licensing.html for license information
//
//===----------------------------------------------------------------------===//
//
import XCTest
@testable import PythonAPI
@testable import PerfectPython


class PerfectPythonTests: XCTestCase {

  static var allTests = [
    ("testLastError", testLastError),
    ("testFile", testFile),
    ("testCallback", testCallback),
    ("testExample", testExample),
    ("testVersion", testVersion),
    ("testBasic", testBasic),
    ("testBasic2", testBasic2),
    ("testClass", testClass),
    ("testClass2", testClass2)
  ]

  func writeScript(path: String, content: String) {
    guard let f = fopen(path, "w") else {
      XCTFail("\(path) is invalid")
      return
    }
    _ = content.withCString { pstring in
      fwrite(pstring, 1, content.count, f)
    }
    fclose(f)
  }

  override func setUp() {
    Py_Initialize()
    var program = """
class Person:
                    def __init__(self, name, age):
                        self.name = name
                        self.age = age
                    def intro(self):
                        return 'Name: ' + self.name + ', Age: ' + str(self.age)
                  """
    var path = "/tmp/clstest.py"
    writeScript(path: path, content: program)
    program = """
    def mymul(num1, num2):
                    return num1 * num2;
                def mydouble(num):
                    return num * 2;
                    stringVar = 'Hello, world'
                listVar = ['rocky', 505, 2.23, 'wei', 70.2]
                dictVar = {'Name': 'Rocky', 'Age': 17, 'Class': 'Top'};
             """
    path = "/tmp/helloworld.py"
    writeScript(path: path, content: program)
  }

  override func tearDown() {
    //Py_Finalize()
    unlink("/tmp/clstest.py")
    unlink("/tmp/clstest.pyc")
    unlink("/tmp/helloworld.py")
    unlink("/tmp/helloworld.pyc")
  }

  func testExample() {
    let p = PyObject()
    print(p)
  }

  func testFile() {
    do {
      let f = try PyObj.init(value: stdin)
      if let f2 = f.value as? UnsafeMutablePointer<FILE>,
        let g = stdin.python(),
        let h = UnsafeMutablePointer<FILE>(python: g) {
        XCTAssertEqual(stdin, f2)
        XCTAssertEqual(h, f2)
      } else {
        XCTFail("STDOUT PYTHONIZATION FAILURE")
      }
    }catch {
      XCTFail(error.localizedDescription)
    }
  }
  func testLastError() {
    do {
      let _ = try PyObj(path: "/nowhere", import: "inexisting")
    } catch PyObj.Exception.Throw(let msg) {
      print("Trapped an expected error:", msg)
    } catch {
      XCTFail(error.localizedDescription)
    }
  }

  func testVersion() {
    if let v = PyObj.Version {
      XCTAssertTrue(v.hasPrefix("2.7"))
    } else {
      XCTFail("version checking failed")
    }
  }

  func testClass2() {
    do {
      let pymod = try PyObj(path: "/tmp", import: "clstest")
      if let personClass = pymod.load("Person"),
        let person = personClass.construct(["rocky", 24]),
        let name = person.load("name")?.value as? String,
        let age = person.load("age")?.value as? Int {
        print("loaded with: ", name, age)
        let intro = try person.call("intro")?.value as? String ?? "missing"
        XCTAssertEqual(name, "rocky")
        XCTAssertEqual(age, 24)
        XCTAssertNotEqual(intro, "missing")
      }
    }catch {
      XCTFail("\(error)")
    }
  }

  func testClass() {
    PySys_SetPath(UnsafeMutablePointer<Int8>(mutating: "/tmp"))
    if let module = PyImport_ImportModule("clstest"),
      let personClass = PyObject_GetAttrString(module, "Person"),
      let args = PyTuple_New(2),
      let name = PyString_FromString("Rocky"),
      let age = PyInt_FromLong(24),
      PyTuple_SetItem(args, 0, name) == 0,
      PyTuple_SetItem(args, 1, age) == 0,
      let personObj = PyInstance_New(personClass, args, nil),
      let introFunc = PyObject_GetAttrString(personObj, "intro"),
      let introRes = PyObject_CallObject(introFunc, nil),
      let intro = PyString_AsString(introRes)
    {
      print(String(cString: intro))
      Py_DecRef(personObj)
      Py_DecRef(introFunc)
      Py_DecRef(introRes)
      Py_DecRef(args)
      Py_DecRef(name)
      Py_DecRef(age)
      Py_DecRef(personClass)
      Py_DecRef(module)
    } else {
      XCTFail("class variable failed")
    }
  }

  func testBasic2() {
    let program = "def mymul(num1, num2):\n\treturn num1 * num2;\n\nstringVar = 'Hello, world'\nlistVar = ['rocky', 505, 2.23, 'wei', 70.2]\ndictVar = {'Name': 'Rocky', 'Age': 17, 'Class': 'Top'};\n"
    let path = "/tmp/hola.py"
    writeScript(path: path, content: program)
    do {
      let pymod = try PyObj(path: "/tmp", import: "hola")
      if let res = try pymod.call("mymul", args: [2,3]),
        let ires = res.value as? Int {
        XCTAssertEqual(ires, 6)
      } else {
        XCTFail("function call failure")
      }
      let testString = "Hola, 🇨🇳🇨🇦"
      if let str = pymod.load("stringVar") {
        do {
          XCTAssertEqual(str.value as? String ?? "failed", "Hello, world")
          try pymod.save("stringVar", newValue: testString)
        }catch{
          XCTFail(error.localizedDescription)
        }
      } else {
        XCTFail("string call failure")
      }
      if let str2 = pymod.load("stringVar") {
        XCTAssertEqual(str2.value as? String ?? "failed", testString)
      } else {
        XCTFail("string call failure")
      }
      if let listObj = pymod.load("listVar"),
        let list = listObj.value as? [Any] {
        XCTAssertEqual(list.count, 5)
        print(list)
      } else {
        XCTFail("loading list failure")
      }
      if let dictObj = pymod.load("dictVar"),
        let dict = dictObj.value as? [String:Any] {
        XCTAssertEqual(dict.count, 3)
        print(dict)
      }
    }catch {
      XCTFail(error.localizedDescription)
    }

  }

  func testBasic() {
    PySys_SetPath(UnsafeMutablePointer<Int8>(mutating: "/tmp"))
    if let module = PyImport_ImportModule("helloworld"),
      let function = PyObject_GetAttrString(module, "mydouble"),
      let num = PyInt_FromLong(2),
      let args = PyTuple_New(1),
      PyTuple_SetItem(args, 0, num) == 0,
      let res = PyObject_CallObject(function, args) {
      let four = PyInt_AsLong(res)
      XCTAssertEqual(four, 4)
      if let strObj = PyObject_GetAttrString(module, "stringVar"),
        let pstr = PyString_AsString(strObj) {
        let strvar = String(cString: pstr)
        print(strvar)
        Py_DecRef(function)
        Py_DecRef(args)
        Py_DecRef(num)
        Py_DecRef(res)
        Py_DecRef(strObj)
      } else {
        XCTFail("string variable failed")
      }
      if let listObj = PyObject_GetAttrString(module, "listVar") {
        XCTAssertEqual(String(cString: listObj.pointee.ob_type.pointee.tp_name), "list")
        let size = PyList_Size(listObj)
        XCTAssertEqual(size, 5)
        for i in 0 ..< size {
          if let item = PyList_GetItem(listObj, i) {
            let j = item.pointee
            let tpName = String(cString: j.ob_type.pointee.tp_name)
            let v: Any?
            switch tpName {
            case "str":
              v = String(cString: PyString_AsString(item))
              break
            case "int":
              v = PyInt_AsLong(item)
            case "float":
              v = PyFloat_AsDouble(item)
            default:
              v = nil
            }
            if let v = v {
              print(i, tpName, v)
            } else {
              print(i, tpName, "Unknown")
            }
            Py_DecRef(item)
          }
        }
        Py_DecRef(listObj)
      } else {
        XCTFail("list variable failed")
      }

      if let dicObj = PyObject_GetAttrString(module, "dictVar"),
        let keys = PyDict_Keys(dicObj) {
        XCTAssertEqual(String(cString: dicObj.pointee.ob_type.pointee.tp_name), "dict")
        let size = PyDict_Size(dicObj)
        XCTAssertEqual(size, 3)
        for i in 0 ..< size {
          guard let key = PyList_GetItem(keys, i),
            let item = PyDict_GetItem(dicObj, key) else {
              continue
          }
          let keyName = String(cString: PyString_AsString(key))
          let j = item.pointee
          let tpName = String(cString: j.ob_type.pointee.tp_name)
          let v: Any?
          switch tpName {
          case "str":
            v = String(cString: PyString_AsString(item))
            break
          case "int":
            v = PyInt_AsLong(item)
          case "float":
            v = PyFloat_AsDouble(item)
          default:
            v = nil
          }
          if let v = v {
            print(keyName, tpName, v)
          } else {
            print(keyName, tpName, "Unknown")
          }
          Py_DecRef(item)
        }
        Py_DecRef(keys)
        Py_DecRef(dicObj)
      } else {
        XCTFail("dictionary variable failed")
      }
      Py_DecRef(module)
    } else {
      XCTFail("library import failed")
    }
  }

  func testCallback() {
    let program = "def callback(msg):\n\treturn 'callback: ' + msg\ndef caller(info, func):\n\treturn func(info)"
    let path = "/tmp/callback.py"
    writeScript(path: path, content: program)
    do {
      let pymod = try PyObj(path: "/tmp", import: "callback")
      if let funSource = pymod.load("callback") {
        if let result = try pymod.call("caller", args: ["Hello", funSource]),
          let v = result.value as? String {
          print("callback result:", v)
        } else {
          print("callback failure")
        }
      } else {
        XCTFail("callback not found")
      }
    }catch {
      XCTFail(error.localizedDescription)
    }
  }
}
