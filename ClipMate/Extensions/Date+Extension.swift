import SwiftUI

extension Date {
    static func clipMateDateFormat(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy년MM월dd일 HH:mm"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        
        return dateFormatter.string(from: date)
    }
    
    static func imageFileName(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        
        return dateFormatter.string(from: date)
    }
}
