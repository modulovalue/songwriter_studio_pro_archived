//
//  AppearanceTabController.swift
//  SongwriterStudioPro
//
//  Created by Modestas Valauskas on 18.12.17.
//  Copyright © 2017 MV. All rights reserved.
//

import Foundation
import UIKit

class AppearanceTabController: UITableViewController {

    @IBOutlet weak var lblWaveIndicatorColor: UILabel!
    @IBOutlet weak var lblWaveBackgroundColor: UILabel!
    @IBOutlet weak var lblWaveBandColor: UILabel!
    @IBOutlet weak var lblWaveRecordingBandColor: UILabel!
    @IBOutlet weak var lblWaveBandsPerBeat: UILabel!

    @IBOutlet weak var lblTimelineIndicatorColor: UILabel!
    @IBOutlet weak var lblTimelineBackgroundColor: UILabel!
    @IBOutlet weak var lblTimelineBeatTickColor: UILabel!
    @IBOutlet weak var lblTimelineBarTickColor: UILabel!

    lazy var projectManager: ProjectManager? = (navigationController?.tabBarController as! SettingsView).projectManager as? ProjectManager

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateUI()
    }

    func colorPicker(_ color: UIColor, _ setColor: (UIColor) -> Void) {
        setColor(UIColor.black)
        updateUI()
    }


    @IBAction func showMenu(_ sender: Any) {
        (navigationController?.tabBarController as! SettingsView).menu()
    }

    func updateUI() {
        if let manager = projectManager {
            lblWaveIndicatorColor.text = "        "
            lblWaveIndicatorColor.backgroundColor = manager.waveformIndicatorColor()

            lblWaveBackgroundColor.text = "        "
            lblWaveBackgroundColor.backgroundColor = manager.waveformBackgroundColor()

            lblWaveBandColor.text = "        "
            lblWaveBandColor.backgroundColor = manager.waveformNotRecordingBandColor()

            lblWaveRecordingBandColor.text = "        "
            lblWaveRecordingBandColor.backgroundColor = manager.waveformRecordingBandColor()

            lblWaveBandsPerBeat.text = "\(manager.waveformbandsPerBeat())"

            lblTimelineIndicatorColor.text = "        "
            lblTimelineIndicatorColor.backgroundColor = manager.timelineIndicatorColor()

            lblTimelineBackgroundColor.text = "        "
            lblTimelineBackgroundColor.backgroundColor = manager.timelineBackgroundColor()

            lblTimelineBeatTickColor.text = "        "
            lblTimelineBeatTickColor.backgroundColor = manager.timelineBeatTickColor()

            lblTimelineBarTickColor.text = "        "
            lblTimelineBarTickColor.backgroundColor = manager.timelineBarTickColor()
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if let manager = projectManager {
            switch indexPath.section {
            case 0:
                switch indexPath.row {
                case 0:
                    colorPicker(manager.waveformIndicatorColor(), { manager.globalSettings(.waveformIndicatorColor($0)) })
                case 1:
                    colorPicker(manager.waveformBackgroundColor(), { manager.globalSettings(.waveformBackgroundColor($0)) })
                case 2:
                    colorPicker(manager.waveformRecordingBandColor(), { manager.globalSettings(.waveformRecordingBandColor($0)) })
                case 3:
                    colorPicker(manager.waveformNotRecordingBandColor(), { manager.globalSettings(.waveformNotRecordingBandColor($0)) })
                case 4:
                    let alert = UIAlertController(title: "Choose the amount of bands per beat for the wave representation", message: "", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "16", style: UIAlertActionStyle.default, handler:{ (UIAlertAction) in
                        manager.globalSettings(.waveformbandsPerBeat(16))
                        self.updateUI()
                    }))
                    alert.addAction(UIAlertAction(title: "8", style: UIAlertActionStyle.default, handler:{ (UIAlertAction) in
                        manager.globalSettings(.waveformbandsPerBeat(8))
                        self.updateUI()
                    }))
                    alert.addAction(UIAlertAction(title: "4", style: UIAlertActionStyle.default, handler:{ (UIAlertAction) in
                        manager.globalSettings(.waveformbandsPerBeat(8))
                        self.updateUI()
                    }))
                    self.present(alert, animated: true, completion: nil)
                    break
                default:
                    print("section 1 not implemented other row onClick events")
                }
            case 1:
                switch indexPath.row {
                case 0:
                    colorPicker(manager.timelineIndicatorColor(), { manager.globalSettings(.timelineIndicatorColor($0)) })
                case 1:
                    colorPicker(manager.timelineBackgroundColor(), { manager.globalSettings(.timelineBackgroundColor($0)) })
                case 2:
                    colorPicker(manager.timelineBeatTickColor(), { manager.globalSettings(.timelineBeatTickColor($0)) })
                case 3:
                    colorPicker(manager.timelineBarTickColor(), { manager.globalSettings(.timelineBarTickColor($0)) })
                default:
                    print("section 1 not implemented other row onClick events")
                }
            case 2:
                switch indexPath.row {
                case 0:
                    manager.globalSettings(.resetAppearance())
                default:
                    print("appearance settings, section not implemented other row onClick events")
                }
            default:
                print("section not implemented AppearanceTabController")
            }
        } else {
            print("error")
        }
    }

}



