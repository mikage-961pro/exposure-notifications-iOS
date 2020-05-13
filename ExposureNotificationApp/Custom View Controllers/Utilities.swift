/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Code that displays a UIAlert for a view controller or opens Settings.
*/

import UIKit

func showError(_ error: Error, from viewController: UIViewController) {
    let alert = UIAlertController(title: NSLocalizedString("ERROR", comment: "Title"), message: error.localizedDescription, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Button"), style: .cancel))
    viewController.present(alert, animated: true, completion: nil)
}

func openSettings(from viewController: UIViewController) {
    viewController.view.window?.windowScene?.open(URL(string: UIApplication.openSettingsURLString)!, options: nil, completionHandler: nil)
}
