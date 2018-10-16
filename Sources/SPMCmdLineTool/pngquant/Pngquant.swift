//
//  pngquant.swift
//  CommandLineTool
//
//  Created by admin on 2018/10/15.
//  Copyright © 2018年 clcw. All rights reserved.
//

import Foundation
import FilesProvider
func LocalFile(path:String) {
    let documentsProvider = LocalFileProvider()
    documentsProvider.contentsOfDirectory(path: "/", completionHandler: { contents, error in
        for file in contents {
            print("Name: \(file.name)")
            print("Size: \(file.size)")
            print("Creation Date: \(file.creationDate)")
            print("Modification Date: \(file.modifiedDate)")
        }
    })
}

