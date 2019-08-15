import UIKit

class NavigationController: UINavigationController {

    var menu: MediumMenu?
    var mainScreen: MainScreen?
    var projectManager: ProjectManager = ProjectManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMenu()
    }

    func setupMenu() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let session = MediumMenuItem(title: "Session") {
            self.loadSession(storyboard: storyboard)
        }
        let gallery = MediumMenuItem(title: "Gallery") {
            self.loadGallery(storyboard: storyboard)
        }
        let settings = MediumMenuItem(title: "Settings") {
            self.loadSettings(storyboard: storyboard)
        }
        let share = MediumMenuItem(title: "Share") {
            self.loadShare(storyboard: storyboard)
        }
        menu = MediumMenu(items: [gallery, session, settings, share], forViewController: self)
        loadGallery(storyboard: storyboard)
    }

    func loadSession(storyboard: UIStoryboard) {
        doWhenProjectLoaded {
            if mainScreen == nil {
                mainScreen = storyboard.instantiateViewController(withIdentifier: "MainScreen") as? MainScreen
            }
            if (mainScreen != nil) {
                mainScreen?.dataSource = projectManager.playlist
                mainScreen?.delegate = projectManager.playlist
                setNavigationBarHidden(true, animated: false)
                self.changeTransitionAnimation()
                self.setViewControllers([self.mainScreen!], animated: false)
            } else {
                displayErrorMessage()
            }
        }
    }

    func loadGallery(storyboard: UIStoryboard) {
        if let vc = storyboard.instantiateViewController(withIdentifier: "GalleryView") as? GalleryView {
            vc.projectManager = self.projectManager
            setNavigationBarHidden(true, animated: false)
            self.changeTransitionAnimation()
            self.setViewControllers([vc], animated: false)
        } else {
            displayErrorMessage()
        }
    }

    func loadSettings(storyboard: UIStoryboard) {
        if let vc = storyboard.instantiateViewController(withIdentifier: "SettingsView") as? SettingsView {
            vc.projectManager = self.projectManager
            setNavigationBarHidden(true, animated: false)
            self.changeTransitionAnimation()
            self.setViewControllers([vc], animated: false)
        } else {
            displayErrorMessage()
        }
    }

    func loadShare(storyboard: UIStoryboard) {
        doWhenProjectLoaded {
            if let vc = storyboard.instantiateViewController(withIdentifier: "ShareView") as? ShareViewController {
                vc.projectManager = self.projectManager
                setNavigationBarHidden(true, animated: false)
                self.changeTransitionAnimation()
                self.setViewControllers([vc], animated: false)
            } else {
                displayErrorMessage()
            }
        }
    }

    func doWhenProjectLoaded(isLoaded: () -> Void) {
        if projectManager.isProjectLoaded() {
            isLoaded()
        } else {
            let alarm = UIAlertController(title: "No project loaded", message: "Please open a project in the gallery", preferredStyle: UIAlertControllerStyle.alert)
            alarm.addAction(UIKit.UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in }))
            self.present(alarm, animated: true, completion: nil)
            return
        }
    }

    func changeTransitionAnimation() {
        let transition = CATransition()
        transition.duration = 0.3
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
        transition.type = kCATransitionFade
        self.view.layer.add(transition, forKey: nil)
    }

    func showMenu() {
        menu?.show()
    }

    func displayErrorMessage() {
        let alarm = UIAlertController(title: "An Error has occurred", message: "", preferredStyle: UIAlertControllerStyle.alert)
        alarm.addAction(UIKit.UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in }))
        self.present(alarm, animated: true, completion: nil)
    }

    func openProject(_ data: ProjectInformation) {
        print("open project")
    }

    func shareProject(_ data: ProjectInformation) {
        print("open project")
    }

    func deleteProject(_ data: ProjectInformation) {
        do {
            try self.projectManager.deleteProject(project: data)
        } catch {
            //todo add handling
            print("error deleting project")
        }
    }
}

extension UINavigationBar {
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.size.width, height: 60)
    }
}
