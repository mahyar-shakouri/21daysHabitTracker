//
//  AddViewController.swift
//  Habit21
//
//  Created by MahyarShakouri on 1/8/22.
//

import UIKit
import RealmSwift
import UserNotifications

protocol AddDelegate {
    func switchChanged(forItem item : Reminder)
}

class AddViewController: UIViewController, AddDelegate {

    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var addHabitTextField: UITextField!
    @IBOutlet weak var reminderSwitch: UISwitch!
    @IBOutlet weak var firstSeprator: UIView!
    @IBOutlet weak var addHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var secondSeprator: UIView!
    @IBOutlet weak var dateView: UIView!
    @IBOutlet weak var dateHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var dateTextField: UITextField!
    @IBOutlet weak var reminderTableView: UITableView!
    @IBOutlet weak var reminderTableViewHeightConstraint: NSLayoutConstraint!
    
    var delegate: HomeDelegate?
    var datePicker: UIDatePicker?
    var reminderList = [Reminder]()
    var realm : Realm?
    var notificationCenter = UNUserNotificationCenter.current()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        datePicker = UIDatePicker()
        datePicker?.datePickerMode = .time
        datePicker?.addTarget(self, action: #selector(AddViewController.reminderFormattedDate(datePicker:)), for: .valueChanged)
        dateTextField.inputView = datePicker
        datePicker!.preferredDatePickerStyle = UIDatePickerStyle.wheels
    
        self.saveButton.isEnabled = false
        self.saveButton.tintColor = UIColor.lightGray
        self.addHabitTextField.delegate = self
        
        realm = try! Realm()
        loadValues()
    }
    
    func switchChanged(forItem item: Reminder) {
        
        print("Item \(item._id)'s switched has changed its value to \(item.isOn)")
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { (notificationRequests) in
            var identifiers: [String] = []
            for notification:UNNotificationRequest in notificationRequests {
                identifiers.append(notification.identifier)
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
            }
        }
    }
        
    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        let habit = Habit()
        let reminderList = List<Reminder>()

        habit.habitTitle = addHabitTextField.text ?? ""
        habit.reminders = reminderList
        
        try! realm?.write {
            realm?.add(habit)
        }
        delegate?.reload()
        self.dismiss(animated: true)
    }
    
    @IBAction func reminderSwitchTapped(_ sender: Any) {
        if reminderSwitch.isOn{
            self.addHeightConstraint.constant = 40
            self.dateHeightConstraint.constant = 40
            self.reminderTableViewHeightConstraint.constant = 370
            self.reminderTableView.isHidden = false
            firstSeprator.isHidden = false
            secondSeprator.isHidden = false
            dateView.isHidden = false
        }else{
            self.addHeightConstraint.constant = 0
            self.dateHeightConstraint.constant = 0
            self.reminderTableViewHeightConstraint.constant = 450
            self.reminderTableView.isHidden = true
            firstSeprator.isHidden = true
            secondSeprator.isHidden = true
            dateView.isHidden = true
        }
    }
    
    @IBAction func addButtonTapped(_ sender: Any) {
        
        if dateTextField.text?.isEmpty == true {
            
            let alertController = UIAlertController(title: "Please pick a Date", message: "", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) {
                UIAlertAction in
                NSLog("OK Pressed")
            }
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        } else{
            
            let reminder = Reminder()
            reminder.reminderTime = dateTextField.text ?? ""
            reminder.isOn = true
            //        reminder.id = reminder.incrementID()
            
            self.reminderList.append(reminder)
            self.reminderTableView.reloadData()
            
            notificationCenter.getNotificationSettings { (settings) in
                
                DispatchQueue.main.async
                {
                    let title = self.addHabitTextField.text ?? "Reminder"
                    let message = "You have to do it, Now!"
                    let date = self.datePicker!.date
                    
                    if(settings.authorizationStatus == .authorized)
                    {
                        let content = UNMutableNotificationContent()
                        content.title = title
                        content.body = message
                        content.sound = .default
                        
                        let dateComp = Calendar.current.dateComponents([.hour, .minute], from: date)
                        
                        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComp, repeats: true)
                        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                        
                        self.notificationCenter.add(request) { (error) in
                            if(error != nil)
                            {
                                print("Error " + error.debugDescription)
                                return
                            }
                        }
                        let ac = UIAlertController(title: "Notification Scheduled", message: "At " + self.notificationFormattedDate(date: date), preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in}))
                        self.present(ac, animated: true)
                    }
                    else
                    {
                        let ac = UIAlertController(title: "Enable Notifications?", message: "To use this feature you must enable notifications in settings", preferredStyle: .alert)
                        let goToSettings = UIAlertAction(title: "Settings", style: .default)
                        { (_) in
                            guard let setttingsURL = URL(string: UIApplication.openSettingsURLString)
                            else
                            {
                                return
                            }
                            
                            if(UIApplication.shared.canOpenURL(setttingsURL))
                            {
                                UIApplication.shared.open(setttingsURL) { (_) in}
                            }
                        }
                        ac.addAction(goToSettings)
                        ac.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (_) in}))
                        self.present(ac, animated: true)
                    }
                }
            }
        }
    }
    
    @objc func reminderFormattedDate(datePicker: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        dateTextField.text = dateFormatter.string(from: datePicker.date)
    }
    
    func notificationFormattedDate(date: Date) -> String
        {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        }

    func loadValues() {
        self.reminderList = Array(try! Realm().objects(Reminder.self))
        self.reminderTableView.reloadData()
    }
}

extension AddViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if let text = textField.text,
           let textRange = Range(range, in: text) {
            let updatedText = text.replacingCharacters(in: textRange, with: string)
            
            if textField == self.addHabitTextField {
                if updatedText.isEmpty {
                    self.saveButton.isEnabled = false
                    self.saveButton.tintColor = UIColor.lightGray
                }
                else {
                    self.saveButton.isEnabled = true
                    self.saveButton.tintColor = UIColor.systemRed
                }
            }
        }
        return true
    }
}

extension AddViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.reminderList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReminderCell", for: indexPath) as! ReminderTableViewCell
        cell.delegate = self
        cell.config(self.reminderList[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        let reminder = self.reminderList[indexPath.row]
        let deleteAction = UIContextualAction(style: .destructive, title:  "") { (contextualAction, view, actionPerformed: @escaping (Bool) -> ()) in
            
            let alert = UIAlertController(title: "Delete Reminder", message: "Are you sure you want to delete this reminder: \(reminder.reminderTime)?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: {  (alertAction) in
                actionPerformed(false)
            }))
            
            alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: {(alertAction) in
                self.reminderList.remove(at: indexPath.row)
                self.reminderTableView.deleteRows(at: [indexPath], with: .fade)
                //
           
                UNUserNotificationCenter.current().getPendingNotificationRequests { (notificationRequests) in
                    var identifiers: [String] = []
                    for notification:UNNotificationRequest in notificationRequests {
                        identifiers.append(notification.identifier)
                        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
                    }
                }
                //
                
                actionPerformed(true)
            }))
            self.present(alert, animated: true)
        }
        deleteAction.image = UIImage(named: "DeleteIcon")
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let editAction = UIContextualAction(style: .normal, title: "") { (action, view, completion) in
        }
        editAction.image = UIImage(named: "EditIcon")
        editAction.backgroundColor = UIColor(named: "EditColor")
        return UISwipeActionsConfiguration(actions: [editAction])
    }
}
