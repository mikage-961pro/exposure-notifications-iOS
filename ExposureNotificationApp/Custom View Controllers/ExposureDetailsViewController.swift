/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller that shows details for a single exposure event.
*/

import UIKit

class ExposureDetailsViewController: ValueStepViewController<Exposure> {
    
    var exposureDetailsView: ExposureDetailsView!
    
    static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        formatter.formattingContext = .dynamic
        return formatter
    }()
    
    override func viewDidLoad() {
        let nib = UINib(nibName: "ExposureDetailsView", bundle: nil)
        exposureDetailsView = (nib.instantiate(withOwner: nil, options: nil).first as! ExposureDetailsView)
        let dataString = DateFormatter.localizedString(from: value.date, dateStyle: .long, timeStyle: .none)
        exposureDetailsView.exposureDateLabel.text = String(format: NSLocalizedString("EXPOSURE_DETAILS_DATE_TEXT", comment: "Text"), dataString)
        exposureDetailsView.learnMoreButton.addTarget(self, action: #selector(learnMore), for: .touchUpInside)
        super.viewDidLoad()
        NSLayoutConstraint.activate([
            exposureDetailsView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            exposureDetailsView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
        ])
    }
    
    override var step: Step {
        let daysAgo = Calendar.current.dateComponents([.day], from: Date(), to: value.date)
        let daysAgoString = ExposureDetailsViewController.relativeDateFormatter.localizedString(from: daysAgo)
        return Step(
            rightBarButton: .init(item: .done) {
                self.dismiss(animated: true, completion: nil)
            },
            title: NSLocalizedString("EXPOSURE_DETAILS_TITLE", comment: "Title"),
            text: String(format: NSLocalizedString("EXPOSURE_DETAILS_TEXT", comment: "Text"), daysAgoString),
            customView: exposureDetailsView,
            isModal: false
        )
    }
    
    @objc
    func learnMore() {
        let navigationController = StepNavigationController(rootViewController: ExposureLearnMoreViewController.make())
        present(navigationController, animated: true, completion: nil)
    }
}

class ExposureLearnMoreViewController: StepViewController {
    override var step: Step {
        Step(
            rightBarButton: .init(item: .done) {
                self.dismiss(animated: true, completion: nil)
            },
            title: NSLocalizedString("EXPOSURE_DETAILS_LEARN_TITLE", comment: "Title"),
            text: NSLocalizedString("EXPOSURE_DETAILS_LEARN_TEXT", comment: "Text"),
            isModal: false
        )
    }
}

class ExposureDetailsView: UIView {
    @IBOutlet var exposureDateLabel: UILabel!
    @IBOutlet var learnMoreButton: UIButton!
}
