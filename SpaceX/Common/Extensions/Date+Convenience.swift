import Foundation

extension Date {

    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        return formatter.string(from: self)
    }

}
