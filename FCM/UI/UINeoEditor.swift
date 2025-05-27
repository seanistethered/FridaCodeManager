/*
UINeoEditor.swift

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

struct NeoEditorHelper: View {
    @Binding var isPresented: Bool
    @Binding var filepath: String
    @State var ready: Bool = false

    var project: Project
    var body: some View {
        Group {
            if ready {
                NavigationBarViewControllerRepresentable(isPresented: $isPresented, filepath: filepath, project: project)
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .onAppear {
            ready = true
        }
    }
}

// MARK: Code Editor
import SwiftUI
import UIKit
import Foundation

// caches for toolbar v2
var highlightLayerCache: [CAShapeLayer] = []
var toolbarItemCache: [UIBarButtonItem] = []

// configuration for NeoEditor
struct NeoEditorConfig {
    var background: UIColor
    var selection: UIColor
    var current: UIColor
    var standard: UIColor
    var font: UIFont
}

// restore class
struct NavigationBarViewControllerRepresentable: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var filepath: String
    var project: Project

    var title: String
    var backgroundColor: UIColor = UIColor.systemGray6
    var tintColor: UIColor = UIColor.label

    let textView: CustomTextView = CustomTextView()

    private var filename: String
    private let config: NeoEditorConfig = {
        let userInterfaceStyle = UIScreen.main.traitCollection.userInterfaceStyle

        var meow: NeoEditorConfig = NeoEditorConfig(background: UIColor.clear, selection: UIColor.clear, current: UIColor.clear, standard: UIColor.clear, font: UIFont.systemFont(ofSize: 10.0))

        meow.font = UIFont.monospacedSystemFont(ofSize: CGFloat(UserDefaults.standard.double(forKey: "CEFontSize")), weight: UIFont.Weight.medium)

        if userInterfaceStyle == .light {
            meow.background = light_background
            meow.selection = light_selection
            meow.current = light_current
            meow.standard = light_standard
        } else {
            meow.background = dark_background
            meow.selection = dark_selection
            meow.current = dark_current
            meow.standard = dark_standard
        }

        return meow
    }()

    init(
        isPresented: Binding<Bool>,
        filepath: String,
        project: Project
    ) {
        _isPresented = isPresented
        self.filepath = filepath
        self.project = project
        self.filename = {
            let fileURL = URL(fileURLWithPath: filepath)
            return fileURL.lastPathComponent
        }()
        self.title = filename
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        let hostingController = UIHostingController(rootView: NeoEditor(isPresented: $isPresented, filepath: filepath, project: project, textView: textView, config: config))
        hostingController.view.backgroundColor = config.background
        let navigationController = UINavigationController(rootViewController: hostingController)
        let navigationBar = navigationController.navigationBar
        navigationBar.prefersLargeTitles = false
        navigationBar.backgroundColor = backgroundColor
        navigationBar.tintColor = tintColor

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = backgroundColor
        appearance.titleTextAttributes = [.foregroundColor: tintColor]
        appearance.largeTitleTextAttributes = [.foregroundColor: tintColor]

        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance

        let saveButton = ClosureBarButtonItem(title: "Save", style: .plain) {
            textView.endEditing(true)
            let fileURL = URL(fileURLWithPath: filepath)
            do {
                try textView.text.write(to: fileURL, atomically: true, encoding: .utf8)
            } catch {
            }
        }

        let closeButton = ClosureBarButtonItem(title: "Close", style: .plain) {
            textView.endEditing(true)
            isPresented = false
        }

        hostingController.navigationItem.rightBarButtonItem = saveButton
        hostingController.navigationItem.leftBarButtonItem = closeButton

        return navigationController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        uiViewController.navigationBar.topItem?.title = title
        uiViewController.navigationBar.backgroundColor = backgroundColor
        uiViewController.navigationBar.tintColor = tintColor
    }
}

struct NeoEditor: UIViewRepresentable {
    private let containerView: UIView
    private let textView: CustomTextView
    private let highlightRules: [HighlightRule]
    private let filepath: String
    private let filename: String
    private let toolbar: UIToolbar

    private let config: NeoEditorConfig

    @Binding private var sheet: Bool
    private var project: Project

    @AppStorage("CERender") var render: Double = 1.0
    @AppStorage("CEFontSize") var font: Double = 13.0
    @AppStorage("CEToolbar") var enableToolbar: Bool = true
    @AppStorage("CECurrentLineHighlighting") var current_line_highlighting: Bool = false
    @AppStorage("CETypechecking") var dotypecheck: Bool = false

    init(
        isPresented: Binding<Bool>,
        filepath: String,
        project: Project,
        textView: CustomTextView,
        config: NeoEditorConfig
    ) {
        _sheet = isPresented

        self.filepath = filepath
        self.filename = {
            let fileURL = URL(fileURLWithPath: filepath)
            return fileURL.lastPathComponent
        }()

        self.highlightRules = grule(gsuffix(from: filename))
        self.containerView = UIView()
        self.textView = textView
        self.project = project
        self.toolbar = UIToolbar()
        self.config = config
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIView {
       textView.text = {
            do {
                return try String(contentsOfFile: filepath)
            } catch {
                sheet = false
                return ""
            }
        }()
        textView.delegate = context.coordinator
        context.coordinator.applyHighlighting(to: textView, with: NSRange(location: 0, length: textView.text.utf16.count))
        context.coordinator.runIntrospect(textView)

        textView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: containerView.topAnchor),
            textView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        textView.backgroundColor = config.background
        textView.tintColor = config.selection
        textView.textColor = config.standard
        textView.lineLight = config.current.cgColor
        if current_line_highlighting && !isPad {
            textView.setupHighlightLayer()
        }
        textView.keyboardType = .asciiCapable
        textView.textContentType = .none
        textView.smartQuotesType = .no
        textView.smartDashesType = .no
        textView.smartInsertDeleteType = .no
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.layoutManager.allowsNonContiguousLayout = true
        textView.layer.shouldRasterize = true
        textView.layer.rasterizationScale = UIScreen.main.scale * CGFloat(render)
        textView.isUserInteractionEnabled = true
        textView.layoutManager.addTextContainer(textView.textContainer)
        textView.layoutManager.ensureLayout(for: textView.textContainer)

        /*var claimed: [Int] = []

        if dotypecheck {
            textView.setLayoutCompletionHandler {
                let errorcache = errorcache
                for item in errorcache {
                    if !claimed.contains(item.line) {
                        if item.file == filepath {
                            switch item.level {
                                case 0:
                                    textView.highlightLine(at: item.line - 1, with: UIColor.systemBlue, with: item.description, with: "info.circle.fill")
                                    claimed.append(item.line)
                                    break
                                case 1:
                                    textView.highlightLine(at: item.line - 1, with: UIColor.systemYellow, with: item.description, with: "exclamationmark.triangle.fill")
                                    claimed.append(item.line)
                                    break
                                case 2:
                                    textView.highlightLine(at: item.line - 1, with: UIColor.systemRed, with: item.description, with: "xmark.circle.fill")
                                    claimed.append(item.line)
                                    break
                                default:
                                    break
                            }
                        }
                    }
                }
            }
        }*/

        if enableToolbar {
            setupToolbar(textView: textView)
        }

        return containerView
    }

    func setupToolbar(textView: UITextView) {
        toolbar.sizeToFit()

        let mode: Int = UserDefaults.standard.integer(forKey: "tabmode")
        let spacing: Int = UserDefaults.standard.integer(forKey: "tabspacing")
        let tabButton = ClosureButton(title: "Tab") {
            if mode == 0 {
                insertTextAtCurrentPosition(textView: textView, newText: "\t")
            } else {
                insertTextAtCurrentPosition(textView: textView, newText: String(repeating: " ", count: spacing))
            }
        }

        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        let action1 = UIAction(title: "Go To Line", image: UIImage(systemName: "arrow.right")) { _ in
            toolbarItemCache = toolbar.items ?? []

            self.animateToolbarItemsDisappearance {
                let textField = UITextField()
                textField.text = ""
                textField.placeholder = "Line number to jump to"
                textField.borderStyle = .roundedRect
                textField.keyboardType = .asciiCapable
                textField.textContentType = .none
                textField.smartQuotesType = .no
                textField.smartDashesType = .no
                textField.smartInsertDeleteType = .no
                textField.autocorrectionType = .no
                textField.autocapitalizationType = .none
                let doneButton = ClosureButton(title: "Cancel") {
                    self.animateToolbarItemsDisappearance {
                        self.restoreToolbarItems()
                    }
                }
                let gotoButton = ClosureButton(title: "Goto") {
                    guard let lineNumber = Int(textField.text ?? "n/a") else { return }
                    guard let textView = textView as? CustomTextView else { return }
                    guard let askedRange: NSRange = textView.rangeOfLine(lineNumber: lineNumber - 1) else { return }
                    guard let rect: CGRect = visualRangeRect(in: textView, for: askedRange) else { return }
                    setSelectedTextRange(for: textView, with: askedRange)
                    textView.scrollRangeToVisible(askedRange)
                    guard let highlight: CAShapeLayer = textView.addPath(color: UIColor.yellow.withAlphaComponent(0.3), rect: rect, entirePath: false, radius: 4.0) else { return }
                    let animation = CABasicAnimation(keyPath: "opacity")
                    animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
                    animation.fillMode = CAMediaTimingFillMode.forwards
                    animation.isRemovedOnCompletion = false
                    animation.fromValue = 1.0
                    animation.toValue = 0.0
                    animation.duration = 1.5
                    highlight.add(animation, forKey: nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + animation.duration) {
                        highlight.removeFromSuperlayer()
                    }
                    self.animateToolbarItemsDisappearance {
                        self.restoreToolbarItems()
                    }
                }
                let doneBarButtonItem = UIBarButtonItem(customView: doneButton)
                let gotoBarButtonItem = UIBarButtonItem(customView: gotoButton)
                let textBarButtonItem = UIBarButtonItem(customView: textField)
                let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
                restoreToolbarItems(with: [doneBarButtonItem, flexibleSpace, textBarButtonItem, flexibleSpace, gotoBarButtonItem])
            }
        }

        let action2 = UIAction(title: "Search String", image: UIImage(systemName: "magnifyingglass")) { _ in
            toolbarItemCache = toolbar.items ?? []
            self.animateToolbarItemsDisappearance {
                let textField = UITextField()
                textField.text = ""
                textField.placeholder = "String to search"
                textField.borderStyle = .roundedRect
                textField.keyboardType = .asciiCapable
                textField.textContentType = .none
                textField.smartQuotesType = .no
                textField.smartDashesType = .no
                textField.smartInsertDeleteType = .no
                textField.autocorrectionType = .no
                textField.autocapitalizationType = .none
                let doneButton = ClosureButton(title: "Close") {
                    if !highlightLayerCache.isEmpty {
                        for item in highlightLayerCache {
                            item.removeFromSuperlayer()
                        }
                    }
                    self.animateToolbarItemsDisappearance {
                        self.restoreToolbarItems()
                    }
                }
                let searchButton = ClosureButton(title: "Search") {
                    guard let string = textField.text else { return }
                    guard let textView = textView as? CustomTextView else { return }
                    if !highlightLayerCache.isEmpty {
                        for item in highlightLayerCache {
                            item.removeFromSuperlayer()
                        }
                    }
                    let nsranges: [NSRange] = findRanges(of: string, in: textView.text)
                    for item in nsranges {
                        if let rect = visualRangeRect(in: textView, for: item) {
                            let layer = textView.addPath(color: UIColor.yellow.withAlphaComponent(0.3), rect: rect, entirePath: false, radius: 4.0)
                            if let layer = layer {
                                highlightLayerCache.append(layer)
                            }
                        }
                    }
                }
                let doneBarButtonItem = UIBarButtonItem(customView: doneButton)
                let gotoBarButtonItem = UIBarButtonItem(customView: searchButton)
                let textBarButtonItem = UIBarButtonItem(customView: textField)
                let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
                restoreToolbarItems(with: [doneBarButtonItem, flexibleSpace, textBarButtonItem, flexibleSpace, gotoBarButtonItem])
            }
        }

        let menu = UIMenu(title: "Tools", children: [action2, action1])
        let menuButton = UIButton(type: .system)
        menuButton.tintColor = UIColor.label
        menuButton.setTitle("Tools", for: .normal)
        menuButton.menu = menu
        menuButton.showsMenuAsPrimaryAction = true
        let menuBarButtonItem = UIBarButtonItem(customView: menuButton)
        let TabBarButtonItem = UIBarButtonItem(customView: tabButton)
        toolbar.items = [TabBarButtonItem, flexibleSpace, menuBarButtonItem]
        textView.inputAccessoryView = toolbar
    }

    func animateToolbarItemsDisappearance(completion: @escaping () -> Void) {
        guard let items = toolbar.items else { return }
        let fadeOutDuration: TimeInterval = 0.3
        UIView.animate(withDuration: fadeOutDuration, animations: {
            for item in items {
                item.customView?.alpha = 0.0
            }
        }) { _ in
            self.toolbar.items = []
            completion()
        }
    }

    func restoreToolbarItems(with cache: [UIBarButtonItem] = toolbarItemCache) {
        toolbar.items = cache
        guard let items = toolbar.items else { return }
        let fadeInDuration: TimeInterval = 0.3
        for item in items {
            item.customView?.alpha = 0.0
        }
        UIView.animate(withDuration: fadeInDuration) {
            for item in items {
                item.customView?.alpha = 1.0
            }
        }
    }

    func insertTextAtCurrentPosition(textView: UITextView, newText: String) {
        if let selectedRange = textView.selectedTextRange {
            textView.replace(selectedRange, withText: newText)
        }
    }

    func updateUIView(_ uiView: UIView, context: Context) { }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: NeoEditor
        private var isInvalidated = false
        private var debounceWorkItem: DispatchWorkItem?
        private let debounceDelay: TimeInterval = 2.0
        //private var shouldCheck: Bool
        private var shouldAutocomplete: Bool
        let mode: Int = UserDefaults.standard.integer(forKey: "tabmode")
        let tabchar: String = {
            let mode: Int = UserDefaults.standard.integer(forKey: "tabmode")
            if mode != 1 {
                return "\t"
            } else {
                let spacing: Int = UserDefaults.standard.integer(forKey: "tabspacing")
                return String(repeating: " ", count: spacing)
            }
        }()

        init(_ markdownEditorView: NeoEditor) {
            self.parent = markdownEditorView
            //self.shouldCheck = false
            self.shouldAutocomplete = false
            let suffix: String = gsuffix(from: self.parent.filepath)

            /*let dotypecheck = UserDefaults.standard.bool(forKey: "CETypechecking")
            if dotypecheck {
                if suffix == "c" || suffix == "cpp" || suffix == "m" || suffix == "mm" || suffix == "swift" {
                    self.shouldCheck = true
                }
            }*/
            let doautocomplete = UserDefaults.standard.bool(forKey: "CEAutocomplete")
            if doautocomplete {
                if suffix == "c" || suffix == "cpp" || suffix == "m" || suffix == "mm" || suffix == "swift" {
                    self.shouldAutocomplete = true
                }
            }
        }

        func runIntrospect(_ textView: UITextView) {
            textView.font = parent.config.font
        }

        func textViewDidChange(_ textView: UITextView) {
            guard let textView = textView as? CustomTextView else { return }

            if textView.didPasted {
                self.applyHighlighting(to: textView, with: NSRange(location: 0, length: textView.text.utf16.count))
                textView.didPasted = false
            } else {
                self.applyHighlighting(to: textView, with: textView.cachedLineRange ?? NSRange(location: 0, length: 0))
            }

            /*if !shouldCheck {
                return
            }

            if !isInvalidated {
                for item in textView.highlightTMPLayer {
                    if  UIScreen.main.traitCollection.userInterfaceStyle == .light {
                        item.fillColor = UIColor.lightGray.cgColor
                    } else {
                        item.fillColor = UIColor.darkGray.cgColor
                    }
                }
                isInvalidated = true
            }

            debounceWorkItem?.cancel()
            debounceWorkItem = DispatchWorkItem { [self] in
                DispatchQueue.global(qos: .userInitiated).async {
                    let project = self.parent.project
                    mainlogSystem.clearLog()
                    typecheck(project)
                    errorcache = getlog(logitems: mainlogSystem.log)

                    DispatchQueue.main.async { [self] in
                        for item in textView.highlightTMPLayer {
                            let animation = CABasicAnimation(keyPath: "opacity")
                            animation.duration = 0.10
                            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
                            animation.fillMode = CAMediaTimingFillMode.forwards
                            animation.isRemovedOnCompletion = false
                            animation.fromValue = 1.0
                            animation.toValue = 0.0
                            item.add(animation, forKey: nil)
                            DispatchQueue.main.asyncAfter(deadline: .now() + animation.duration) {
                                item.removeFromSuperlayer()
                            }
                        }
                        for item in textView.buttonTMPLayer {
                            item.removeFromSuperview()
                        }
                        textView.highlightTMPLayer.removeAll()
                        textView.buttonTMPLayer.removeAll()
                        var claimed: [Int] = []
                        let errorcache = errorcache
                        for item in errorcache {
                            if !claimed.contains(item.line) {
                               if item.file == self.parent.filepath {
                                    switch item.level {
                                        case 0:
                                            textView.highlightLine(at: item.line - 1, with: UIColor.systemBlue, with: item.description, with: "info.circle.fill")
                                            claimed.append(item.line)
                                            break
                                        case 1:
                                            textView.highlightLine(at: item.line - 1, with: UIColor.systemYellow, with: item.description, with: "exclamationmark.triangle.fill")
                                            claimed.append(item.line)
                                            break
                                        case 2:
                                            textView.highlightLine(at: item.line - 1, with: UIColor.systemRed, with: item.description, with: "xmark.circle.fill")
                                            claimed.append(item.line)
                                            break
                                        default:
                                            break
                                    }
                                }
                            }
                        }
                        isInvalidated = false
                        return
                    }
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + debounceDelay, execute: debounceWorkItem!)*/
        }

        func applyHighlighting(to textView: UITextView, with visibleRange: NSRange) {
            let text = textView.text ?? ""

            DispatchQueue.global(qos: .userInitiated).async {
                var attributesToApply = [(NSRange, NSAttributedString.Key, Any)]()
                self.parent.highlightRules.forEach { rule in
                    let matches = rule.pattern.matches(in: text, options: [], range: visibleRange)
                    matches.forEach { match in
                        let matchRange = match.range
                        let isOverlapping = attributesToApply.contains { (range, _, _) in
                            NSIntersectionRange(range, matchRange).length > 0
                        }
                        guard !isOverlapping else { return }
                        rule.formattingRules.forEach { formattingRule in
                            guard let key = formattingRule.key,
                                  let calculateValue = formattingRule.calculateValue else { return }
                            if let matchRangeStr = Range(match.range, in: text) {
                                let matchContent = String(text[matchRangeStr])
                                let value = calculateValue(matchContent, matchRangeStr)
                                attributesToApply.append((match.range, key, value))
                            }
                        }
                    }
                }
                DispatchQueue.main.async {
                    textView.textStorage.beginEditing()
                    textView.textStorage.addAttribute(.foregroundColor, value: self.parent.config.standard, range: visibleRange)
                    attributesToApply.forEach { (range, key, value) in
                        textView.textStorage.addAttribute(key, value: value, range: range)
                    }
                    textView.textStorage.endEditing()
                }
            }
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            guard let textView = textView as? CustomTextView else { return }
            textView.enableHighlightLayer()
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            guard let textView = textView as? CustomTextView else { return }
            textView.disableHighlightLayer()
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if shouldAutocomplete {
                guard let textView = textView as? CustomTextView else { return true }

                // AUTOCOMPLETION
                if textView.didPasted {
                    return true
                }

                // spacing options
                if text == "" && range.length == 1 {
                    if let cur_line_text = currentLine(in: textView), cur_line_text.hasSuffix(tabchar) {
                        if mode == 1 {
                            backspaceMultipleCharacters(in: textView, numberOfCharacters: UserDefaults.standard.integer(forKey: "tabspacing"))
                        } else {
                            textView.deleteBackward()
                        }
                        return false
                    }
                }

                // auto curly braces implementation
                if text.contains("{") {
                    guard let cur_line_text = currentLine(in: textView) else { return false }
                    let count = countConsecutiveOccurrences(of: tabchar, in: cur_line_text)
                    parent.insertTextAtCurrentPosition(textView: textView, newText: "{")
                    let currentLineRange = textView.cachedLineRange ?? NSRange(location: 0, length: 0)
                    parent.insertTextAtCurrentPosition(textView: textView, newText: "\n\(String(repeating: tabchar, count: count + 1))\n\(String(repeating: tabchar, count: count))}")
                    moveCursorOneLineUp(in: textView)
                    self.applyHighlighting(to: textView, with: currentLineRange)
                    return false
                }

                // auto braces implementation
                if text.contains("(") {
                    parent.insertTextAtCurrentPosition(textView: textView, newText: "()")
                    textView.selectedRange = NSMakeRange(textView.selectedRange.location - 1, 0)
                    return false
                }

                // auto string implementation
                if text.contains("\"") {
                    parent.insertTextAtCurrentPosition(textView: textView, newText: "\"\"")
                    textView.selectedRange = NSMakeRange(textView.selectedRange.location - 1, 0)
                    return false
                }

                // auto tabbing implementation
                if text.contains("\n") {
                    guard let cur_line_text = currentLine(in: textView) else { return false }
                    let count = countConsecutiveOccurrences(of: tabchar, in: cur_line_text)
                    parent.insertTextAtCurrentPosition(textView: textView, newText: "\n\(String(repeating: tabchar, count: count))")
                    return false
                }

                // hardware keyboard implementation
                if mode == 1, text.contains("\t") {
                    let spacing: Int = UserDefaults.standard.integer(forKey: "tabspacing")
                    parent.insertTextAtCurrentPosition(textView: textView, newText: String(repeating: " ", count: spacing))
                    return false
                }
            }

            return true
        }
    }
}

