 /* 
 Project.swift 

 Copyright (C) 2023, 2024 SparkleChan and SeanIsTethered 
 Copyright (C) 2024 fridakitten 

 This file is part of FridaCodeManager. 

 FridaCodeManager is free software: you can redistribute it and/or modify 
 it under the terms of the GNU General Public License as published by 
 the Free Software Foundation, either version 3 of the License, or 
 (at your option) any later version. 

 FridaCodeManager is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of 
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
 GNU General Public License for more details. 

 You should have received a copy of the GNU General Public License 
 along with FridaCodeManager. If not, see <https://www.gnu.org/licenses/>. 

  ______    _     _         _____        __ _                           ______                    _       _   _
 |  ___|  (_)   | |       /  ___|      / _| |                          |  ___|                  | |     | | (_)
 | |_ _ __ _  __| | __ _  \ `--.  ___ | |_| |___      ____ _ _ __ ___  | |_ ___  _   _ _ __   __| | __ _| |_ _  ___  _ __
 |  _| '__| |/ _` |/ _` |  `--. \/ _ \|  _| __\ \ /\ / / _` | '__/ _ \ |  _/ _ \| | | | '_ \ / _` |/ _` | __| |/ _ \| '_ \
 | | | |  | | (_| | (_| | /\__/ / (_) | | | |_ \ V  V / (_| | | |  __/ | || (_) | |_| | | | | (_| | (_| | |_| | (_) | | | |
 \_| |_|  |_|\__,_|\__,_| \____/ \___/|_|  \__| \_/\_/ \__,_|_|  \___| \_| \___/ \__,_|_| |_|\__,_|\__,_|\__|_|\___/|_| |_|
 Founded by. Sean Boleslawski, Benjamin Hornbeck and Lucienne Salim in 2023
 */ 
    
import Foundation

struct Project: Identifiable, Equatable {
    let id: UUID = UUID()
    var Name: String
    var BundleID: String
    var Version: String
    var ProjectPath: String
    var Executable: String
    var Macro: String
    var SDK: String
    var TG: String
    var TYPE: String

    static func == (lhs: Project, rhs: Project) -> Bool {
        return lhs.Name == rhs.Name &&
               lhs.BundleID == rhs.BundleID &&
               lhs.Version == rhs.Version &&
               lhs.ProjectPath == rhs.ProjectPath &&
               lhs.Executable == rhs.Executable &&
               lhs.Macro == rhs.Macro &&
               lhs.SDK == rhs.SDK &&
               lhs.TG == rhs.TG &&
               lhs.TYPE == rhs.TYPE
    }
}

