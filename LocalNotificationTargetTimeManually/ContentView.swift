import SwiftUI
import UserNotifications

struct ContentView: View {
    @State private var inputTime: String = ""

    var body: some View {
        VStack {
            TextField("Enter time (HH:mm)", text: $inputTime)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Button("Request Permission") {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                    if success {
                        print("All set!")
                    } else if let error = error {
                        print(error.localizedDescription)
                    }
                }
            }
            Button("Schedule Notification") {
                scheduleNotificationManually(at: inputTime)
            }
            Button("Cancel Notifications") {
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                print("All notifications cancelled!")
            }
        }
        .padding()
    }

    func scheduleNotificationManually(at timeString: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let notificationTime = formatter.date(from: timeString) else {
            print("Failed to parse time string.")
            return
        }

        let now = Date()
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current

        var components = calendar.dateComponents([.hour, .minute], from: notificationTime)
        components.year = calendar.component(.year, from: now)
        components.month = calendar.component(.month, from: now)
        components.day = calendar.component(.day, from: now)

        guard let scheduledTime = calendar.date(from: components),
              scheduledTime > now else {
            print("Scheduled time must be in the future.")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Peringatan Sholat"
        content.subtitle = "Anda belum Sholat"
        content.sound = UNNotificationSound.default

        var triggerComponents = DateComponents()
        triggerComponents.hour = calendar.component(.hour, from: scheduledTime)
        triggerComponents.minute = calendar.component(.minute, from: scheduledTime)

        // Create a repeating notification every 5 minutes
        for minuteOffset in stride(from: 0, to: 60, by: 5) {
            var repeatingComponents = triggerComponents
            repeatingComponents.minute = (triggerComponents.minute! + minuteOffset) % 60
            let trigger = UNCalendarNotificationTrigger(dateMatching: repeatingComponents, repeats: true)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error adding notification: \(error.localizedDescription)")
                } else {
                    print("Notification scheduled for \(timeString) with a 5-minute repeat interval!")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