class CustomTextView: UITextView {
    var didPasted: Bool = false
    var lineLight: CGColor = UIColor.clear.cgColor

    private(set) var hightlight_setuped: Bool = false
    private(set) var cachedLineRange: NSRange?
    private var wempty: Bool = false
    private let highlightLayer = CAShapeLayer()
    var highlightTMPLayer: [CAShapeLayer] = []
    var buttonTMPLayer: [UIButton] = []

    override func paste(_ sender: Any?) {
        didPasted = true
        super.paste(sender)
    }

    override func caretRect(for position: UITextPosition) -> CGRect {
        let caretRect = super.caretRect(for: position)
        updateCurrentLineRange()
        return caretRect
    }

    func setupHighlightLayer() {
        highlightLayer.fillColor = lineLight
        layer.insertSublayer(highlightLayer, at: 0)
        hightlight_setuped = true
    }

    private func updateCurrentLineRange() {
        guard let caretPosition = selectedTextRange?.start else {
            return
        }

        let caretIndex = offset(from: beginningOfDocument, to: caretPosition)
        let text = self.text as NSString
        let lineRange = text.lineRange(for: NSRange(location: caretIndex, length: 0))

        cachedLineRange = lineRange

        if hightlight_setuped {
            updateHighlightLayer()
        }
    }

