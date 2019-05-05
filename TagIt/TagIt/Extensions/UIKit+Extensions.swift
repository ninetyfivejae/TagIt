import UIKit
import Foundation

extension UICollectionView {
	
	func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
		let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
		return allLayoutAttributes.map { $0.indexPath }
	}
	
}

extension UIViewController {
	
	func clearStatusBar() {
		let statusBar = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView
		statusBar?.backgroundColor = .clear
	}
	
	func clearNavigationBar() {
		self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
		self.navigationController?.navigationBar.shadowImage = UIImage()
		self.navigationController?.navigationBar.isTranslucent = true
		self.navigationController?.navigationBar.backgroundColor = .clear
	}
	
	func clearToolbar() {
		self.navigationController?.toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .bottom, barMetrics: UIBarMetrics.default)
		self.navigationController?.toolbar.isTranslucent = true
		self.navigationController?.toolbar.setShadowImage(UIImage(), forToolbarPosition: .bottom)
		self.navigationController?.toolbar.backgroundColor = .clear
	}
	
	static var instance: UIViewController {
		return UIStoryboard(name: self.className, bundle: nil).instantiateInitialViewController()!
	}
	
	func startRightBarIndicatorAnimating(style: UIActivityIndicatorView.Style = .gray) {
		let indicator = UIActivityIndicatorView(style: style)
		indicator.startAnimating()
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: indicator)
	}
	
	func stopRightBarIndicatorAnimating() {
		if
			let rightBarButtonItem = self.navigationItem.rightBarButtonItem,
			let indicator = rightBarButtonItem.customView as? UIActivityIndicatorView {
			indicator.stopAnimating()
			self.navigationItem.rightBarButtonItem = nil
		}
	}
	
	func alert(title: String = "Just Tag It",
						 message: String, okTitle: String = "확인", okAction: (() -> Swift.Void)? = nil) {
		DispatchQueue.main.async {
			let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
			let okAction = UIAlertAction(title: okTitle, style: .cancel) { _ in
				guard let action = okAction else { return }
				action()
			}
			
			alert.addAction(okAction)
			alert.view.tintColor = UIColor.periwinkle
			self.present(alert, animated: true, completion: { alert.view.tintColor = UIColor.periwinkle })
		}
	}
	
	func alert(title: String = "Just Tag It", message: String,
						 okTitle: String,
						 cancelTitle: String = "취소",
						 okAction: @escaping () -> Void) {
		DispatchQueue.main.async {
			let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
			let okAction = UIAlertAction(title: okTitle, style: UIAlertAction.Style.default) { _ in okAction() }
			let cancelAction = UIAlertAction(title: cancelTitle, style: UIAlertAction.Style.cancel) { _ in  }
			
			alert.addAction(cancelAction)
			alert.addAction(okAction)
			alert.view.tintColor = UIColor.periwinkle
			self.present(alert, animated: true, completion: { alert.view.tintColor = UIColor.periwinkle })
		}
	}
	
	func alert(message: String,
						 okTitle: String,
						 cancelTitle: String = "취소",
						 okAction: @escaping () -> Void,
						 cancelAction: @escaping () -> Void) {
		DispatchQueue.main.async {
			let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
			let okAction = UIAlertAction(title: okTitle, style: UIAlertAction.Style.default) { _ in okAction() }
			let cancelAction = UIAlertAction(title: cancelTitle, style: UIAlertAction.Style.cancel) { _ in cancelAction() }
			
			alert.addAction(cancelAction)
			alert.addAction(okAction)
			alert.view.tintColor = UIColor.periwinkle
			self.present(alert, animated: true, completion: { alert.view.tintColor = UIColor.periwinkle })
		}
	}
	
	func actionSheet(title: String = "Just Tag It",
									 message: String? = nil,
									 cancelTitle: String? = "Cancel",
									 cancelStyle: UIAlertAction.Style = .cancel,
									 actions: [(title: String, action: ((UIAlertAction) -> Void))]) {
		let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
		actions.forEach {
			alertController.addAction(UIAlertAction(title: $0.title, style: .default, handler: $0.action))
		}
		
		alertController.addAction(UIAlertAction(title: cancelTitle, style: cancelStyle, handler: { _ in
			alertController.dismiss(animated: true)
		}))
		
		self.present(alertController, animated: true)
	}
	
	static let indicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.whiteLarge)
	static let indicatorLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 20))
	
	func startIndicator(labelText: String = "") {
		if UIViewController.indicator.superview == nil {
			UIViewController.indicator.removeFromSuperview()
			UIViewController.indicator.alpha = 0.0
			UIViewController.indicator.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
			UIViewController.indicator.layer.cornerRadius = 10
			UIViewController.indicator.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
			UIViewController.indicator.center = self.view.center
			UIViewController.indicator.clipsToBounds = true
			UIViewController.indicator.startAnimating()
			self.view.addSubview(UIViewController.indicator)
		}
		
		UIViewController.indicatorLabel.center.x = self.view.center.x
		UIViewController.indicatorLabel.center.y = self.view.center.y + 55
		UIViewController.indicatorLabel.text = labelText
		UIViewController.indicatorLabel.font = UIFont(name: "AppleSDGothicNeo-Light", size: 14.0)
		UIViewController.indicatorLabel.alpha = 0.0
		UIViewController.indicatorLabel.textColor = UIColor.darkText
		UIViewController.indicatorLabel.textAlignment = .center
		UIViewController.indicatorLabel.backgroundColor = UIColor.clear
		
		if UIViewController.indicatorLabel.superview == nil {
			self.view.addSubview(UIViewController.indicatorLabel)
		}
		
		UIView.animate(withDuration: 0.2,
									 delay: 0.2,
									 options: UIView.AnimationOptions.curveEaseIn,
									 animations: {
										UIViewController.indicator.alpha = 1.0
										UIViewController.indicatorLabel.alpha = 1.0
		})
	}
	
	func stopIndicator() {
		UIView.animate(withDuration: 0.2,
									 delay: 0.2,
									 options: UIView.AnimationOptions.curveEaseOut,
									 animations: {
										UIViewController.indicator.alpha = 0.0
										UIViewController.indicatorLabel.alpha = 0.0 },
									 completion: { _ in
										UIViewController.indicator.stopAnimating()
										UIViewController.indicator.removeFromSuperview()
										UIViewController.indicatorLabel.removeFromSuperview()
		})
	}
	
}

