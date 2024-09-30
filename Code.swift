//
//  ViewController.swift
//  TinyEel
//
//  Created by Gavin Morrison on 6/17/24.
//
import UIKit
import UserNotifications

class ViewController: UIViewController {
    
    // Connect the labels and date picker
    @IBOutlet weak var Thanks: UILabel!
    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var setTimeButton: UIButton!
    @IBOutlet weak var NotiTime: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var time1: UILabel!
    @IBOutlet weak var time2: UILabel!
    @IBOutlet weak var time3: UILabel!
    @IBOutlet weak var time4: UILabel!
    @IBOutlet weak var time5: UILabel!
    
    var selectedHour: Int = 8 // Default notification time is 8 AM
       var selectedMinute: Int = 0 // Default notification time is 00 minutes

       let lastUpdatedKey = "lastUpdatedTimeKey" // Key to store last updated time
       let notificationTimeKey = "notificationTimeKey" // Key to store notification time
       let monthlyUpdateCountKey = "monthlyUpdateCountKey" // Key to store the monthly update count

       var thanksLabelUpdateTimes: [Date] = [] // Array to store the last 5 timestamps
       
       override func viewDidLoad() {
           super.viewDidLoad()
           // Do any additional setup after loading the view.
           requestNotificationPermission()
           
           // Set up UIDatePicker
           timePicker.datePickerMode = .time
           timePicker.alpha = 0 // Hide the timePicker initially

           // Load saved notification time or set default
           loadNotificationTime()
       }

       // Action for the button to update the Thanks label
       @IBAction func Send(_ sender: Any) {
           // Append the current date and time to the thanksLabelUpdateTimes array
           thanksLabelUpdateTimes.append(Date())
           
           // Keep only the last 5 timestamps
           if thanksLabelUpdateTimes.count > 5 {
               thanksLabelUpdateTimes.removeFirst()
           }
           
           updateThanksLabel()
           updateTimestampLabels()
       }
       
       // Action for the button to set notification time
       @IBAction func setTimeButtonPressed(_ sender: Any) {
           if canUpdateNotification() {
               // Show the timePicker
               UIView.animate(withDuration: 0.3) {
                   self.timePicker.alpha = 1
               }
           } else {
               showUpdateDeniedAlert()
           }
       }
       