    private func updateHighlightLayer() {
        guard let currentLineRange = cachedLineRange else {
            highlightLayer.path = nil
            return
        }

        let path = UIBezierPath()

        layoutManager.enumerateLineFragments(forGlyphRange: currentLineRange) { (rect, usedRect, _, glyphRange, _) in
            let textRect = usedRect.offsetBy(dx: self.textContainerInset.left, dy: self.textContainerInset.top)
            path.append(UIBezierPath(roundedRect: textRect, cornerRadius: 4.0))
        }

        animateHighlightLayer(from: highlightLayer.path, to: path.cgPath)

        highlightLayer.path = path.cgPath
    }

    private func animateHighlightLayer(from oldPath: CGPath?, to newPath: CGPath) {
        let animation = CABasicAnimation(keyPath: "path")
        animation.duration = 0.25

        animation.toValue = newPath
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.isRemovedOnCompletion = false

        if newPath.boundingBox.isEmpty && !wempty {
            animation.keyPath = "opacity"
            animation.fromValue = 1.0
            animation.toValue = 0.0
            animation.duration = 0.50
            wempty = true
            highlightLayer.add(animation, forKey: nil)
        } else if wempty && !newPath.boundingBox.isEmpty {
            animation.keyPath = "opacity"
            animation.fromValue = 0.0
            animation.toValue = 1.0
            animation.duration = 0.50
            wempty = false
        }

        if wempty {
            return
        }

        highlightLayer.add(animation, forKey: nil)
    }

