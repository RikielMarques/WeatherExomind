//
//  ContentView.swift
//  WeatherExomind
//
//  Created by Rikiel Marques on 14/10/2023.
//

import SwiftUI
import Foundation
import SwiftyJSON

struct ContentView: View {
    
    var body: some View {
        NavigationView {
            VStack(alignment: .center, spacing: 20) {
                Spacer()
                Text("Bienvenue sur")
                    .font(.body)
                    .foregroundColor(Color("exomindPurple"))
                Text("Exomind Weather App")
                    .font(.title)
                    .foregroundColor(Color("exomindPurple"))
                
                NavigationLink(destination: WeatherView()) {
                        Text("Commencer")
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .frame(height: 40)
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .bold))
                            .background(LinearGradient(gradient: Gradient(colors: [Color("exomindPurple").opacity(0.5), Color("exomindPurple")]), startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(15)
                    .padding()
                }
                Spacer()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct WeatherView: View {
    @State private var progress: Double = 0.0
    @State private var citiesWeather: [CityWeather] = []
    @State private var loadingMessageIndex = 0
    @State private var cityIndex = 0
    @State private var timer: Timer?
    @State var showsAlertError: Bool = false
    let messages = ["Nous téléchargeons les données...", "C'est presque fini...", "Plus que quelques secondes avant d'avoir le résultat..."]
    let cities = ["Rennes", "Paris", "Nantes", "Bordeaux", "Lyon"]

    
    var body: some View {
            VStack(alignment: .center, spacing: 30) {
                        VStack {
                        Text(messages[loadingMessageIndex])
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color("exomindPurple"))
                        }.frame(height: 50)
                    .padding()
                if self.progress >= 1.0 {
                    Button(action: reset) {
                        Text("Recommencer")
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .frame(height: 40)
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .bold))
                            .background(LinearGradient(gradient: Gradient(colors: [Color("exomindPurple").opacity(0.5), Color("exomindPurple")]), startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(15)
                    }
                    .padding()
                } else {
                    ProgressBarView(progress: $progress)
                        .onAppear(perform: startProgress)
                }
                    List(citiesWeather, id: \.id) { weather in
                        HStack(alignment: .center, spacing: 10) {
                            Text(weather.name ?? "Ville non trouvée")
                            Spacer()
                            Text("\(Int(weather.temperature ?? 0.0))°C")
                            AsyncImage(url: URL(string: "https://openweathermap.org/img/w/\(String(describing: weather.weatherPictogram ?? "")).png"))
                                .frame(width: 20, height: 20)
                        }
                    }
                    .listStyle(PlainListStyle())
                Spacer()
            }
            .alert(isPresented: $showsAlertError) {
                Alert(title: Text("Une erreur est survenue lors du chargement des données, veuillez réessayer dans quelques instants"),
                      dismissButton: .default(Text("OK"))
                )
            }
    }
    func startProgress() {
        let citiesTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { timer in
            if cityIndex < cities.count {
                fetchWeatherData()
                cityIndex += 1
            }
        }
        timer = Timer.scheduledTimer(withTimeInterval: 6.0, repeats: true) { timer in
            self.loadingMessageIndex = (self.loadingMessageIndex + 1) % self.messages.count
        }
        
        let apiTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { timer in
            if self.progress >= 1.0 {
                timer.invalidate()
            } else {
                self.progress += 10.0 / 60.0
            }
        }
        
        RunLoop.current.add(apiTimer, forMode: .common)
        apiTimer.tolerance = 1.0
    }
    
    func fetchWeatherData() {
        
        let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?q=\(cities.safelyAccessElement(at: cityIndex) ?? "")&appid=c200fe740a130638ca69a4dda0263de5&units=metric")!
    

        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                self.showsAlertError.toggle()
                self.reset()
            } else if let data = data {
                do {
                    let json = try JSON(data: data)
                    let weather = CityWeather(name: json["name"].rawValue as? String, temperature: json["main"]["temp"].rawValue as? Double, weatherPictogram: json["weather"][0]["icon"].rawValue as? String)
                    citiesWeather.append(weather)
                } catch {
                    print("Error decoding JSON: \(error)")
                    self.showsAlertError.toggle()
                }
            }
        }

        task.resume()
    }
    
    func reset() {
        progress = 0.0
        citiesWeather = []
        loadingMessageIndex = 0
        cityIndex = 0
        timer?.invalidate()
        startProgress()
    }
}

struct ProgressBarView: View {
    @Binding var progress: Double
    @State var time = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack(alignment: .leading) {
            GeometryReader { geometry in
                Rectangle()
                    .frame(width: geometry.size.width, height: 30)
                    .opacity(0.3)
                    .foregroundColor(Color.gray)
                
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color("exomindPurple").opacity(0.5), Color("exomindPurple")]), startPoint: .leading, endPoint: .trailing))
                    .frame(width: min(CGFloat(self.progress) * geometry.size.width, geometry.size.width), height: 30)
                    .animation(.easeInOut(duration: 10.0), value: progress)
            }
            HStack {
                Spacer()
                Text("\(Int(progress*100)) %")
                    .foregroundColor(Color("exomindPurple"))
                    .shadow(color: .black, radius: 1)
                    .padding(.trailing, 10)
            }
        }
        .frame(height: 30)
        .cornerRadius(15.0)
        .padding()
    }
}

struct CityWeather: Hashable {
    let id = UUID()
    let name: String?
    let temperature: Double?
    let weatherPictogram: String?
}

// Extension from :
// https://cocoacasts.com/swift-fundamentals-how-to-safely-access-the-elements-of-an-array
extension Array {

    func safelyAccessElement(at index: Int) -> Element? {
        guard index >= 0 && index < count else {
            return nil
        }

        return self[index]
    }

}
