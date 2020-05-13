/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller that manages the process of notifying others about a positive diagnosis.
*/

import UIKit
import ExposureNotification

class NotifyOthersViewController: UITableViewController {
    
    var observers = [NSObjectProtocol]()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        observers.append(NotificationCenter.default.addObserver(forName: ExposureManager.authorizationStatusChangeNotification,
                                                                object: nil, queue: nil) { [unowned self] notification in
            self.updateTableView(animated: true, reloadingOverview: true)
        })
        
        observers.append(LocalStore.shared.$testResults.addObserver { [unowned self] in
            self.updateTableView(animated: true)
        })
    }
    
    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    enum Section: Int {
        case overview
        case testResults
    }
    
    enum Item: Hashable {
        case overviewAction
        case testResult(id: UUID)
    }
    
    class DataSource: UITableViewDiffableDataSource<Section, Item> {
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            switch snapshot().sectionIdentifiers[section] {
            case .testResults:
                return NSLocalizedString("POSITIVE_DIAGNOSES", comment: "Header")
            default:
                return nil
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch dataSource.snapshot().sectionIdentifiers[section] {
        case .overview:
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "OverviewHeader") as! TableHeaderView
            switch ENManager.authorizationStatus {
            case .authorized:
                header.headerText = NSLocalizedString("NOTIFY_OTHERS_HEADER", comment: "Header")
                header.text = NSLocalizedString("NOTIFY_OTHERS_DESCRIPTION", comment: "Header")
                header.buttonText = NSLocalizedString("LEARN_MORE", comment: "Button")
                header.buttonAction = { [unowned self] in
                    self.performSegue(withIdentifier: "ShowLearnMore", sender: nil)
                }
            case .unknown:
                header.headerText = NSLocalizedString("EXPOSURE_NOTIFICATION_OFF", comment: "Header")
                header.text = NSLocalizedString("NOTIFY_OTHERS_DISABLED_DIRECTIONS", comment: "Header")
            default:
                header.headerText = NSLocalizedString("EXPOSURE_NOTIFICATION_OFF", comment: "Header")
                header.text = NSLocalizedString("NOTIFY_OTHERS_DENIED_DIRECTIONS", comment: "Header")
            }
            return header
        default:
            return nil
        }
    }
    
    var dataSource: DataSource!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(TableHeaderView.self, forHeaderFooterViewReuseIdentifier: "OverviewHeader")
        dataSource = DataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
            switch item {
            case .overviewAction:
                let cell = tableView.dequeueReusableCell(withIdentifier: "Action", for: indexPath)
                switch ENManager.authorizationStatus {
                case .authorized:
                    cell.textLabel!.text = NSLocalizedString("NOTIFY_OTHERS_ACTION", comment: "Button")
                case .unknown:
                    cell.textLabel!.text = NSLocalizedString("EXPOSURE_NOTIFICATION_DISABLED_ACTION", comment: "Button")
                default:
                    cell.textLabel!.text = NSLocalizedString("GO_TO_SETTINGS", comment: "Button")
                }
                return cell
            case let .testResult(id):
                let cell = tableView.dequeueReusableCell(withIdentifier: "TestResult", for: indexPath)
                let testResult = LocalStore.shared.testResults[id]!
                let dateString = DateFormatter.localizedString(from: testResult.dateAdministered, dateStyle: .long, timeStyle: .none)
                let sharedColor = testResult.isShared ? UIColor.systemGreen : UIColor.systemRed
                cell.textLabel!.text = NSLocalizedString("TEST_RESULT_DIAGNOSIS_POSITIVE", comment: "Value")
                let detailString = NSMutableAttributedString(string: "%@ – %@", attributes: [
                    .font: UIFont.preferredFont(forTextStyle: .caption1),
                    .foregroundColor: UIColor.secondaryLabel
                ])
                detailString.replaceCharacters(in: (detailString.string as NSString).range(of: "%@"), with: dateString)
                detailString.replaceCharacters(in: (detailString.string as NSString).range(of: "%@"),
                                               with: NSAttributedString(string: testResult.isShared ?
                                                NSLocalizedString("TEST_RESULT_STATE_SHARED", comment: "Value") :
                                                NSLocalizedString("TEST_RESULT_STATE_NOT_SHARED", comment: "Value"),
                                                                        attributes: [
                                                                            .font: UIFont.preferredFont(forTextStyle: .caption1),
                                                                            .foregroundColor: sharedColor]))
                cell.detailTextLabel!.attributedText = detailString
                return cell
            }
        })
        dataSource.defaultRowAnimation = .fade
        updateTableView(animated: false)
    }
    
    func updateTableView(animated: Bool, reloadingOverview: Bool = false) {
        guard isViewLoaded else { return }
        var snapshot = dataSource.snapshot()
        snapshot.deleteAllItems()
        snapshot.appendSections([.overview])
        snapshot.appendItems([.overviewAction], toSection: .overview)
        if reloadingOverview {
            snapshot.reloadSections([.overview])
        }
        let testResults = LocalStore.shared.testResults.filter { $0.value.isAdded }
        if !testResults.isEmpty {
            snapshot.appendSections([.testResults])
            let sortedTestResults = testResults.values.sorted { testResult1, testResult2 in
                return testResult1.dateAdministered > testResult2.dateAdministered
            }
            snapshot.appendItems(sortedTestResults.map { .testResult(id: $0.id) }, toSection: .testResults)
        }
        dataSource.apply(snapshot, animatingDifferences: tableView.window != nil ? animated : false)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch dataSource.itemIdentifier(for: indexPath)! {
        case .overviewAction:
            tableView.deselectRow(at: indexPath, animated: true)
            switch ENManager.authorizationStatus {
            case .authorized:
                performSegue(withIdentifier: "ShowTestVerification", sender: nil)
            case .unknown:
                performSegue(withIdentifier: "ShowOnboarding", sender: nil)
            default:
                openSettings(from: self)
            }
        case .testResult:
            performSegue(withIdentifier: "ShowTestResultDetails", sender: nil)
        }
    }
    
    @IBSegueAction func showOnboarding(_ coder: NSCoder) -> OnboardingViewController? {
        return OnboardingViewController(rootViewController: OnboardingViewController.EnableExposureNotificationsViewController.make(), coder: coder)
    }
    
    @IBSegueAction func showLearnMore(_ coder: NSCoder) -> OnboardingViewController? {
        return OnboardingViewController(rootViewController: OnboardingViewController.NotifyingOthersViewController.make(independent: true),
                                        coder: coder)
    }
    
    @IBSegueAction func showTestResultDetails(_ coder: NSCoder) -> TestResultDetailsViewController? {
        switch dataSource.itemIdentifier(for: tableView.indexPathForSelectedRow!)! {
        case let .testResult(id: id):
            return TestResultDetailsViewController(testResultID: id, coder: coder)
        default:
            preconditionFailure()
        }
    }
}
