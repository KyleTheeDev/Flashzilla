//
//  ContentView.swift
//  Flashzilla
//
//  Created by Kyle Miller on 7/14/21.
//

import SwiftUI

extension View {
    func stacked(at position: Int, in total: Int) -> some View {
        let offset = CGFloat(total - position)
        return self.offset(CGSize(width: 0, height: offset * 10))
    }
}

struct ContentView: View {
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor
    @Environment(\.accessibilityEnabled) var accessibilityEnabled
    
   //  @State private var cards = [Card](repeating: Card.example, count: 10) // used for example card
    @State private var cards = [Card]()

    
    @State private var isActive = true
    @State private var timeRemaining = 100
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State private var showingEditScreen = false
        
    
    var body: some View {
        ZStack { // allows us to have background image and card stack overlapping
            Image(decorative: "background") // decorative stops voice over from reading the background
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("Time: \(timeRemaining)")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.black)
                            .opacity(0.75)
                    )
                
                ZStack {
                    ForEach(0..<cards.count, id: \.self) { index in
                        CardView(card: self.cards[index]) {
                            withAnimation {
                                self.removeCard(at: index)
                            }
                        }
                        .stacked(at: index, in: self.cards.count)
                        .allowsHitTesting(index == self.cards.count - 1) // stops you from moving cards behind top card
                        .accessibility(hidden: index < self.cards.count - 1) // stops voice over from reading cards behind top card
                        
                    }
                }
                .allowsHitTesting(timeRemaining > 0)
                
                if cards.isEmpty {
                    Button("Start Again", action: resetCards)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .clipShape(Capsule())
                }
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        self.showingEditScreen = true
                    }) {
                        Image(systemName: "plus.circle")
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .clipShape(Circle())
                }
                
                Spacer()
            }
            .foregroundColor(.white)
            .font(.largeTitle)
            .padding()
            
            if differentiateWithoutColor || accessibilityEnabled {
                VStack {
                    Spacer()
                    
                    HStack {
                        Button(action: {
                            withAnimation {
                                self.removeCard(at: self.cards.count - 1)
                            }
                        }) {
                            Image(systemName: "xmark.circle")
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .clipShape(Circle())
                        }
                        .accessibility(label: Text("Wrong"))
                        .accessibility(hint: Text("Mark your answer as being incorrect."))
                        
                        Spacer()
                        Button(action: {
                            withAnimation {
                                self.removeCard(at: self.cards.count - 1)
                            }
                        }) {
                            Image(systemName: "checkmark.circle")
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .clipShape(Circle())
                        }
                        .accessibility(label: Text("Correct"))
                        .accessibility(hint: Text("Mark your answer as being correct."))
                    }
                    .foregroundColor(.white)
                    .font(.largeTitle)
                    .padding()
                }
            }
        }
        //all 3 onReceive are important to pause anything in the app when you leave the app
        
        .onReceive(timer) { timer in
            guard self.isActive else { return }
            
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            self.isActive = false
        }
        
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            if self.cards.isEmpty == false {
                self.isActive = true
            }
        }
        
        .sheet(isPresented: $showingEditScreen, onDismiss: resetCards) {
            EditCardView()
        }
        
        .onAppear(perform: resetCards)
        
    }
    
    
    
    
    func removeCard(at index: Int) {
        guard index >= 0 else { return } // stops the method from removing a card when one doesn't exist
        cards.remove(at: index)
        
        if cards.isEmpty {
            isActive = false
        }
    }
    
    func resetCards() {
        // cards = [Card](repeating: Card.example, count: 10) used for the example card
        timeRemaining = 100
        isActive = true
        loadData()
        
    }
    
    func loadData() {
        if let data = UserDefaults.standard.data(forKey: "Cards") {
            if let decoded = try? JSONDecoder().decode([Card].self, from: data) {
                self.cards = decoded
            }
        }
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}













/*
 Supporting specific accessibility needs with SwiftUI
 https://www.hackingwithswift.com/books/ios-swiftui/supporting-specific-accessibility-needs-with-swiftui
 
 func withOptionalAnimation<Result>(_ animation: Animation? = .default, _ body: () throws -> Result) rethrows -> Result {
     if UIAccessibility.isReduceMotionEnabled {
         return try body()
     } else {
         return try withAnimation(animation, body)
     }
 }

 struct ContentView: View {
   //  @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor
     @Environment(\.accessibilityReduceMotion) var reduceMotion
     
     @State private var scale: CGFloat = 10
         
     var body: some View {
         Text("Hello, World!")
             .scaleEffect(scale)
             .onTapGesture {
                 withOptionalAnimation {
                     self.scale *= 1.5
                 }
             }
         
         
         
     /*    Text("Hello, World!")
             .scaleEffect(scale)
             .onTapGesture {
                 if self.reduceMotion {
                     self.scale *= 1.5
                 } else {
                     withAnimation {
                         self.scale *= 1.5
                     }
                 }
             } */
         
         
      /*   HStack {
             if differentiateWithoutColor {
                 Image(systemName: "checkmark.circle")
             }
             
             Text("Success")
         }
         .padding()
         .background(differentiateWithoutColor ? Color.black : Color.green)
         .foregroundColor(Color.white)
         .clipShape(Capsule())
     } */
 }
 */

