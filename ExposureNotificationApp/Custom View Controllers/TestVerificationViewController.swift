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
    
    init?<CustomItem: Hashable>(rootViewController: TestStepViewController<CustomItem>, coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        pushViewController(rootViewController, animated: false)
    }
    
    class TestStepViewController<CustomItem: Hashable>: ValueStepViewController<UUID, CustomItem> {
        var testResultID: UUID { value }
        var testResult: TestResult {
            get { LocalStore.shared.testResults[value]! }
            set { LocalStore.shared.testResults[value] = newValue }
        }
        static func make(testResultID: UUID) -> Self {
            return make(value: testResultID)
        }
    }
    
    class BeforeYouGetStartedViewController: TestStepViewController<Never> {
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
        }
    }
    
    class TestIdentifierViewController: TestStepViewController<Never> {
        
        var customStackView: UIStackView!
        var entryView: EntryView!
        
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
    
    class TestAdministrationDateViewController: TestStepViewController<TestAdministrationDateViewController.CustomItem> {
        
        var date: Date? {
            didSet {
                updateTableView(animated: true, reloading: [.custom(.date)])
                updateButtons()
            }
        }
        
        var showingDatePicker = false {
            didSet {
                updateTableView(animated: true)
            }
        }
        
        enum CustomItem: Hashable {
            case date
            case datePicker
        }
        
        override var step: Step {
            Step(
                rightBarButton: .init(item: .cancel) {
                    TestVerificationViewController.cancel(from: self)
                },
                title: NSLocalizedString("VERIFICATION_ADMINISTRATION_DATE_TITLE", comment: "Title"),
                text: NSLocalizedString("VERIFICATION_ADMINISTRATION_DATE_TEXT", comment: "Text"),
                buttons: [Step.Button(title: NSLocalizedString("NEXT", comment: "Button"), isProminent: true, isEnabled: self.date != nil, action: {
                    self.testResult.dateAdministered = self.date!
                    self.show(ReviewViewController.make(testResultID: self.testResultID), sender: nil)
                })]
            )
        }
        
        override func viewDidLoad() {
            tableView.register(UINib(nibName: "TestAdministrationDateCell", bundle: nil), forCellReuseIdentifier: "Date")
            tableView.register(UINib(nibName: "TestAdministrationDatePickerCell", bundle: nil), forCellReuseIdentifier: "DatePicker")
            super.viewDidLoad()
        }
        
        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, customItem: CustomItem) -> UITableViewCell {
            switch customItem {
            case .date:
                let cell = tableView.dequeueReusableCell(withIdentifier: "Date", for: indexPath)
                cell.textLabel!.text = NSLocalizedString("VERIFICATION_ADMINISTRATION_DATE_LABEL", comment: "Label")
                if let date = date {
                    cell.detailTextLabel!.text = DateFormatter.localizedString(from: date, dateStyle: .long, timeStyle: .none)
                } else {
                    cell.detailTextLabel!.text = NSLocalizedString("VERIFICATION_ADMINISTRATION_DATE_NOT_SET", comment: "Value")
                }
                return cell
            case .datePicker:
                let cell = tableView.dequeueReusableCell(withIdentifier: "DatePicker", for: indexPath) as! TestAdministrationDatePickerCell
                cell.datePicker.maximumDate = Date()
                cell.datePicker.addTarget(self, action: #selector(datePickerValueChanged(_:)), for: .valueChanged)
                return cell
            }
        }
        
        override func modifySnapshot(_ snapshot: inout NSDiffableDataSourceSnapshot<Section, Item>) {
            snapshot.appendItems([.custom(.date)], toSection: .main)
            if showingDatePicker {
                snapshot.appendItems([.custom(.datePicker)], toSection: .main)
            }
        }
        
        override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
            switch dataSource.itemIdentifier(for: indexPath) {
            case .custom(.date):
                return true
            default:
                return super.tableView(tableView, shouldHighlightRowAt: indexPath)
            }
        }
        
        override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            switch dataSource.itemIdentifier(for: indexPath) {
            case .custom(.date):
                tableView.deselectRow(at: indexPath, animated: true)
                showingDatePicker.toggle()
            default:
                super.tableView(tableView, didSelectRowAt: indexPath)
            }
        }
        
        @objc
        func datePickerValueChanged(_ datePicker: UIDatePicker) {
            date = datePicker.date
        }
    }
    
    class ReviewViewController: TestStepViewController<ReviewViewController.CustomItem> {
        
        enum CustomItem: Hashable {
            case diagnosis
            case administrationDate
        }
        
        override var step: Step {
            Step(
                rightBarButton: .init(item: .cancel) {
                    TestVerificationViewController.cancel(from: self)
                },
                title: NSLocalizedString("VERIFICATION_REVIEW_TITLE", comment: "Title"),
                text: NSLocalizedString("VERIFICATION_REVIEW_TEXT", comment: "Text"),
                isModal: false,
                buttons: [Step.Button(title: NSLocalizedString("TEST_RESULT_SHARE", comment: "Button"), isProminent: true, action: {
                    ExposureManager.shared.getAndPostDiagnosisKeys(testResult: self.testResult) { error in
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
        
        override func viewDidLoad() {
            tableView.register(UINib(nibName: "TestReviewCell", bundle: nil), forCellReuseIdentifier: "Cell")
            super.viewDidLoad()
        }
        
        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, customItem: CustomItem) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            switch customItem {
            case .diagnosis:
                cell.textLabel!.text = NSLocalizedString("TEST_RESULT_DIAGNOSIS", comment: "Label")
                cell.detailTextLabel!.text = NSLocalizedString("TEST_RESULT_DIAGNOSIS_POSITIVE", comment: "Value")
            case .administrationDate:
                cell.textLabel!.text = NSLocalizedString("TEST_RESULT_ADMINISTRATION_DATE", comment: "Label")
                cell.detailTextLabel!.text = DateFormatter.localizedString(from: self.testResult.dateAdministered, dateStyle: .long, timeStyle: .none)
            }
            return cell
        }
        
        override func modifySnapshot(_ snapshot: inout NSDiffableDataSourceSnapshot<Section, Item>) {
            snapshot.appendItems([.custom(.diagnosis), .custom(.administrationDate)], toSection: .main)
        }
        
        func saveAndFinish() {
            testResult.isAdded = true
            show(FinishedViewController.make(testResultID: testResultID), sender: nil)
        }
    }
    
    static func cancel<CustomItem: Hashable>(from viewController: TestStepViewController<CustomItem>) {
        let testResult = viewController.testResult
        if !testResult.isAdded {
            LocalStore.shared.testResults.removeValue(forKey: testResult.id)
        }
        viewController.dismiss(animated: true, completion: nil)
    }
    
    class FinishedViewController: TestStepViewController<Never> {
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

class TestAdministrationDatePickerCell: StepOptionalSeparatorCell {
    @IBOutlet var datePicker: UIDatePicker!
}