    func enableHighlightLayer() {
        if hightlight_setuped {
            setupHighlightLayer()
        }
    }

    func disableHighlightLayer() {
        if hightlight_setuped {
            highlightLayer.removeFromSuperlayer()
        }
    }

    func rangeOfLine(lineNumber: Int) -> NSRange? {
        let nsString = self.text as NSString
        let lines = nsString.components(separatedBy: .newlines)
        guard lineNumber >= 0 && lineNumber < lines.count else {
            return nil
        }
        var location = 0
        for i in 0..<lineNumber {
            location += (lines[i] as NSString).length + 1
        }
        let length = (lines[lineNumber] as NSString).length
        return NSRange(location: location, length: length)
    }

    func addPath(color: UIColor, rect: CGRect, entirePath: Bool? = nil, radius: CGFloat? = 0.0) -> CAShapeLayer? {
        let newHighlightLayer = CAShapeLayer()
        newHighlightLayer.fillColor = color.cgColor
        layer.insertSublayer(newHighlightLayer, at: 1)

        let path = UIBezierPath()
        var newRect: CGRect = rect

        if let entirePath = entirePath {
            if entirePath {
                newRect.size.width = UIScreen.main.bounds.size.width
            }
        } else {
            newRect.size.width = UIScreen.main.bounds.size.width
        }

        path.append(UIBezierPath(roundedRect: newRect, cornerRadius: radius ?? 0.0))

        newHighlightLayer.path = path.cgPath
        highlightTMPLayer.append(newHighlightLayer)

        return newHighlightLayer
    }

