import SpriteKit
import UIKit

// set projectManager bevor using
class GalleryView: UIViewController {

    @IBOutlet weak var tableview: UITableView!

    var projectManager: ProjectManagerProtocol? {
        didSet {
            refresh()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableview.backgroundColor = UIColor.darkGray
    }

    @IBAction func menuAction(_ sender: Any) {
        (navigationController as? NavigationController)?.showMenu()
    }

    @IBAction func addNewProject(_ sender: Any) {
        var name: String?
        var bpm: Double?
        self.getName {
            name = $0
            self.getBPM {
                do {
                    bpm = $0
                    try self.projectManager?.createNewProject(name: name!, bpm: bpm!)
                    self.refresh()
                } catch let error as NSError {
                    print("\(error)")
                }
            }
        }
    }

    func getName(name: @escaping (String) -> Void) {
        func configurationTextFieldName(textField: UITextField!) {
            textField.text = ""
        }
        let alert = UIAlertController(title: "Choose a name", message: "Choose a name for your new project", preferredStyle: UIAlertControllerStyle.alert)
        alert.addTextField(configurationHandler: configurationTextFieldName)
        alert.addAction(UIAlertAction(title: "Next", style: UIAlertActionStyle.default, handler:{ (UIAlertAction) in
            let n = alert.textFields?.first?.text
            if let manager = self.projectManager {
                if !manager.nameIsValid(n) {
                    let alarm = UIAlertController(title: "Please choose a different name", message: "Name invalid", preferredStyle: UIAlertControllerStyle.alert)
                    alarm.addAction(UIKit.UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in }))
                    self.present(alarm, animated: true, completion: nil)
                } else {
                    name(n!)
                }
            } else {
                let alarm = UIAlertController(title: "Error, nil", message: "", preferredStyle: UIAlertControllerStyle.alert)
                alarm.addAction(UIKit.UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in }))
                self.present(alarm, animated: true, completion: nil)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler:{ (UIAlertAction) in }))
        self.present(alert, animated: true, completion: nil)
    }

    func getBPM(bpm: @escaping (Double) -> Void) {
        func configurationTextFieldBPM(textField: UITextField!) {
            textField.text = "\(Double.INITBPM)"
            textField.keyboardType = .numberPad
        }
        let alert = UIAlertController(title: "Choose the BPM for your project", message: "Please keep it between 50 and 300 \n70 - slow \n 110 - normal \n 140 - fast", preferredStyle: UIAlertControllerStyle.alert)
        alert.addTextField(configurationHandler: configurationTextFieldBPM)
        alert.addAction(UIAlertAction(title: "Create", style: UIAlertActionStyle.default, handler:{ (UIAlertAction) in
            let newBPM = Double((alert.textFields?.first?.text)!)
            if newBPM != nil && newBPM! >= 50 && newBPM! <= 300 {
                bpm(newBPM!)
            } else {
                let alarm = UIAlertController(title: "Please choose a different BPM value", message: "BPM invalid", preferredStyle: UIAlertControllerStyle.alert)
                alarm.addAction(UIKit.UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in }))
                self.present(alarm, animated: true, completion: nil)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler:{ (UIAlertAction) in }))
        self.present(alert, animated: true, completion: nil)
    }

    func openProject(data: ProjectInformation) {
        (navigationController as? NavigationController)?.openProject(data)
        tableview.reloadData()
    }

    func shareProject(data: ProjectInformation) {
        (navigationController as? NavigationController)?.shareProject(data)
        tableview.reloadData()
    }

    func deleteProject(data: ProjectInformation) {
        let alarm = UIAlertController(title: "Are you sure you want to delete this project?", message: "This action can't be undone.", preferredStyle: UIAlertControllerStyle.alert)
        alarm.addAction(UIKit.UIAlertAction(title: "Delete", style: .default, handler: { (action: UIAlertAction!) in
            (self.navigationController as? NavigationController)?.deleteProject(data)
            self.tableview.reloadData()
        }))
        alarm.addAction(UIKit.UIAlertAction(title: "Don't delete", style: .default, handler: { (action: UIAlertAction!) in }))
        self.present(alarm, animated: true, completion: nil)

    }

    func refresh() {
        if (tableview != nil) {
            tableview.reloadData()
        }
    }

}

extension GalleryView: UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?

        do {
            if try projectManager?.getProjectList().count == 0 {
                cell = tableView.dequeueReusableCell(withIdentifier: "emptyGalleryCell", for: indexPath)
            } else if let projectData = try projectManager?.getProjectList()[indexPath.row] {
                let cell2 = tableView.dequeueReusableCell(withIdentifier: "galleryCell", for: indexPath) as! GalleryCell
                            cell2.set(
                                name: projectData.name,
                                length: "todo",
                                share: { self.shareProject(data: projectData) },
                                open: { self.openProject(data: projectData) },
                                delete: { self.deleteProject(data: projectData) })
                cell = cell2
            }
        } catch let error as NSError {
            print(error)
            // check projectmanager projectlist count and that its not null
            cell = tableView.dequeueReusableCell(withIdentifier: "errorGalleryCell", for: indexPath)
        }
        return cell!
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let manager = projectManager {
            do {
                let count = try manager.getProjectList().count
                if count == 0 {
                    return 1
                } else {
                    return count
                }
            } catch let error as NSError {
                print(error)
                return 1
            }

        } else {
            return 1
        }

    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

}

