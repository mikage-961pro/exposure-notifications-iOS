/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller that manages a standardized visual layout for a single step in a user interface flow.
*/

import UIKit

struct Step {
    
    struct BarButton {
        let item: UIBarButtonItem.SystemItem
        let action: () -> Void
    }
    
    struct Button {
        let title: String
        let isProminent: Bool
        let isEnabled: Bool
        let action: () -> Void
        
        init(title: String, isProminent: Bool = false, isEnabled: Bool = true, action: @escaping () -> Void) {
            self.title = title
            self.isProminent = isProminent
            self.isEnabled = isEnabled
            self.action = action
        }
    }
    
    let hidesNavigationBackButton: Bool
    let rightBarButton: BarButton?
    let title: String
    let text: NSAttributedString
    let urlHandler: ((URL, UITextItemInteraction) -> Bool)?
    let customView: UIView?
    let isModal: Bool
    let buttons: [Button]
    
    static let bodyTextAttributes: [NSAttributedString.Key: Any] = [
        .foregroundColor: UIColor.label,
        .font: UIFont.preferredFont(forTextStyle: .body)
    ]
    
    static let headlineTextAttributes: [NSAttributedString.Key: Any] = [
        .foregroundColor: UIColor.label,
        .font: UIFont.preferredFont(forTextStyle: .headline)
    ]
    
    static func linkTextAttributes(_ link: URL) -> [NSAttributedString.Key: Any] { [
        .font: UIFont.preferredFont(forTextStyle: .body),
        .link: link
    ]}
    
    init(hidesNavigationBackButton: Bool = false,
         rightBarButton: BarButton? = nil,
         title: String,
         text: NSAttributedString,
         urlHandler: ((URL, UITextItemInteraction) -> Bool)? = nil,
         customView: UIView? = nil,
         isModal: Bool = true,
         buttons: [Button] = []) {
        self.hidesNavigationBackButton = hidesNavigationBackButton
        self.rightBarButton = rightBarButton
        self.title = title
        let mutableText = NSMutableAttributedString(attributedString: text)
        let warningBegin = (text.string as NSString).range(of: "{")
        let warningEnd = (text.string as NSString).range(of: "}")
        mutableText.addAttribute(.foregroundColor, value: UIColor.systemOrange, range: warningBegin.union(warningEnd))
        self.text = mutableText
        self.urlHandler = urlHandler
        self.customView = customView
        self.isModal = isModal
        self.buttons = buttons
    }
    
    init(hidesNavigationBackButton: Bool = false,
         rightBarButton: BarButton? = nil,
         title: String,
         text: String,
         urlHandler: ((URL, UITextItemInteraction) -> Bool)? = nil,
         customView: UIView? = nil,
         isModal: Bool = true,
         buttons: [Button] = []) {
        self.init(hidesNavigationBackButton: hidesNavigationBackButton,
                  rightBarButton: rightBarButton,
                  title: title,
                  text: NSAttributedString(string: text, attributes: Step.bodyTextAttributes),
                  urlHandler: urlHandler,
                  customView: customView,
                  isModal: isModal,
                  buttons: buttons)
    }
}

class StepNavigationController: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.standardAppearance.configureWithOpaqueBackground()
        navigationBar.standardAppearance.shadowColor = nil
    }
}

class StepViewController: UIViewController, UITextViewDelegate {
    
    var step: Step {
        preconditionFailure("Must override step.")
    }
    
    static func make() -> Self {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "Step", creator: { coder -> Self? in
            return Self(coder: coder)
        })
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        navigationItem.hidesBackButton = step.hidesNavigationBackButton
        if let barButton = step.rightBarButton {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: barButton.item,
                                                                target: self, action: #selector(rightBarButtonAction))
        }
        isModalInPresentation = step.isModal
    }
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var stackView: UIStackView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var textView: UITextView!
    @IBOutlet var buttonBackgroundView: UIView!
    @IBOutlet var buttonStackView: UIStackView!
    @IBOutlet var button0: PlatterButton!
    @IBOutlet var button1: PlatterButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = step.title
        titleLabel.accessibilityTraits = .header
        textView.attributedText = step.text
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0.0
        if let customView = step.customView {
            stackView.addArrangedSubview(customView)
        }
        
        buttonBackgroundView.isHidden = step.buttons.isEmpty
        
        updateButtons()
    }
    
    func updateButtons() {
        func apply(_ stepButton: Step.Button, to platterButton: PlatterButton) {
            UIView.performWithoutAnimation {
                platterButton.setTitle(stepButton.title, for: .normal)
                platterButton.layoutIfNeeded()
            }
            platterButton.isProminent = stepButton.isProminent
            platterButton.isEnabled = stepButton.isEnabled
        }
        
        switch step.buttons.count {
        case 0:
            button0.isHidden = true
            button1.isHidden = true
        case 1:
            apply(step.buttons[0], to: button0)
            button1.isHidden = true
        case 2:
            apply(step.buttons[0], to: button0)
            apply(step.buttons[1], to: button1)
        default:
            assertionFailure("Step cannot have more than 2 buttons.")
        }
    }
    
    var scrollViewBottomInset: CGFloat {
        let buttonStackHeight = buttonStackView.frame.height
        return buttonStackHeight == 0.0 ? 0.0 : buttonStackHeight + 32.0
    }
    
    var scrollViewBottomIndicatorInset: CGFloat {
        return scrollViewBottomInset
    }
    
    override func viewDidLayoutSubviews() {
        scrollView.contentInset.bottom = scrollViewBottomInset
        scrollView.verticalScrollIndicatorInsets.bottom = scrollViewBottomIndicatorInset
    }
    
    @objc
    func rightBarButtonAction() {
        step.rightBarButton!.action()
    }
    
    @IBAction func button0TouchUpInside() {
        step.buttons[0].action()
    }
    
    @IBAction func button1TouchUpInside() {
        step.buttons[1].action()
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return step.urlHandler?(URL, interaction) ?? true
    }
}

class ValueStepViewController<Value>: StepViewController {
    var value: Value
    required init?(value: Value, coder: NSCoder) {
        self.value = value
        super.init(coder: coder)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    static func make(value: Value) -> Self {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "Step", creator: { coder -> Self? in
            return Self(value: value, coder: coder)
        })
    }
}