/*
 How to be notified when your SwiftUI app moves to the background
 https://www.hackingwithswift.com/books/ios-swiftui/how-to-be-notified-when-your-swiftui-app-moves-to-the-background
 
 struct ContentView: View {
         
     var body: some View {
         Text("Hello, World!")
             .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                 print("Moving to the background!")
             }
     }
 }

 struct ContentView_Previews: PreviewProvider {
     static var previews: some View {
         ContentView()
     }
 }
 */

/*
 Triggering events repeatedly using a timer
 https://www.hackingwithswift.com/books/ios-swiftui/triggering-events-repeatedly-using-a-timer
 
 struct ContentView: View {
     
     let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
     
     @State private var counter = 0
         
     var body: some View {
         Text("Hello, World!")
             .onReceive(timer) { time in
                 //print("The time is now \(time).")
                 if self.counter == 5 {
                     self.timer.upstream.connect().cancel()
                 } else {
                     print("The time is now \(time).")
                 }
                 self.counter += 1
             }
     }
 }
 */


/*
 Making vibrations with UINotificationFeedbackGenerator and Core Haptics
 https://www.hackingwithswift.com/books/ios-swiftui/making-vibrations-with-uinotificationfeedbackgenerator-and-core-haptics
 
 import CoreHaptics
 import SwiftUI

 struct ContentView: View {
     @State private var engine: CHHapticEngine?
     
     var body: some View {
         Text("Hello, World!")
             .onAppear(perform: prepareHaptics)
             .onTapGesture(perform: complexSuccess)
     }
     
     func simpleSuccess() {
         let generator = UINotificationFeedbackGenerator()
         generator.notificationOccurred(.success)
     }
     
     func prepareHaptics() {
         guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
         
         do {
             self.engine = try CHHapticEngine()
             try engine?.start()
         } catch {
             print("There was an error creating the engine: \(error.localizedDescription)")
         }
     }
     
     func complexSuccess() {
         guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
         var events = [CHHapticEvent]()
         
         let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1)
         let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1)
         let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
         events.append(event)
         
         do {
             let pattern = try CHHapticPattern(events: events, parameters: [])
             let player = try engine?.makePlayer(with: pattern)
         } catch {
             print("Failed to play pattern: \(error.localizedDescription)")
         }
     }
 }
 */

/*
 How to use gestures in SwiftUI
 https://www.hackingwithswift.com/books/ios-swiftui/how-to-use-gestures-in-swiftui
 
 struct ContentView: View {
     @State private var offset = CGSize.zero
     @State private var isDragging = false
     
     var body: some View {
         let dragGesture = DragGesture()
             .onChanged { value in self.offset = value.translation }
             .onEnded { _ in
                 withAnimation {
                     self.offset = .zero
                     self.isDragging = false
                 }
             }
         
         let pressGesture = LongPressGesture()
             .onEnded { value in
                 withAnimation {
                     self.isDragging = true
                 }
             }
         
         let combined = pressGesture.sequenced(before: dragGesture)
         
         return Circle()
             .fill(Color.red)
             .frame(width: 64, height: 64)
             .scaleEffect(isDragging ? 1.5 : 1)
             .offset(offset)
             .gesture(combined)
         
         
     }
 }
 */

/*
 
 struct ContentView: View {
     
     @State private var currentMagnifyAmount: CGFloat = 0
     @State private var finalMagnifyAmount: CGFloat = 1
     
     @State private var currentRotateAmount: Angle = .degrees(0)
     @State private var finalRotateAmount: Angle = .degrees(0)
     
    // Simultaneously does multple gestures
    /* var body: some View {
         VStack {
             Text("Hello, World!")
                 .onTapGesture {
                     print("Text Tapped")
                 }
         }
         .simultaneousGesture(
             TapGesture()
                 .onEnded {
                     print("VStack Tapped")
                 }
         )
     } */
 
     var body: some View {
         Text("Hello, world!")
             //.onTapGesture(count: 2) { print("Double tapped") }
             //.onLongPressGesture(minimumDuration: 2, pressing: { inProgress in print("In Progress: \(inProgress)") }) { print("long pressed") }
         /*   .scaleEffect(finalMagnifyAmount + currentMagnifyAmount)
             .gesture(
                 MagnificationGesture()
                     .onChanged { amount in
                         self.currentMagnifyAmount = amount - 1
                     }
                     .onEnded { amount in
                               self.finalMagnifyAmount += self.currentMagnifyAmount
                               self.currentMagnifyAmount = 0
                     }
             ) */
             .rotationEffect(finalRotateAmount + currentRotateAmount)
             .gesture(
                 RotationGesture()
                     .onChanged { angle in
                         self.currentRotateAmount = angle
                     }
                     .onEnded { angle in
                         self.finalRotateAmount += self.currentRotateAmount
                         self.currentRotateAmount = .degrees(0)
                     }
             )
         
     }
 }
 */
