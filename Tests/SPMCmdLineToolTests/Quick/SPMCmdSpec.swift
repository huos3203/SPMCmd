//
//  SPMCmdSpec.swift
//  iSPMCmd
//
//  Created by jhmac on 2020/6/10.
//  
//

import Quick
import Nimble

class SPMCmdSpec: QuickSpec {
    override func spec() {
        describe("测试功能") {
            beforeEach({
                //方法1:访问控制器的View，来触发控制器的.viewDidLoad()
                print("----first-----")
            })
            it("测试2") {
                print("222")
            }
            afterEach {
                print("----end-----")
            }
        }
    }
}