       // Action for the UIDatePicker when value is changed
       @IBAction func timePickerChanged(_ sender: UIDatePicker) {
           // Get the selected hour and minute from UIDatePicker
           let calendar = Calendar.current
           let components = calendar.dateComponents([.hour, .minute], from: timePicker.date)
           selectedHour = components.hour ?? 8 // Default to 8 AM if hour is nil
           selectedMinute = components.minute ?? 0 // Default to 0 minutes if minute is nil
           scheduleMonthlyNotification()
           
           // Update the NotiTime label
           updateNotiTimeLabel(hour: selectedHour, minute: selectedMinute)
           
           // Save the last update time
           UserDefaults.standard.set(Date(), forKey: lastUpdatedKey)
           
           // Save the selected time
           saveNotificationTime(hour: selectedHour, minute: selectedMinute)
           
           // Increment the monthly update count
           incrementMonthlyUpdateCount()
           
           // Hide the timePicker with a fade-out animation after 6 seconds
           DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
               UIView.animate(withDuration: 0.3) {
                   self.timePicker.alpha = 0
               }
           }
       }
       
       func updateThanksLabel() {
           Thanks.text = "Clocked!"
           // Debug: Check if the label was updated
           print("Thanks label updated to: \(Thanks.text ?? "nil")")
       }
       
       func updateTimestampLabels() {
           // Create a date formatter
           let dateFormatter = DateFormatter()
           dateFormatter.dateStyle = .short
           dateFormatter.timeStyle = .medium
           
           // Create an array of formatted date strings
           let formattedDates = thanksLabelUpdateTimes.map { dateFormatter.string(from: $0) }
           
           // Update the timestamp labels with the formatted dates
           time1.text = formattedDates.count > 0 ? formattedDates[formattedDates.count - 1] : ""
           time2.text = formattedDates.count > 1 ? formattedDates[formattedDates.count - 2] : ""
           time3.text = formattedDates.count > 2 ? formattedDates[formattedDates.count - 3] : ""
           time4.text = formattedDates.count > 3 ? formattedDates[formattedDates.count - 4] : ""
           time5.text = formattedDates.count > 4 ? formattedDates[formattedDates.count - 5] : ""
       }
       
       func updateNotiTimeLabel(hour: Int, minute: Int) {
           // Format the hour and minute to display in the NotiTime label
           let timeFormatter = DateFormatter()
           timeFormatter.dateFormat = "h:mm a"
           let dateComponents = DateComponents(calendar: Calendar.current, hour: hour, minute: minute)
           if let date = Calendar.current.date(from: dateComponents) {
               NotiTime.text = timeFormatter.string(from: date)
           } else {
               NotiTime.text = "Invalid time"
           }
       }
       
       func requestNotificationPermission() {
           UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
               if granted {
                   print("Notification permission granted.")
               } else if let error = error {
                   print("Notification Authorization Error: \(error)")
               }
           }
       }
       
       func scheduleMonthlyNotification() {
           let content = UNMutableNotificationContent()
           content.title = "Monthly Reminder"
           content.body = "Don't forget to press the button today!"
           
           var dateComponents = DateComponents()
           dateComponents.day = 1 // Set the notification to repeat on the 1st of every month
           dateComponents.hour = selectedHour
           dateComponents.minute = selectedMinute
           
           let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
           
           let request = UNNotificationRequest(identifier: "MonthlyReminder", content: content, trigger: trigger)
           
           UNUserNotificationCenter.current().add(request) { error in
               if let error = error {
                   print("Error scheduling notification: \(error)")
               }
           }
       }
       
       func canUpdateNotification() -> Bool {
           let calendar = Calendar.current
           let currentDate = Date()
           
           // Reset the monthly update count if it's a new month
           if let lastUpdated = UserDefaults.standard.object(forKey: lastUpdatedKey) as? Date,
              !calendar.isDate(currentDate, equalTo: lastUpdated, toGranularity: .month) {
               UserDefaults.standard.set(0, forKey: monthlyUpdateCountKey)
           }
           
           // Check the monthly update count
           let monthlyUpdateCount = UserDefaults.standard.integer(forKey: monthlyUpdateCountKey)
           return monthlyUpdateCount < 31
       }
       
       func incrementMonthlyUpdateCount() {
           let monthlyUpdateCount = UserDefaults.standard.integer(forKey: monthlyUpdateCountKey)
           UserDefaults.standard.set(monthlyUpdateCount + 1, forKey: monthlyUpdateCountKey)
       }
       
       func saveNotificationTime(hour: Int, minute: Int) {
           let timeDict: [String: Int] = ["hour": hour, "minute": minute]
           UserDefaults.standard.set(timeDict, forKey: notificationTimeKey)
       }
       
       func loadNotificationTime() {
           if let timeDict = UserDefaults.standard.dictionary(forKey: notificationTimeKey) as? [String: Int],
              let hour = timeDict["hour"], let minute = timeDict["minute"] {
               selectedHour = hour
               selectedMinute = minute
           } else {
               // Set default time to 8:00 AM
               selectedHour = 8
               selectedMinute = 0
           }
           updateNotiTimeLabel(hour: selectedHour, minute: selectedMinute)
       }
       
       func showUpdateDeniedAlert() {
           let alert = UIAlertController(title: "Denied", message: "Monthly Limit Reached", preferredStyle: .alert)
           alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
           present(alert, animated: true, completion: nil)
       }
       
       func showConfirmationAlert() {
           let alert = UIAlertController(title: "Denied", message: "Monthly Limit Reached", preferredStyle: .alert)
           alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
           present(alert, animated: true, completion: nil)
       }
   }