    func addAnimatedPath(color: UIColor, rect: CGRect, entirePath: Bool? = nil, radius: CGFloat? = 0.0) -> CAShapeLayer? {
        let newHighlightLayer = CAShapeLayer()
        newHighlightLayer.fillColor = color.cgColor
        layer.insertSublayer(newHighlightLayer, at: 1)

        let path = UIBezierPath()
        var newRect: CGRect = rect

        if let entirePath = entirePath {
            if entirePath {
                newRect.size.width = UIScreen.main.bounds.size.width
                newRect.origin.x = 0
            }
        } else {
            newRect.size.width = UIScreen.main.bounds.size.width
            newRect.origin.x = 0
        }

        path.append(UIBezierPath(roundedRect: newRect, cornerRadius: radius ?? 0.0))

        newHighlightLayer.path = path.cgPath
        newHighlightLayer.opacity = 0.1
        highlightTMPLayer.append(newHighlightLayer)

        let animation = CABasicAnimation(keyPath: "opacity")
        animation.duration = 0.25
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.isRemovedOnCompletion = false
        animation.fromValue = 0.0
        animation.toValue = 1.0
        newHighlightLayer.add(animation, forKey: nil)

        return newHighlightLayer
    }

    func highlightLine(at lineNumber: Int, with color: UIColor, with text: String, with symbol: String) {
        guard let range = rangeOfLine(lineNumber: lineNumber) else { return }
        guard let rect = visualRangeRect(in: self, for: range) else { return }

        _ = addAnimatedPath(color: color.withAlphaComponent(0.3), rect: rect)

        let lineRect: CGRect = rect

        var button: UIButton = UIButton()
        button = ClosureButton(title: "") {
            let uiView: UIView = UIView()
            uiView.backgroundColor = UIColor.systemGray6
            uiView.frame = CGRect(x: (UIScreen.main.bounds.width - (UIScreen.main.bounds.width / 2.25)) - (self.font?.pointSize ?? 0.0), y: lineRect.midY - ((self.font?.pointSize ?? 0.0) / 2), width: (UIScreen.main.bounds.width / 2.25) + (self.font?.pointSize ?? 0.0), height: 100)
            uiView.layer.cornerRadius = 15
            uiView.layer.borderWidth = 1
            uiView.layer.borderColor = color.cgColor
            uiView.clipsToBounds = true
            let dissmissButton: UIButton = ClosureButton(title: "") {
                UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn, animations: {
                    uiView.alpha = 0.0
                }, completion: { finished in
                    if finished {
                        uiView.removeFromSuperview()
                    }
                })
            }
            dissmissButton.frame = CGRect(x: uiView.bounds.width - 30 , y: 10, width: 15, height: 15)
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 15, weight: .regular)
            let image = UIImage(systemName: "xmark.circle", withConfiguration: symbolConfig)
            dissmissButton.setImage(image, for: .normal)
            dissmissButton.tintColor = UIColor.label
            let issueLabel: UILabel = PaddedLabel()
            issueLabel.frame = CGRect(x: 10, y: dissmissButton.frame.maxY + 10, width: uiView.bounds.width - 20, height: (uiView.bounds.height - dissmissButton.bounds.height) - 30)
            issueLabel.backgroundColor = UIColor.systemBackground
            issueLabel.layer.cornerRadius = 10
            issueLabel.layer.borderWidth = 1
            issueLabel.layer.borderColor = color.withAlphaComponent(0.5).cgColor
            issueLabel.clipsToBounds = true
            issueLabel.numberOfLines = 0
            issueLabel.font = self.font?.withSize(CGFloat((self.font?.pointSize ?? 0.0) / 1.5))
            issueLabel.text = text
            uiView.addSubview(dissmissButton)
            uiView.addSubview(issueLabel)
            uiView.alpha = 0.0
            self.addSubview(uiView)
            UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn, animations: {
                uiView.alpha = 1.0
            }, completion: nil)
        }
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
        let image = UIImage(systemName: symbol, withConfiguration: symbolConfig)
        button.setImage(image, for: .normal)
        button.tintColor = color
        button.backgroundColor = .clear
        button.frame = CGRect(x: (UIScreen.main.bounds.width - 5) - (font?.pointSize ?? 0.0), y: lineRect.midY - ((font?.pointSize ?? 0.0) / 2), width: font?.pointSize ?? 0.0, height: font?.pointSize ?? 0.0)
        self.addSubview(button)
        bringSubviewToFront(button)
        buttonTMPLayer.append(button)
    }

    var onLayoutCompletion: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        onLayoutCompletion?()
        onLayoutCompletion = nil
    }

    func setLayoutCompletionHandler(_ handler: @escaping () -> Void) {
        self.onLayoutCompletion = handler
    }
}