func MakeApplicationProject(_ Name: String, _ BundleID: String, type: Int) -> Int {
    let mode: Int = UserDefaults.standard.integer(forKey: "tabmode")
    let spacing: Int = UserDefaults.standard.integer(forKey: "tabspacing")
    let spcstr: String = {
        if mode == 0 {
            return "\t"
        } else {
            return String(repeating: " ", count: spacing)
        }
    }()

    let v2uuid: UUID = UUID()
    let SDK: String = UserDefaults.standard.string(forKey: "sdk") ?? "iPhoneOS15.6.sdk"
    let TYPE: String = {
        switch type {
            case 1, 2, 3, 5:
                return "Applications"
            case 4:
                return "Utilities"
            case 6:
                return "Sean16"
            default:
                return "Applications"
        }
    }()

    do {
        let ResourcesPath = "\(global_documents)/\(v2uuid)/Resources"
        try FileManager.default.createDirectory(atPath: ResourcesPath, withIntermediateDirectories: true)

        let infoPlistData: [String: Any] = [
            "CFBundleExecutable": Name,
            "CFBundleIdentifier": BundleID,
            "CFBundleName": Name,
            "CFBundleShortVersionString": "1.0",
            "CFBundleVersion": "1.0",
            "MinimumOSVersion": gosver() ?? "15.0",
        ]

        let infoPlistPath = "\(ResourcesPath)/Info.plist"
        let infoPlistDataSerialized = try PropertyListSerialization.data(fromPropertyList: infoPlistData, format: .xml, options: 0)
        FileManager.default.createFile(atPath: infoPlistPath, contents: infoPlistDataSerialized, attributes: nil)

        let dontTouchMePlistData: [String: Any] = [
            "SDK": SDK,
            "TYPE": TYPE,
            "CMacro": "stable",
            "Macro": [
                "stable": [:] as [String: Any],
                "debug": [:] as [String: Any],
            ]
        ]

        let dontTouchMePlistPath = "\(ResourcesPath)/DontTouchMe.plist"
        let dontTouchMePlistDataSerialized = try PropertyListSerialization.data(fromPropertyList: dontTouchMePlistData, format: .xml, options: 0)
        FileManager.default.createFile(atPath: dontTouchMePlistPath, contents: dontTouchMePlistDataSerialized, attributes: nil)

        switch(type) {
            case 1: // Swift App
                FileManager.default.createFile(atPath: "\(global_documents)/\(v2uuid)/My App.swift", contents: Data("\(authorgen(file: "My App.swift"))import SwiftUI\n\n@main\nstruct MyApp: App {\n\(spcstr)var body: some Scene {\n\(spcstr)\(spcstr)WindowGroup {\n\(spcstr)\(spcstr)\(spcstr)ContentView()\n\(spcstr)\(spcstr)}\n\(spcstr)}\n}".utf8))
                FileManager.default.createFile(atPath: "\(global_documents)/\(v2uuid)/ContentView.swift", contents: Data("\(authorgen(file: "ContentView.swift"))import SwiftUI\n\nstruct ContentView: View {\n\(spcstr)var body: some View {\n\(spcstr)\(spcstr)Text(\"Hello, World!\")\n\(spcstr)}\n}".utf8))
                break
            case 2: // ObjC App
                FileManager.default.createFile(atPath: "\(global_documents)/\(v2uuid)/main.m", contents: Data("\(authorgen(file: "main.m"))#import <Foundation/Foundation.h>\n#import \"myAppDelegate.h\"\n\nint main(int argc, char *argv[]) {\n\(spcstr)@autoreleasepool {\n\(spcstr)\(spcstr)return UIApplicationMain(argc, argv, nil, NSStringFromClass(myAppDelegate.class));\n\(spcstr)}\n}".utf8))
                FileManager.default.createFile(atPath: "\(global_documents)/\(v2uuid)/myAppDelegate.h", contents: Data("\(authorgen(file: "myAppDelegate.h"))#import <UIKit/UIKit.h>\n \n@interface myAppDelegate : UIResponder <UIApplicationDelegate>\n \n@property (nonatomic, strong) UIWindow *window;\n@property (nonatomic, strong) UINavigationController *rootViewController;\n \n@end".utf8))
                FileManager.default.createFile(atPath: "\(global_documents)/\(v2uuid)/myAppDelegate.m", contents: Data("\(authorgen(file: "myAppDelegate.m"))#import \"myAppDelegate.h\"\n#import \"myRootViewController.h\"\n\n@implementation myAppDelegate\n\n- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {\n\(spcstr)_window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];\n\(spcstr)_rootViewController = [[UINavigationController alloc] initWithRootViewController:[[myRootViewController alloc] init]];\n\(spcstr)_window.rootViewController = _rootViewController;\n\(spcstr)[_window makeKeyAndVisible];\n\(spcstr)return YES;\n}\n\n@end".utf8))
                FileManager.default.createFile(atPath: "\(global_documents)/\(v2uuid)/myRootViewController.h", contents: Data("\(authorgen(file: "myRootViewController.h"))#import <UIKit/UIKit.h>\n \n@interface myRootViewController : UIViewController\n \n@end".utf8))
                FileManager.default.createFile(atPath: "\(global_documents)/\(v2uuid)/myRootViewController.m", contents: Data("\(authorgen(file: "myRootViewController.m"))#import \"myRootViewController.h\"\n@interface myRootViewController () <UITableViewDataSource>\n@property (nonatomic, strong) UITableView *logTableView;\n@property (nonatomic, strong) NSMutableArray *logEntries;\n@end\n\n@implementation myRootViewController\n- (void)viewDidLoad {\n\(spcstr)[super viewDidLoad];\n\(spcstr)self.title = @\"ObjectiveC support!\";\n\(spcstr)self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonTapped:)];\n\(spcstr)self.logTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];\n\(spcstr)self.logTableView.dataSource = self;\n\(spcstr)[self.view addSubview:self.logTableView];\n\(spcstr)self.logEntries = [NSMutableArray array];\n}\n- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {\n\(spcstr)return self.logEntries.count;\n}\n- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {\n\(spcstr)static NSString *CellIdentifier = @\"Cell\";\n\(spcstr)UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];\n\(spcstr)if (!cell) {\n\(spcstr)\(spcstr)cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];\n\(spcstr)}\n\(spcstr)cell.textLabel.text = self.logEntries[indexPath.row];\n\(spcstr)return cell;\n}\n- (void)addButtonTapped:(id)sender {\n\(spcstr)@try {\n\(spcstr)\(spcstr)NSString *logEntry = @\"Hello, World!\";\n\(spcstr)\(spcstr)[self.logEntries insertObject:logEntry atIndex:0];\n\(spcstr)\(spcstr)[self.logTableView reloadData];\n\(spcstr)} @catch (NSException *exception) {\n\(spcstr)\(spcstr)NSLog(@\"Exception: %@\", exception);\n\(spcstr)} @finally {\n\(spcstr)\(spcstr)NSLog(@\"Add button tapped\");\n\(spcstr)}\n}\n@end".utf8))
                break
            case 3: // Swift/ObjC App
                FileManager.default.createFile(atPath: "\(global_documents)/\(v2uuid)/My App.swift", contents: Data("\(authorgen(file: "My App.swift"))import SwiftUI\n\n@main\nstruct MyApp: App {\n\(spcstr)var body: some Scene {\n\(spcstr)\(spcstr)WindowGroup {\n\(spcstr)\(spcstr)\(spcstr)ContentView()\n\(spcstr)\(spcstr)}\n\(spcstr)}\n}".utf8))
                FileManager.default.createFile(atPath: "\(global_documents)/\(v2uuid)/ContentView.swift", contents: Data("\(authorgen(file: "ContentView.swift"))import Foundation\nimport SwiftUI\n\nstruct ContentView: View {\n\(spcstr)var body: some View {\n\(spcstr)\(spcstr)Text(hello())\n\(spcstr)}\n\(spcstr)func hello() -> String {\n\(spcstr)\(spcstr)let myObjCInstance = MyObjectiveCClass()\n\(spcstr)\(spcstr)return myObjCInstance.hello()\n\(spcstr)}\n}".utf8))
                FileManager.default.createFile(atPath:"\(global_documents)/\(v2uuid)/bridge.h", contents: Data("\(authorgen(file: "bridge.h"))#import \"main.h\"".utf8))
                FileManager.default.createFile(atPath: "\(global_documents)/\(v2uuid)/main.h", contents: Data("\(authorgen(file: "main.h"))#import <Foundation/Foundation.h>\n@interface MyObjectiveCClass : NSObject\n\n- (NSString *)hello;\n\n@end".utf8))
                FileManager.default.createFile(atPath: "\(global_documents)/\(v2uuid)/main.m", contents: Data("\(authorgen(file: "main.m"))#import \"main.h\"\n\n@implementation MyObjectiveCClass\n\n- (NSString *)hello {\n\(spcstr)return @\"Hello ObjectiveC World!\";\n}\n\n@end".utf8))
                break
            case 4: // C Binary
                FileManager.default.createFile(atPath: "\(global_documents)/\(v2uuid)/main.c", contents: Data("\(authorgen(file: "main.c"))#include <stdio.h>\n\nint main(void) {\n\(spcstr)printf(\"Hello, World\");\n}".utf8))
                break
            case 5: // Swift/C++ App
                FileManager.default.createFile(atPath: "\(global_documents)/\(v2uuid)/My App.swift", contents: Data("\(authorgen(file: "My App.swift"))import SwiftUI\n\n@main\nstruct MyApp: App {\n\(spcstr)var body: some Scene {\(spcstr)\(spcstr)WindowGroup {\n\(spcstr)\(spcstr)\(spcstr)ContentView()\n\(spcstr)\(spcstr)}\n\(spcstr)}\n}".utf8))
                FileManager.default.createFile(atPath: "\(global_documents)/\(v2uuid)/ContentView.swift", contents: Data("\(authorgen(file: "ContentView.swift"))import Foundation\nimport SwiftUI\n\nstruct ContentView: View {\n\(spcstr)var body: some View {\n\(spcstr)\(spcstr)Button(\"Test\") {\n\(spcstr)\(spcstr)\(spcstr)test()\n\(spcstr)\(spcstr)}\n\(spcstr)}\n}".utf8))
                FileManager.default.createFile(atPath:"\(global_documents)/\(v2uuid)/bridge.h", contents: Data("\(authorgen(file: "bridge.h"))int test();".utf8))
                FileManager.default.createFile(atPath: "\(global_documents)/\(v2uuid)/main.cpp", contents: Data("\(authorgen(file: "main.cpp"))#include <iostream>\n\nextern \"C\" {\n\nint test() {\n\(spcstr)std::cout << \"Hello, World!\" << std::endl;\n\(spcstr)return 0;\n}\n\n}".utf8))
                FileManager.default.createFile(atPath: "\(global_documents)/\(v2uuid)/api.api", contents: Data("<api>\n\(spcstr)<version>1.1</version>\n\(spcstr)<build>-lc -lc++</build>\n</api>".utf8))
                break
            default:
                return 2
        }

        var entitlementsPlistData: [String: Any] = [ "platform-application": true ]
        if type == 4 {
            entitlementsPlistData = [
                "platform-application": true,
                "com.apple.private.security.no-sandbox": true
            ]
        }

        let entitlementsPlistPath = "\(global_documents)/\(v2uuid)/entitlements.plist"
        let entitlementsPlistDataSerialized = try PropertyListSerialization.data(fromPropertyList: entitlementsPlistData, format: .xml, options: 0)
        FileManager.default.createFile(atPath: entitlementsPlistPath, contents: entitlementsPlistDataSerialized, attributes: nil)
    } catch {
        print(error)
        return 1
    }

    return 0
}

func authorgen(file: String) -> String {
    let author = UserDefaults.standard.string(forKey: "Author")
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd.MM.yy"
    let currentDate = Date()
    return "//\n// \(file)\n//\n// Created by \(author ?? "Anonym") on \(dateFormatter.string(from: currentDate))\n//\n \n"
}

func importProj(target: String) -> Void {
    let v2uuid: String = "\(UUID())"

    if FileManager.default.fileExists(atPath: target) {
        if libzip_unzip(target, "\(global_container)/tmp/\(v2uuid)") != 0 {
            return
        }
    } else {
        return
    }
    cfolder(atPath: "\(global_container)/tmp/\(v2uuid)")
    let content: [URL] = try! FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: "\(global_documents)/../tmp/\(v2uuid)"), includingPropertiesForKeys: nil)
    let projpath: String = content[0].path
    _ =  mv("\(projpath)", "\(global_documents)/\(v2uuid)")
    _ = rm("\(global_container)/tmp/\(v2uuid)")
}
