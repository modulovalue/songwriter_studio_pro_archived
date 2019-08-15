import UIKit

@objc class SettingsView: UITabBarController {

    var projectManager: ProjectManagerProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        let menuItem = UIBarButtonItem(title: "Menu", style: .done, target: self, action: #selector(SettingsView.menu))
        self.navigationController?.navigationBar.topItem?.rightBarButtonItem = menuItem
        self.navigationController?.navigationBar.topItem?.title = "Settings"
        extendedLayoutIncludesOpaqueBars = true
    }

    @objc func menu() {
        (navigationController as? NavigationController)?.showMenu()
    }

    func showMenu() {
        (navigationController as? NavigationController)?.showMenu()
    }

}