func moveCursorOneLineUp(in textView: UITextView) {
    guard let text = textView.text, !text.isEmpty else { return }
    let currentLocation = textView.selectedRange.location
    let nsText = text as NSString
    let currentLineRange = nsText.lineRange(for: NSRange(location: currentLocation, length: 0))
    if currentLineRange.location > 0 {
        let previousLineRange = nsText.lineRange(for: NSRange(location: currentLineRange.location - 1, length: 0))
        textView.selectedRange = NSRange(location: NSMaxRange(previousLineRange) - 1, length: 0)
    }
}

class PaddedLabel: UILabel {
    var textInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + textInsets.left + textInsets.right,
                      height: size.height + textInsets.top + textInsets.bottom)
    }
}

func backspaceMultipleCharacters(in textView: UITextView, numberOfCharacters: Int) {
    guard let selectedRange = textView.selectedTextRange, numberOfCharacters > 0 else { return }
    let cursorPosition = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
    let startPosition = max(cursorPosition - numberOfCharacters, 0)
    if let startPositionIndex = textView.position(from: textView.beginningOfDocument, offset: startPosition) {
        let rangeToDelete = textView.textRange(from: startPositionIndex, to: selectedRange.start)
        if let rangeToDelete = rangeToDelete {
            textView.replace(rangeToDelete, withText: "")
        }
    }
}

struct TextFormattingRule {
   typealias AttributedKeyCallback = (String, Range<String.Index>) -> Any

   let key: NSAttributedString.Key?
   let calculateValue: AttributedKeyCallback?

   init(key: NSAttributedString.Key, value: Any) {
       self.init(key: key, calculateValue: { _, _ in value })
   }

   init(
       key: NSAttributedString.Key? = nil,
       calculateValue: AttributedKeyCallback? = nil
   ) {
       self.key = key
       self.calculateValue = calculateValue
   }
}

struct HighlightRule {
   let pattern: NSRegularExpression

   let formattingRules: [TextFormattingRule]

   init(pattern: NSRegularExpression, formattingRules: [TextFormattingRule]) {
       self.pattern = pattern
       self.formattingRules = formattingRules
   }
}

class ClosureBarButtonItem: UIBarButtonItem {
    private var actionHandler: (() -> Void)?

    init(title: String?, style: UIBarButtonItem.Style, actionHandler: @escaping () -> Void) {
        self.actionHandler = actionHandler
        super.init()
        self.title = title
        self.style = style
        self.target = self
        self.tintColor = UIColor.label
        self.action = #selector(didTapButton)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    @objc private func didTapButton() {
        actionHandler?()
    }
}

class ClosureButton: UIButton {
    private var actionHandler: (() -> Void)?