extension UILabel {
	
	func makeSubStringColored(subString: String, color: UIColor) {
		self.attributedText = (self.text ?? "").colored(range: ((self.text ?? "") as NSString).range(of: subString), color: color)
	}
	
	func makeSubStringColored(range: (location: Int, length: Int), color: UIColor) {
		self.attributedText = (self.text ?? "").colored(range: NSRange(location: range.location, length: range.length), color: color)
	}
	
}

extension UIFont {
	
	class func appleSDGothicNeoLight(size: CGFloat = 14) -> UIFont {
		return UIFont(name: "AppleSDGothicNeo-Light", size: size)!
	}
	
}

extension UITextView {
	
	func makeSubStringColored(subString: String, color: UIColor) {
		self.attributedText = (self.text ?? "").colored(range: ((self.text ?? "") as NSString).range(of: subString), color: color)
	}
	
	func makeSubStringColored(range: (location: Int, length: Int), color: UIColor) {
		self.attributedText = (self.text ?? "").colored(range: NSRange(location: range.location, length: range.length), color: color)
	}
	
}

extension UITextField {
	
	func makeSubStringColored(subString: String, color: UIColor) {
		self.attributedText = (self.text ?? "").colored(range: ((self.text ?? "") as NSString).range(of: subString), color: color)
	}
	
	func makeSubStringColored(range: (location: Int, length: Int), color: UIColor) {
		self.attributedText = (self.text ?? "").colored(range: NSRange(location: range.location, length: range.length), color: color)
	}
	
}
