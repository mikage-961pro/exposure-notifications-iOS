/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controllers used when users receive notification that they may have been exposed by someone they came in contact with.
*/

import UIKit

class ExposureNotificationsInfoViewController: StepNavigationController {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        pushViewController(ContentViewController.make(), animated: false)
    }
    
    class ContentViewController: StepViewController {
        var requirementsView: RequirementView!
        
        override var step: Step {
            
            let settingsURL = URL(string: UIApplication.openSettingsURLString)!
            let learnMoreURL = URL(string: "learn-more:")!
            
            let text = NSMutableAttributedString(string: NSLocalizedString("EXPOSURE_INFO_TEXT", comment: "Text"),
                                                 attributes: Step.bodyTextAttributes)
            text.replaceCharacters(in: (text.string as NSString).range(of: "%@"),
                                   with: NSAttributedString(string: NSLocalizedString("SETTINGS", comment: "Button"),
                                                            attributes: Step.linkTextAttributes(settingsURL)))
            text.replaceCharacters(in: (text.string as NSString).range(of: "%@"),
                                   with: NSAttributedString(string: NSLocalizedString("LEARN_MORE", comment: "Button"),
                                                            attributes: Step.linkTextAttributes(learnMoreURL)))
            
            return Step(
                rightBarButton: .init(item: .done) {
                    self.dismiss(animated: true, completion: nil)
                },
                title: NSLocalizedString("EXPOSURE_INFO_TITLE", comment: "Title"),
                text: text,
                urlHandler: { url, interaction in
                    if interaction == .invokeDefaultAction {
                        switch url {
                        case settingsURL:
                            return true
                        case learnMoreURL:
                            self.navigationController!.performSegue(withIdentifier: "ShowExposureNotificationsPrivacy", sender: nil)
                            return false
                        default:
                            preconditionFailure()
                        }
                    } else {
                        return false
                    }
                },
                customView: requirementsView,
                isModal: false
            )
        }
        
        override func viewDidLoad() {
            requirementsView = RequirementView(text: NSLocalizedString("EXPOSURE_INFO_REQUIREMENT_TEXT", comment: "Requirement text"))
            super.viewDidLoad()
        }
    }
}

class ExposureNotificationsPrivacyViewController: StepNavigationController {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        pushViewController(ContentViewController.make(), animated: false)
    }
    
    class ContentViewController: StepViewController {
        override var step: Step {
            Step(
                rightBarButton: .init(item: .done) {
                    self.dismiss(animated: true, completion: nil)
                },
                title: NSLocalizedString("EXPOSURE_ABOUT_TITLE", comment: "Title"),
                text: NSLocalizedString("EXPOSURE_ABOUT_TEXT", comment: "Text"),
                isModal: false
            )
        }
    }
}
