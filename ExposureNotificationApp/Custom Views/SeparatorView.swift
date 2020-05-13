/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view with an intrinsic height of one pixel.
*/

import UIKit

class SeparatorView: UIView {
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 1.0 / traitCollection.displayScale)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        invalidateIntrinsicContentSize()
    }
}
