import SwiftUI
import Foundation

struct SDKDownload: View {
    @State private var sdks: [String] = ["9.3","10.3","11.4","12.4","13.7","14.5","15.6","16.5"]
    @State private var listid: UUID = UUID()
    var body: some View {
        List {
            ForEach(sdks, id:\.self) { item in
                if !FileManager.default.fileExists(atPath: "\(global_sdkpath)/iPhoneOS\(item).sdk") {
                    Button( action: {
                        download(item)
                    }) {
                        Label("iOS \(item)", systemImage: "arrow.down")
                    }
                } else {
                    Button( action: {
                        remove(item)
                    }) {
                        Label("iOS \(item)", systemImage: "trash.fill")
                    }
                }
            }
        }
        .navigationTitle("SDK Hub")
        .navigationBarTitleDisplayMode(.inline)
        .id(listid)
    }

    private func download(_ sdk: String) -> Void {
        DispatchQueue.global(qos: .utility).async {
            ShowAlert(UIAlertController(title: "Downloading SDK", message: "", preferredStyle: .alert))
            cfolder(atPath: "\(global_sdkpath)")
            fdownload("https://raw.githubusercontent.com/fridakitten/FridaCodeManager/main/FCM/UI/TabBar/Settings/SDKHub/sdk/iOS\(sdk).zip", "tmp/sdk.zip")
            if libzip_unzip("\(global_container)/tmp/sdk.zip","\(global_sdkpath)") != 0 {
                // back then we did ran download tasks unnecessarily as root
                #if jailbreak
                shell("chown mobile \(global_sdkpath)", uid: 0)
                #elseif trollstore
                shell("chown mobile:mobile \(global_sdkpath)", uid: 0)
                #endif
                libzip_unzip("\(global_container)/tmp/sdk.zip","\(global_sdkpath)")
            }
            _ = rm("\(global_container)/tmp/sdk.zip")
            listid = UUID()
            DismissAlert()
        }
    }

    private func remove(_ sdk: String) -> Void {
        DispatchQueue.global(qos: .utility).async {
            ShowAlert(UIAlertController(title: "Removing SDK", message: "", preferredStyle: .alert))
            // some people might have downloaded SDKs in the past that got unnecessarily stored as root
            if rm("\(global_sdkpath)/iPhoneOS\(sdk).sdk") != 0 {
                #if !stock
                shell("rm -rf \(global_sdkpath)/iPhoneOS\(sdk).sdk", uid: 0)
                #endif
            }
            listid = UUID()
            DismissAlert()
        }
    }
}
