import Foundation

class MacroManager {
    private var plistData: [String: Any] = [:]
    var plistPath: String = ""
    
    func getCurrentMacro() -> String? {
        return plistData["CMacro"] as? String
    }

    func setCurrentMacro(to newMacro: String) {
        plistData["CMacro"] = newMacro
    }
    
    func getAllMacros() -> [String] {
        guard let macroDict = plistData["Macro"] as? [String: Any] else {
            return []
        }
        return Array(macroDict.keys)
    }
    
    func addMacro(_ macroName: String) {
        var macroDict = plistData["Macro"] as? [String: Any] ?? [:]
        macroDict[macroName] = [:] as [String: Any]
        plistData["Macro"] = macroDict
    }

    func removeMacro(_ macroName: String) {
        var macroDict = plistData["Macro"] as? [String: Any] ?? [:]
        macroDict.removeValue(forKey: macroName)
        plistData["Macro"] = macroDict
    }
    
    func loadPlist() {
        do {
            let plistData = try Data(contentsOf: URL(fileURLWithPath: plistPath))
            if let plistDictionary = try PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] {
                self.plistData = plistDictionary
            }
        } catch {
        }
    }

    func savePlist() {
        if let plistURL = URL(string: "file://\(plistPath)") {
            do {
                let plistData = try PropertyListSerialization.data(fromPropertyList: self.plistData, format: .xml, options: 0)
                try plistData.write(to: plistURL)
                print("Plist saved successfully to Documents directory.")
            } catch {
                print("Error saving plist: \(error)")
            }
        }
    }
}