    init(title: String, actionHandler: @escaping () -> Void) {
        self.actionHandler = actionHandler
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        self.setTitleColor(.label, for: .normal)
        self.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        self.tintColor = UIColor.label
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    @objc private func didTapButton() {
        actionHandler?()
    }
}

func grule(_ isaythis: String) -> [HighlightRule] {
    let userInterfaceStyle = UIScreen.main.traitCollection.userInterfaceStyle

    var color1: UIColor = UIColor.clear   // Keywords
    var color2: UIColor = UIColor.clear   // Structure or Class Name
    var color4: UIColor = UIColor.clear   // Numbers
    var color5: UIColor = UIColor.clear   // Comments
    var color6: UIColor = UIColor.clear   // Strings
    var color7: UIColor = UIColor.clear   // Functions
    var color8: UIColor = UIColor.clear   // Function/Variable names
    var color10: UIColor = UIColor.clear  // Preprocessor Statements

    if userInterfaceStyle == .light {
        color1 = light_color1
        color2 = light_color2
        color4 = light_color4
        color5 = light_color5
        color6 = light_color6
        color7 = light_color7
        color8 = light_color8
        color10 = light_color10
    } else {
        color1 = dark_color1
        color2 = dark_color2
        color4 = dark_color4
        color5 = dark_color5
        color6 = dark_color6
        color7 = dark_color7
        color8 = dark_color8
        color10 = dark_color10
    }

    switch(isaythis) {
        case "swift":
            return [
                HighlightRule(pattern: try! NSRegularExpression(pattern: "(?<!\\/\\/)(\"(.*?)\")", options: []), formattingRules: [ TextFormattingRule(key: .foregroundColor, value: color6)
                ]), HighlightRule(pattern: try! NSRegularExpression(pattern: "(//.*|\\/\\*[\\s\\S]*?\\*\\/)", options: []), formattingRules: [ TextFormattingRule(key: .foregroundColor, value: color5)
                ]), HighlightRule(pattern: try! NSRegularExpression(pattern: "\\b(let|var|if|else|func|return|class|struct|self|public|private|extension|true|false|init|try|do|catch|guard|import|override|nil|switch|case|default|some|throw|for|in)\\b", options: []), formattingRules: [ TextFormattingRule(key: .foregroundColor, value: color1)
                ]), HighlightRule(pattern: try! NSRegularExpression(pattern: "\\b(-?\\d+(\\.\\d+)?)\\b", options: []), formattingRules: [ TextFormattingRule(key: .foregroundColor, value: color4)
                ]), HighlightRule(pattern: try! NSRegularExpression(pattern: #"(?<=: |-> |some )[A-Za-z1-9]+"#, options: []), formattingRules: [ TextFormattingRule(key: .foregroundColor, value: color7)
                ]), HighlightRule(pattern: try! NSRegularExpression(pattern: "(?<=\\b(struct|class|extension)\\s)\\w+", options: []), formattingRules: [ TextFormattingRule(key: .foregroundColor, value: color2)
                ]), HighlightRule(pattern: try! NSRegularExpression(pattern: "(?<=\\b(func|let|var)\\s)\\w+", options: []), formattingRules: [ TextFormattingRule(key: .foregroundColor, value: color8)
                ]), HighlightRule(pattern: try! NSRegularExpression(pattern: #"\b\w+(?=\s*[\{\(])"#, options: []), formattingRules: [ TextFormattingRule(key: .foregroundColor, value: color7)
                ]), HighlightRule(pattern: try! NSRegularExpression(pattern: "@\\w+[^()]", options: []), formattingRules: [ TextFormattingRule(key: .foregroundColor, value: color7)])
            ]
        case "c", "h", "m",  "mm", "cpp":
            return [
                HighlightRule(pattern: try! NSRegularExpression(pattern: "(?<!\\/\\/)(<(.*?)>)", options: []), formattingRules: [ TextFormattingRule(key: .foregroundColor, value: color6)
                ]), HighlightRule(pattern: try! NSRegularExpression(pattern: "(?<!\\/\\/)(\"(.*?)\")", options: []), formattingRules: [ TextFormattingRule(key: .foregroundColor, value: color6)
                ]), HighlightRule(pattern: try! NSRegularExpression(pattern: "(//.*|\\/\\*[\\s\\S]*?\\*\\/)", options: []), formattingRules: [ TextFormattingRule(key: .foregroundColor, value: color5)
                ]), HighlightRule(pattern: try! NSRegularExpression(pattern: "\\b\\w+(?=(\\())", options: []), formattingRules: [ TextFormattingRule(key: .foregroundColor, value: color8)
                ]), HighlightRule(pattern: try! NSRegularExpression(pattern: "(#\\w+)", options: []), formattingRules: [ TextFormattingRule(key: .foregroundColor, value: color10)
                ]), HighlightRule(pattern: try! NSRegularExpression(pattern: #"\b\w*_t\b"#, options: []), formattingRules: [ TextFormattingRule(key: .foregroundColor, value: color7)
                ]), HighlightRule(pattern: try! NSRegularExpression(pattern: "\\b(@private|@implementation|@interface|@public|@protected|int|char|float|double|void|short|long|unsigned|signed|struct|union|enum|_Bool|_Complex|_Imaginary|if|else|switch|case|default|while|do|for|break|continue|return|goto|auto|register|static|extern|typedef|sizeof|const|volatile|restrict|inline|_Alignas|_Alignof|_Atomic|_Static_assert|_Noreturn|_Thread_local)\\b", options: []), formattingRules: [ TextFormattingRule(key: .foregroundColor, value: color1)
                ]), HighlightRule(pattern: try! NSRegularExpression(pattern: "\\b\\w+(?=(\\())", options: []), formattingRules: [ TextFormattingRule(key: .foregroundColor, value: color8)
                ]), HighlightRule(pattern: try! NSRegularExpression(pattern: "\\b(-?\\d+(\\.\\d+)?)\\b", options: []), formattingRules: [ TextFormattingRule(key: .foregroundColor, value: color4)
                ])
            ]
        default:
            return []
    }
}

// MARK: Theming
// XCode format
// 1: Keywords
// 2: Type Declarations
// 4: Numbers
// 5: Comments
// 6: Strings
// 7: Other Class Names
// 8: Other Declarations
// 10: Project Preprocessor Macros

// MARK: Color Storage
// Light Color storage
var light_color1: UIColor = UserDefaults.standard.color(forKey: "lc1")
var light_color2: UIColor = UserDefaults.standard.color(forKey: "lc2")
var light_color4: UIColor = UserDefaults.standard.color(forKey: "lc4")
var light_color5: UIColor = UserDefaults.standard.color(forKey: "lc5")
var light_color6: UIColor = UserDefaults.standard.color(forKey: "lc6")
var light_color7: UIColor = UserDefaults.standard.color(forKey: "lc7")
var light_color8: UIColor = UserDefaults.standard.color(forKey: "lc8")
var light_color10: UIColor = UserDefaults.standard.color(forKey: "lc10")

// Dark Color storage
var dark_color1: UIColor = UserDefaults.standard.color(forKey: "dc1")
var dark_color2: UIColor = UserDefaults.standard.color(forKey: "dc2")
var dark_color4: UIColor = UserDefaults.standard.color(forKey: "dc4")
var dark_color5: UIColor = UserDefaults.standard.color(forKey: "dc5")
var dark_color6: UIColor = UserDefaults.standard.color(forKey: "dc6")
var dark_color7: UIColor = UserDefaults.standard.color(forKey: "dc7")
var dark_color8: UIColor = UserDefaults.standard.color(forKey: "dc8")
var dark_color10: UIColor = UserDefaults.standard.color(forKey: "dc10")

var light_standard: UIColor = UserDefaults.standard.color(forKey: "lst")
var light_background: UIColor = UserDefaults.standard.color(forKey: "lb")
var light_selection: UIColor = UserDefaults.standard.color(forKey: "ls")
var light_current: UIColor = UserDefaults.standard.color(forKey: "lcl")
var light_cursor: UIColor = UserDefaults.standard.color(forKey: "lc")

var dark_standard: UIColor = UserDefaults.standard.color(forKey: "dst")
var dark_background: UIColor = UserDefaults.standard.color(forKey: "db")
var dark_selection: UIColor = UserDefaults.standard.color(forKey: "ds")
var dark_current: UIColor = UserDefaults.standard.color(forKey: "dcl")
var dark_cursor: UIColor = UserDefaults.standard.color(forKey: "dc")

// MARK: Theme system
func neoRGB(_ red: CGFloat,_ green: CGFloat,_ blue: CGFloat ) -> UIColor {
    return UIColor(red: red/255.0, green: green/255.0, blue: blue/255.0, alpha: 1.0)
}

func storeTheme() -> Void {
    UserDefaults.standard.setColor(light_color1, forKey: "lc1")
    UserDefaults.standard.setColor(light_color2, forKey: "lc2")
    UserDefaults.standard.setColor(light_color4, forKey: "lc4")
    UserDefaults.standard.setColor(light_color5, forKey: "lc5")
    UserDefaults.standard.setColor(light_color6, forKey: "lc6")
    UserDefaults.standard.setColor(light_color7, forKey: "lc7")
    UserDefaults.standard.setColor(light_color8, forKey: "lc8")
    UserDefaults.standard.setColor(light_color10, forKey: "lc10")

    UserDefaults.standard.setColor(dark_color1, forKey: "dc1")
    UserDefaults.standard.setColor(dark_color2, forKey: "dc2")
    UserDefaults.standard.setColor(dark_color4, forKey: "dc4")
    UserDefaults.standard.setColor(dark_color5, forKey: "dc5")
    UserDefaults.standard.setColor(dark_color6, forKey: "dc6")
    UserDefaults.standard.setColor(dark_color7, forKey: "dc7")
    UserDefaults.standard.setColor(dark_color8, forKey: "dc8")
    UserDefaults.standard.setColor(dark_color10, forKey: "dc10")

    UserDefaults.standard.setColor(light_standard, forKey: "lst")
    UserDefaults.standard.setColor(light_background, forKey: "lb")
    UserDefaults.standard.setColor(light_selection, forKey: "ls")
    UserDefaults.standard.setColor(light_current, forKey: "lcl")
    UserDefaults.standard.setColor(light_cursor, forKey: "lc")

    UserDefaults.standard.setColor(dark_standard, forKey: "dst")
    UserDefaults.standard.setColor(dark_background, forKey: "db")
    UserDefaults.standard.setColor(dark_selection, forKey: "ds")
    UserDefaults.standard.setColor(dark_current, forKey: "dcl")
    UserDefaults.standard.setColor(dark_cursor, forKey: "dc")
}

func setTheme(_ theme: Int) -> Void {
    switch theme {
        case 0:
            light_color1 = neoRGB(155, 35, 147)
            light_color2 = neoRGB(28, 70, 74)
            light_color4 = neoRGB(28, 0, 207)
            light_color5 = neoRGB(93, 108, 121)
            light_color6 = neoRGB(196, 26, 22)
            light_color7 = neoRGB(57, 0, 160)
            light_color8 = neoRGB(15, 104, 160)
            light_color10 = neoRGB(100, 56, 32)

            dark_color1 = neoRGB(252, 95, 163)
            dark_color2 = neoRGB(93, 216, 255)
            dark_color4 = neoRGB(208, 191, 105)
            dark_color5 = neoRGB(108, 121, 134)
            dark_color6 = neoRGB(252, 106, 93)
            dark_color7 = neoRGB(208, 168, 255)
            dark_color8 = neoRGB(65, 161, 192)
            dark_color10 = neoRGB(253, 143, 63)

            light_standard = UIColor.black
            light_background = neoRGB(255, 255, 255)
            light_selection = neoRGB(164, 205, 255)
            light_current = neoRGB(232, 242, 255)
            light_cursor = neoRGB(0, 0, 0)

            dark_standard = UIColor.white
            dark_background = neoRGB(31, 31, 36)
            dark_selection = neoRGB(81, 91, 112)
            dark_current = neoRGB(35, 37, 43)
            dark_cursor = neoRGB(255, 255, 255)
        case 1:
            light_color1 = neoRGB(178, 24, 137)
            light_color2 = neoRGB(93, 216, 255)
            light_color4 = neoRGB(120, 109, 196)
            light_color5 = neoRGB(65, 182, 69)
            light_color6 = neoRGB(219, 44, 56)
            light_color7 = neoRGB(0, 160, 190)
            light_color8 = neoRGB(65, 161, 192)
            light_color10 = neoRGB(198, 124, 72)

            dark_color1 = light_color1
            dark_color2 = light_color2
            dark_color4 = light_color4
            dark_color5 = light_color5
            dark_color6 = light_color6
            dark_color7 = light_color7
            dark_color8 = light_color8
            dark_color10 = light_color10

            light_standard = UIColor.white
            light_background = neoRGB(30, 32, 40)
            light_selection = neoRGB(84, 85, 74)
            light_current = neoRGB(45, 45, 45)
            light_cursor = neoRGB(255, 255, 255)

            dark_standard = light_standard
            dark_background = light_background
            dark_selection = light_selection
            dark_current = light_current
            dark_cursor = light_cursor
        case 2:
            light_color1 = neoRGB(211, 24, 149)
            light_color2 = neoRGB(93, 216, 255)
            light_color4 = neoRGB(120, 109, 255)
            light_color5 = neoRGB(65, 204, 69)
            light_color6 = neoRGB(255, 44, 56)
            light_color7 = neoRGB(0, 160, 255)
            light_color8 = neoRGB(65, 161, 192)
            light_color10 = neoRGB(228, 124, 72)

            dark_color1 = light_color1
            dark_color2 = light_color2
            dark_color4 = light_color4
            dark_color5 = light_color5
            dark_color6 = light_color6
            dark_color7 = light_color7
            dark_color8 = light_color8
            dark_color10 = light_color10

            light_standard = UIColor.white
            light_background = neoRGB(0, 0, 0)
            light_selection = neoRGB(75, 71, 64)
            light_current = neoRGB(26, 25, 25)
            light_cursor = neoRGB(255, 255, 255)

            dark_standard = light_standard
            dark_background = light_background
            dark_selection = light_selection
            dark_current = light_current
            dark_cursor = light_cursor
        default:
            return
    }
}

extension UserDefaults {
    func setColor(_ color: UIColor, forKey key: String) {
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false) {
            self.set(colorData, forKey: key)
        }
    }
    func color(forKey key: String) -> UIColor {
        if let colorData = self.data(forKey: key),
           // let color = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? UIColor
           let color = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [UIColor.self], from: colorData) as? UIColor {
            return color
        }
        return UIColor.clear
    }
}

