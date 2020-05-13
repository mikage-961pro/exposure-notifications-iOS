/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controllers that are used to verify approved medical tests, enter known symptoms, and report the data to a server.
*/

import UIKit
import ExposureNotification

class TestVerificationViewController: StepNavigationController {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let testResult = TestResult(id: UUID(), isAdded: false, dateAdministered: Date(), isShared: false)
        LocalStore.shared.testResults[testResult.id] = testResult
        pushViewController(BeforeYouGetStartedViewController.make(testResultID: testResult.id), animated: false)
    }
    
    init?(rootViewController: TestStepViewController, coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        pushViewController(rootViewController, animated: false)
    }
    
    class TestStepViewController: ValueStepViewController<UUID> {
        var testResultID: UUID { value }
        var testResult: TestResult {
            get { LocalStore.shared.testResults[value]! }
            set { LocalStore.shared.testResults[value] = newValue }
        }
        static func make(testResultID: UUID) -> Self {
            return make(value: testResultID)
        }
    }
    
    class BeforeYouGetStartedViewController: TestStepViewController {
        var requirementsView: RequirementView!
        
        override var step: Step {
            Step(
                rightBarButton: .init(item: .cancel) {
                    TestVerificationViewController.cancel(from: self)
                },
                title: NSLocalizedString("VERIFICATION_START_TITLE", comment: "Title"),
                text: NSLocalizedString("VERIFICATION_START_TEXT", comment: "Text"),
                customView: requirementsView,
                isModal: false,
                buttons: [Step.Button(title: NSLocalizedString("NEXT", comment: "Button"), isProminent: true, action: {
                    self.show(TestIdentifierViewController.make(testResultID: self.testResultID), sender: nil)
                })]
            )
        }
        
        override func viewDidLoad() {
            requirementsView = RequirementView(text: NSLocalizedString("VERIFICATION_START_REQUIREMENT_TEXT", comment: "Requirement text"))
            super.viewDidLoad()
            NSLayoutConstraint.activate([
                requirementsView.widthAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.widthAnchor)
            ])
        }
    }
    
    class TestIdentifierViewController: TestStepViewController {
        
        var customStackView: UIStackView!
        var entryView: EntryView!
        
        var keyboardHeight: CGFloat = 0.0
        var observers = [NSObjectProtocol]()
        
        deinit {
            for observer in observers {
                NotificationCenter.default.removeObserver(observer)
            }
        }
        
        override func viewDidLoad() {
            entryView = EntryView()
            entryView.textDidChange = { [unowned self] in
                self.updateButtons()
            }
            
            let warningLabel = UILabel()
            warningLabel.text = NSLocalizedString("VERIFICATION_IDENTIFIER_DEVELOPER", comment: "Label")
            warningLabel.textColor = .systemOrange
            warningLabel.font = .preferredFont(forTextStyle: .body)
            warningLabel.adjustsFontForContentSizeCategory = true
            warningLabel.textAlignment = .center
            warningLabel.numberOfLines = 0
            
            customStackView = UIStackView(arrangedSubviews: [entryView, warningLabel])
            customStackView.axis = .vertical
            customStackView.spacing = 16.0
            
            super.viewDidLoad()
            
            NSLayoutConstraint.activate([
                customStackView.widthAnchor.constraint(equalTo: stackView.layoutMarginsGuide.widthAnchor)
            ])
            
            let keyboardWillChange = UIResponder.keyboardWillChangeFrameNotification
            observers.append(NotificationCenter.default.addObserver(forName: keyboardWillChange, object: nil, queue: nil, using: { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect, let window = self.view.window {
                    self.keyboardHeight = keyboardFrame.intersection(window.bounds).height
                } else {
                    self.keyboardHeight = 0.0
                }
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
            }))
        }
        
        override var scrollViewBottomInset: CGFloat {
            return max(super.scrollViewBottomInset, keyboardHeight - self.view.safeAreaInsets.bottom + 32.0)
        }
        
        override var scrollViewBottomIndicatorInset: CGFloat {
            return max(super.scrollViewBottomInset, keyboardHeight - self.view.safeAreaInsets.bottom)
        }
        
        override var step: Step {
            
            let learnMoreURL = URL(string: "learn-more:")!
            
            let text = NSMutableAttributedString(string: NSLocalizedString("VERIFICATION_IDENTIFIER_TEXT", comment: "Text"),
                                                 attributes: Step.bodyTextAttributes)
            text.replaceCharacters(in: (text.string as NSString).range(of: "%@"),
                                   with: NSAttributedString(string: NSLocalizedString("LEARN_MORE", comment: "Button"),
                                                            attributes: Step.linkTextAttributes(learnMoreURL)))
            
            return Step(
                rightBarButton: .init(item: .cancel) {
                    TestVerificationViewController.cancel(from: self)
                },
                title: NSLocalizedString("VERIFICATION_IDENTIFIER_TITLE", comment: "Title"),
                text: text,
                urlHandler: { url, interaction in
                    if interaction == .invokeDefaultAction {
                        switch url {
                        case learnMoreURL:
                            let navigationController = StepNavigationController(rootViewController: AboutTestIdentifiersViewController.make())
                            self.present(navigationController, animated: true, completion: nil)
                            return false
                        default:
                            preconditionFailure()
                        }
                    } else {
                        return false
                    }
                },
                customView: customStackView,
                buttons: [Step.Button(title: NSLocalizedString("NEXT", comment: "Button"),
                                      isProminent: true,
                                      isEnabled: isViewLoaded ? entryView.text.count == entryView.numberOfDigits : false,
                                      action: {
                                        // Confirm entryView.text is valid
                                        Server.shared.verifyUniqueTestIdentifier(self.entryView.text) { result in
                                            switch result {
                                            case let .success(valid):
                                                if valid {
                                                    self.show(TestAdministrationDateViewController.make(testResultID: self.testResultID), sender: nil)
                                                } else {
                                                    let alertController = UIAlertController(
                                                        title: NSLocalizedString("VERIFICATION_IDENTIFIER_INVALID", comment: "Alert title"),
                                                        message: nil,
                                                        preferredStyle: .alert
                                                    )
                                                    alertController.addAction(.init(title: NSLocalizedString("OK", comment: "Button"),
                                                                                    style: .cancel, handler: nil))
                                                    self.present(alertController, animated: true, completion: nil)
                                                }
                                            case let .failure(error):
                                                showError(error, from: self)
                                            }
                                        }
                })]
            )
        }
    }
    
    class AboutTestIdentifiersViewController: StepViewController {
        override var step: Step {
            Step(
                rightBarButton: .init(item: .done) {
                    self.dismiss(animated: true, completion: nil)
                },
                title: NSLocalizedString("VERIFICATION_IDENTIFIER_ABOUT_TITLE", comment: "Title"),
                text: NSLocalizedString("VERIFICATION_IDENTIFIER_ABOUT_TEXT", comment: "Text"),
                isModal: false
            )
        }
    }
    
    class TestAdministrationDateViewController: TestStepViewController {
        
        var datePicker: UIDatePicker!
        
        override var step: Step {
            Step(
                rightBarButton: .init(item: .cancel) {
                    TestVerificationViewController.cancel(from: self)
                },
                title: NSLocalizedString("VERIFICATION_ADMINISTRATION_DATE_TITLE", comment: "Title"),
                text: NSLocalizedString("VERIFICATION_ADMINISTRATION_DATE_TEXT", comment: "Text"),
                customView: datePicker,
                buttons: [Step.Button(title: NSLocalizedString("NEXT", comment: "Button"), isProminent: true, action: {
                    self.show(ReviewViewController.make(testResultID: self.testResultID), sender: nil)
                })]
            )
        }
        
        override func viewDidLoad() {
            datePicker = UIDatePicker()
            datePicker.addTarget(self, action: #selector(datePickerValueChanged), for: .valueChanged)
            datePicker.datePickerMode = .date
            datePicker.maximumDate = Date()
            
            super.viewDidLoad()
        }
        
        @objc
        func datePickerValueChanged() {
            self.testResult.dateAdministered = datePicker.date
        }
    }
    
    class ReviewViewController: TestStepViewController, UITableViewDelegate {
        
        enum Section: Hashable {
            case main
        }
        enum Item: Hashable {
            case diagnosis
            case administrationDate
        }
        
        var dataSource: UITableViewDiffableDataSource<Section, Item>!
        var tableView: UITableView!
        
        override var step: Step {
            Step(
                rightBarButton: .init(item: .cancel) {
                    TestVerificationViewController.cancel(from: self)
                },
                title: NSLocalizedString("VERIFICATION_REVIEW_TITLE", comment: "Title"),
                text: NSLocalizedString("VERIFICATION_REVIEW_TEXT", comment: "Text"),
                customView: tableView,
                isModal: false,
                buttons: [Step.Button(title: NSLocalizedString("TEST_RESULT_SHARE", comment: "Button"), isProminent: true, action: {
                    // In this reference implementation, we don't set a transmissionRiskLevel for any of the diagnosis keys. However, it is at this
                    // point that you could use information accumulated in the TestResult instance to determine a transmissionRiskLevel for the
                    // diagnosis keys, and different levels may be specified for keys from different days.
                    ExposureManager.shared.getAndPostDiagnosisKeys { error in
                        if let error = error as? ENError, error.code == .notAuthorized {
                            self.saveAndFinish()
                        } else if let error = error {
                            showError(error, from: self)
                            self.saveAndFinish()
                        } else {
                            self.testResult.isShared = true
                            self.saveAndFinish()
                        }
                    }
                })]
            )
        }
        
        class Cell: UITableViewCell {
            override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
                super.init(style: .value1, reuseIdentifier: reuseIdentifier)
                textLabel!.font = .preferredFont(forTextStyle: .body)
                textLabel!.adjustsFontForContentSizeCategory = true
                detailTextLabel!.font = .preferredFont(forTextStyle: .body)
                detailTextLabel!.adjustsFontForContentSizeCategory = true
            }
            
            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
        }
        
        override func viewDidLoad() {
            tableView = UITableView()
            tableView.register(Cell.self, forCellReuseIdentifier: "Cell")
            tableView.delegate = self
            tableView.alwaysBounceVertical = false
            
            dataSource = UITableViewDiffableDataSource<Section, Item>(tableView: tableView, cellProvider: { tableView, indexPath, row in
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
                switch row {
                case .diagnosis:
                    cell.textLabel!.text = NSLocalizedString("TEST_RESULT_DIAGNOSIS", comment: "Label")
                    cell.detailTextLabel!.text = NSLocalizedString("TEST_RESULT_DIAGNOSIS_POSITIVE", comment: "Value")
                case .administrationDate:
                    cell.textLabel!.text = NSLocalizedString("TEST_RESULT_ADMINISTRATION_DATE", comment: "Label")
                    cell.detailTextLabel!.text = DateFormatter.localizedString(from: self.testResult.dateAdministered,
                                                                               dateStyle: .long, timeStyle: .none)
                }
                return cell
            })
            var snapshot = dataSource.snapshot()
            snapshot.appendSections([.main])
            snapshot.appendItems([.diagnosis, .administrationDate], toSection: .main)
            dataSource.apply(snapshot)
            
            super.viewDidLoad()
            
            tableView.reloadData()
            NSLayoutConstraint.activate([
                tableView.widthAnchor.constraint(equalTo: view.widthAnchor),
                tableView.heightAnchor.constraint(equalTo: tableView.cellForRow(at: IndexPath(row: 0, section: 0))!.heightAnchor,
                                                  multiplier: 2.0)
            ])
        }
        
        func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
            return false
        }
        
        func saveAndFinish() {
            testResult.isAdded = true
            show(FinishedViewController.make(testResultID: testResultID), sender: nil)
        }
    }
    
    static func cancel(from viewController: TestStepViewController) {
        let testResult = viewController.testResult
        if !testResult.isAdded {
            LocalStore.shared.testResults.removeValue(forKey: testResult.id)
        }
        viewController.dismiss(animated: true, completion: nil)
    }
    
    class FinishedViewController: TestStepViewController {
        override var step: Step {
            return Step(
                hidesNavigationBackButton: true,
                title: testResult.isShared ?
                    NSLocalizedString("VERIFICATION_SHARED_TITLE", comment: "Title") :
                    NSLocalizedString("VERIFICATION_NOT_SHARED_TITLE", comment: "Title"),
                text: testResult.isShared ?
                    NSLocalizedString("VERIFICATION_SHARED_TEXT", comment: "Text") :
                    NSLocalizedString("VERIFICATION_NOT_SHARED_TEXT", comment: "Text"),
                buttons: [Step.Button(title: NSLocalizedString("DONE", comment: "Button"), isProminent: true, action: {
                    self.dismiss(animated: true, completion: nil)
                })]
            )
        }
    }
}
