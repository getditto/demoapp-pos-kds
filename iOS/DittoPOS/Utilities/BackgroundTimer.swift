import Foundation
import Network
import DittoSwift

class BackgroundTimer {
    private var timer: Timer?
    private let queue: DispatchQueue
    private var monitor: NWPathMonitor?
    private let url: URL
    
    init(url: URL,
         queue: DispatchQueue = DispatchQueue.global(qos: .background)) {
        self.url = url
        self.queue = queue
    }
    
    func schedule(interval: TimeInterval, repeats: Bool = true, action: @escaping (Bool, Error?) -> Void) {
        // Cancel any existing timer
        cancel()
        
        // Create a new timer on the main thread
        DispatchQueue.main.async { [weak self] in
            self?.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: repeats) { _ in
                // Execute the action on the specified queue
                self?.queue.async {
                    self?.checkReachability(completion: action)
                }
            }
        }
    }
    
    private func checkReachability(completion: @escaping (Bool, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { _, response, error in
            if let error = error {
                completion(false, error)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                let isReachable = (200...299).contains(httpResponse.statusCode) || httpResponse.statusCode == 404
                completion(isReachable, nil)
            } else {
                completion(false, NSError(domain: "BackgroundTimer", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
            }
        }
        task.resume()
    }
    
    func startNetworkMonitoring(networkStatusChanged: @escaping (NWPath.Status) -> Void) {
        monitor = NWPathMonitor()
        monitor?.pathUpdateHandler = { path in
            networkStatusChanged(path.status)
        }
        monitor?.start(queue: queue)
    }
    
    func cancel() {
        timer?.invalidate()
        timer = nil
        monitor?.cancel()
        monitor = nil
    }
    
    deinit {
        cancel()
    }
}

// Example usage:
class NetworkChecker {
    
    private let primaryUrl: URL
    private let fallbackUrl: URL
    private let backgroundTimer: BackgroundTimer
    private let ditto: Ditto
    
    init(primaryUrl: URL, fallbackUrl: URL, ditto: Ditto){
        self.primaryUrl = primaryUrl
        self.fallbackUrl = fallbackUrl
        let checkUrl = primaryUrl.scheme == "wss" ?
            URL(string: "https://" + primaryUrl.host! + primaryUrl.path)! :
        primaryUrl
        self.backgroundTimer = BackgroundTimer(url: checkUrl)
        self.ditto = ditto
    }
    
    func updateWebsocketURL(url: URL) {
        // Don't update the config if it's already set
        if ditto.transportConfig.connect.webSocketURLs.contains(url.absoluteString) {
            return
        }
        print("Switching active websocket URL to \(url.absoluteString)")
        ditto.transportConfig.connect.webSocketURLs = [url.absoluteString]
    }
    
    func startPeriodicCheck() {
        // Start monitoring general network connectivity
        backgroundTimer.startNetworkMonitoring { status in
            switch status {
            case .satisfied:
                print("Network is available")
            case .unsatisfied:
                print("Network is unavailable")
            case .requiresConnection:
                print("Network requires connection")
            @unknown default:
                print("Unknown network status")
            }
        }
        
        // Start periodic URL checks
        backgroundTimer.schedule(interval: 10.0) { isReachable, error in
            if let error = error {
                print("URL is not reachable")
                self.updateWebsocketURL(url: self.fallbackUrl)
                return
            }
            
            if isReachable {
                print("URL is reachable")
                self.updateWebsocketURL(url: self.primaryUrl)
            } else {
                print("URL is not reachable")
                self.updateWebsocketURL(url: self.fallbackUrl)
            }
        }
    }
    
    func stopPeriodicCheck() {
        backgroundTimer.cancel()
    }
}