struct NeoEditorSettings: View {
    @AppStorage("CERender") var render: Double = 1.0
    @AppStorage("CEFontSize") var font: Double = 13.0
    @AppStorage("CEToolbar") var toolbar: Bool = true
    @AppStorage("CEAutocomplete") var autocomplete: Bool = true
    @AppStorage("CECurrentLineHighlighting") var current_line_highlighting: Bool = false
    var body: some View {
        List {
            Section(header: Text("Themes")) {
                Button("Default") {
                    setTheme(0)
                    storeTheme()
                }
                Button("Dusk") {
                    setTheme(1)
                    storeTheme()
                }
                Button("Midnight") {
                    setTheme(2)
                    storeTheme()
                }
            }
            Section(header: Text("Advanced Graphic Settings")) {
                HStack {
                    Text("Render: \(NumberFormatter.localizedString(from: NSNumber(value: render), number: .percent))")
                        .frame(width: 150)
                    Slider(value: $render, in: 0...1)
                }
                Stepper("Font Size: \(String(Int(font)))", value: $font, in: 0...20)
                Toggle("Line Highlighting", isOn: $current_line_highlighting)
                    .disabled(isPad)
                Toggle("Toolbar", isOn: $toolbar)
                Toggle("Autocomplete", isOn: $autocomplete)
            }
        }
        .navigationTitle("Code Editor")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(InsetGroupedListStyle())
    }
}
