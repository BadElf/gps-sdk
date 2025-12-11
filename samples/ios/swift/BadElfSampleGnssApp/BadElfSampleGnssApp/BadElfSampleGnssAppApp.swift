import SwiftUI
import ExternalAccessory
import Combine
import Foundation

// MARK: - 1. NMEA Data Structure
struct NmeaData: Identifiable {
    let id = UUID()
    var timestamp: String?
    var date: String?
    var latitude: Double?
    var longitude: Double?
    var altitude: Double?
    var speed: Double?
    var course: Double?
    var fixType: String?
    var horizontalAccuracy: Double? // Computed from GST
    var hDOP: Double?

    static var empty: NmeaData {
        NmeaData(timestamp: nil, date: nil, latitude: nil, longitude: nil, altitude: nil, speed: nil, course: nil, fixType: nil, horizontalAccuracy: nil, hDOP: nil)
    }
    
    // Check if the required core data is available
    var hasCoreData: Bool {
        return timestamp != nil && latitude != nil && longitude != nil && fixType != nil && horizontalAccuracy != nil
    }
}

extension Data {
    /// Converts the data to a hex string representation.
    /// Example: `Data([0x1A, 0x2B, 0x3C]).toHexString()` -> "1a2b3c"
    func toHexString() -> String {
        // Map each byte to its two-character hex representation (e.g., 10 -> "0a")
        return self.map { byte in
            String(format: "%02hhx", byte)
        }
        // Join all the hex strings together
        .joined()
    }
}

// MARK: - 2. BadElf Receiver Manager
class BadElfReceiver: NSObject, ObservableObject, StreamDelegate {
    
    // Published properties for SwiftUI updates
    @Published var connectionStatus: String = "Disconnected"
    @Published var receiverName: String = "N/A"
    @Published var serialNumber: String = "N/A"
    @Published var currentGnssData: NmeaData = .empty
    @Published var isAutoConnectEnabled: Bool = true
    
    // Internal State
    private var accessory: EAAccessory?
    private var session: EASession?
    private var inputStream: InputStream?
    private var outputStream: OutputStream?
    private var isLegacy: Bool = false
    private var isConfigured: Bool = false
    private var buffer = Data()
    private var pendingGga: NmeaData?
    private var pendingRmc: NmeaData?
    private var pendingGst: NmeaData?
    
    // Protocol strings
    private let primaryProtocol = "com.bad-elf.gnss"
    private let legacyProtocol = "com.bad-elf.gps"
    
    // Singleton pattern for easy access
    static let shared = BadElfReceiver()
    
    override private init() {
        super.init()
        // Register for EAAccessoryManager connection notifications (required for auto-connect logic)
        // NOTE: We avoid EAAccessoryManager.shared().registerFor
        NotificationCenter.default.addObserver(self, selector: #selector(accessoryDidConnect(_:)), name: .EAAccessoryDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(accessoryDidDisconnect(_:)), name: .EAAccessoryDidDisconnect, object: nil)
        EAAccessoryManager.shared().registerForLocalNotifications()
        
        // Initial connection attempt on launch
        Task { await findAndConnect() }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Connection Logic
    
    @objc func accessoryDidConnect(_ notification: Notification) {
        if isAutoConnectEnabled && self.session == nil {
            Task { await findAndConnect() }
        }
    }
    
    @objc func accessoryDidDisconnect(_ notification: Notification) {
        if let disconnectedAccessory = notification.userInfo?[EAAccessoryKey] as? EAAccessory,
           disconnectedAccessory.serialNumber == self.accessory?.serialNumber {
            disconnect()
            if isAutoConnectEnabled {
                Task { await findAndConnect() }
            }
        }
    }
    
    // Public entry point for connection attempts (e.g., on foreground or user toggle)
    func attemptConnection() {
        guard isAutoConnectEnabled else { return }
        if self.session == nil {
            Task { await findAndConnect() }
        }
    }
    
    func disconnectFromCurrent() {
        guard self.accessory != nil else { return }
        disconnect()
    }
    
    private func findAndConnect() async {
        guard self.session == nil else { return }
        
        // Check for connected accessories
        let accessories = EAAccessoryManager.shared().connectedAccessories
        
        guard let accessory = accessories.first(where: {
            $0.protocolStrings.contains(primaryProtocol) || $0.protocolStrings.contains(legacyProtocol)
        }) else {
            DispatchQueue.main.async {
                self.connectionStatus = "No Bad Elf Found"
            }
            return
        }
        
        // Determine protocol and set isLegacy flag
        if accessory.protocolStrings.contains(primaryProtocol) {
            self.isLegacy = false
            self.accessory = accessory
        } else if accessory.protocolStrings.contains(legacyProtocol) {
            self.isLegacy = true
            self.accessory = accessory
        } else {
            return // Should not happen based on the filter
        }
        
        // Open session
        if let session = EASession(accessory: accessory, forProtocol: isLegacy ? legacyProtocol : primaryProtocol) {
            self.session = session
            self.inputStream = session.inputStream
            self.outputStream = session.outputStream
            self.setupStreams()
            
            DispatchQueue.main.async {
                self.receiverName = accessory.name ?? "Bad Elf Receiver"
                self.serialNumber = accessory.serialNumber ?? "N/A"
                self.connectionStatus = "Connecting..."
            }
        }
    }
    
    private func setupStreams() {
        guard let inputStream = self.inputStream, let outputStream = self.outputStream else { return }
        
        inputStream.delegate = self
        inputStream.schedule(in: .current, forMode: .default)
        inputStream.open()
        
        outputStream.delegate = self
        outputStream.schedule(in: .current, forMode: .default)
        outputStream.open()
        
        DispatchQueue.main.async {
            self.connectionStatus = "Connected - Awaiting Streams"
        }
    }
    
    private func disconnect() {
        inputStream?.close()
        inputStream?.remove(from: .current, forMode: .default)
        inputStream = nil
        
        outputStream?.close()
        outputStream?.remove(from: .current, forMode: .default)
        outputStream = nil
        
        accessory = nil
        session = nil
        isConfigured = false
        isLegacy = false
        buffer = Data()
        pendingGga = nil
        pendingRmc = nil
        pendingGst = nil
        
        DispatchQueue.main.async {
            self.connectionStatus = "Disconnected"
            self.receiverName = "N/A"
            self.serialNumber = "N/A"
            self.currentGnssData = .empty
        }
    }
    
    // MARK: - Stream Delegate
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        
        switch eventCode {
        case .openCompleted:
            DispatchQueue.main.async {
                self.connectionStatus = "Connected"
            }
            if aStream == outputStream && !isConfigured {
                sendConfigurationMessage()
            }
        case .hasBytesAvailable:
            if aStream == inputStream {
                readData()
            }
        case .hasSpaceAvailable:
            if aStream == outputStream && !isConfigured {
                sendConfigurationMessage()
            }
        case .endEncountered, .errorOccurred:
            disconnect()
        default:
            break
        }
    }
    
    // MARK: - Configuration
    
    private func sendConfigurationMessage() {
        guard let outputStream = self.outputStream, outputStream.hasSpaceAvailable, !isConfigured else { return }
        
        var configData: Data?
        
        if isLegacy {
            // Binary configuration packet
            let hexString = "24be001105010205310132043301640d0a24be000a0100080b0d0a"
            
            var bytes = [UInt8]()
            for i in stride(from: 0, to: hexString.count, by: 2) {
                let startIndex = hexString.index(hexString.startIndex, offsetBy: i)
                let endIndex = hexString.index(startIndex, offsetBy: 2)
                let byteString = String(hexString[startIndex..<endIndex])
                if let byte = UInt8(byteString, radix: 16) {
                    bytes.append(byte)
                }
            }
            configData = Data(bytes)
            print("Sending binary config packet!")
        } else {
            // String configuration message (JSON/NMEA hybrid)
            let bundle = Bundle.main
            let appName = (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String) ?? "UnknownApp"
            let appId = (bundle.object(forInfoDictionaryKey: "CFBundleIdentifier") as? String) ?? "com.unknown.id"
            let appVersion = (bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "1.0"
            
            let template = "$PBEJS,{\"method\":\"session\",\"params\":{\"appName\":\"APP_NAME\",\"appId\":\"APP_BUNDLE_ID\",\"appVersion\":\"APP_VERSION\",\"msgs\":\"NMEA\"}}\""
            let rawString = template
                .replacingOccurrences(of: "APP_NAME", with: appName)
                .replacingOccurrences(of: "APP_BUNDLE_ID", with: appId)
                .replacingOccurrences(of: "APP_VERSION", with: appVersion)
            
            // Calculate Checksum and append CR/LF
            if let configString = NmeaParser.addChecksumAndTerminator(rawString) {
                configData = configString.data(using: .ascii)
                print("Sending config: \(configString)")
            }
        }
        
        if let data = configData {
            //let bytesWritten = outputStream.write(data.bytes)
            let bytesWritten = outputStream.write(data.withUnsafeBytes { $0.baseAddress!.assumingMemoryBound(to: UInt8.self) }, maxLength: data.count)
            if bytesWritten > 0 {
                isConfigured = true
            }
        }
    }
    
    // MARK: - Data Reading and NMEA Parsing
    
    private func readData() {
        guard let inputStream = self.inputStream else { return }
        
        let maxLength = 4*1024
        var readBuffer = [UInt8](repeating: 0, count: maxLength)
        let bytesRead = inputStream.read(&readBuffer, maxLength: maxLength)
        
        if bytesRead > 0 {
            //print("RX[\(bytesRead)]: ")
            let newData = Data(readBuffer[0..<bytesRead])
            buffer.append(newData)
            processBuffer()
        }
    }
    
    private func processBuffer() {
        while let sentence = extractNextNmeaSentence() {
            parseNmeaSentence(sentence)
        }
    }
    
    private func extractNextNmeaSentence() -> String? {
        
            while let start = buffer.firstIndex(of: 0x24) { // 0x24 is ASCII '$'
                let remainingBuffer = buffer.dropFirst(start - buffer.startIndex)
                
                // Find end of sentence (CR or LF)
                var end = 0
                if let endCR = remainingBuffer.firstIndex(of: 0x0D) {
                    end = endCR
                }
                if let endLF = remainingBuffer.firstIndex(of: 0x0A) {
                    if (end == remainingBuffer.startIndex || (endLF < end)) {
                        end = endLF
                    }
                }
                if (end > remainingBuffer.startIndex) {
                    
                    // Check for another '$' before the terminator
                    if let nextDollar = remainingBuffer.dropFirst().firstIndex(of: 0x24), nextDollar < end {
                        // Another '$' found before the end, discard up to the next '$' and try again
                        buffer.removeFirst(nextDollar - buffer.startIndex)
                        continue
                    }
                    
                    // Found a valid sentence span including $ and terminator(s)
                    let sentenceData = remainingBuffer.prefix((end - remainingBuffer.startIndex) + 1)
                    buffer.removeFirst((end + 1) - buffer.startIndex)
                    // Convert to String
                    if let sentence = String(data: sentenceData, encoding: .ascii)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                        return sentence
                    }
                }
                // No full sentence found, but a '$' was found. If the buffer is huge, we might need more logic,
                // but for typical NMEA messages, if we have a $, we wait for the end.
                return nil
            }
            
            // No '$' found, discard all current bytes
            if buffer.count > 0 {
                buffer.removeAll()
            }
            return nil
        }
    
    private func parseNmeaSentence(_ sentence: String) {
        
        guard NmeaParser.validateChecksum(sentence) else {
            print("NMEA Checksum failed or invalid format: \(sentence)")
            return
        }
        
        print("NMEA: \(sentence)")
        
        let components = sentence.split(separator: ",", omittingEmptySubsequences: false).map { String($0) }
        
        guard let talkerAndType = components.first, components.count >= 2 else { return }
        let sentenceType = String(talkerAndType.dropFirst(3)) // Remove '$G P' or similar
        
        switch sentenceType {
        case "GGA":
            pendingGga = NmeaParser.parseGga(components)
        case "RMC":
            pendingRmc = NmeaParser.parseRmc(components)
        case "GST":
            pendingGst = NmeaParser.parseGst(components)
        default:
            break // Ignore other sentences
        }
        
        if (isLegacy && pendingGga != nil) {
            // GST will never come, so build synthetic GST horizonal accuracy value from DOP
            let horizontalAccuracy: Double = (pendingGga!.hDOP ?? 1.0) * 3.9 // Magic number used by 2200/2300
            pendingGst = NmeaData(
                timestamp: pendingGga?.timestamp,
                horizontalAccuracy: horizontalAccuracy
            )
        }
        
        // Check for complete and matching data
        if let gga = pendingGga, let rmc = pendingRmc, let gst = pendingGst {
            if gga.timestamp == rmc.timestamp && gga.timestamp == gst.timestamp {
                
                // All timestamps match, merge and publish
                var completeData = gga
                completeData.date = rmc.date // Date comes from RMC
                completeData.speed = rmc.speed
                completeData.course = rmc.course
                completeData.horizontalAccuracy = gst.horizontalAccuracy
                
                DispatchQueue.main.async {
                    self.currentGnssData = completeData
                }
            } else {
                // Timestamps don't match, discard all pending data
                print("Data discarded due to timestamp mismatch: GGA(\(gga.timestamp ?? "nil")) RMC(\(rmc.timestamp ?? "nil")) GST(\(gst.timestamp ?? "nil"))")
            }
            
            // Reset pending data regardless of match
            pendingGga = nil
            pendingRmc = nil
            pendingGst = nil
        }
    }
}

// MARK: - 3. NMEA Parser
struct NmeaParser {
    
    // Converts $G PGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47 to 47
    static func validateChecksum(_ sentence: String) -> Bool {
        guard let asteriskIndex = sentence.firstIndex(of: "*") else { return false }
        
        let rawContent = sentence.prefix(upTo: asteriskIndex).dropFirst() // Remove '$'
        let receivedChecksumHex = sentence.suffix(from: sentence.index(after: asteriskIndex))
        
        guard let expectedChecksum = UInt8(String(receivedChecksumHex), radix: 16) else { return false }
        
        var calculatedChecksum: UInt8 = 0
        for byte in rawContent.utf8 {
            calculatedChecksum ^= byte
        }
        
        return calculatedChecksum == expectedChecksum
    }
    
    // Generates NMEA checksum and appends it with CR/LF
    static func addChecksumAndTerminator(_ rawMessage: String) -> String? {
        guard rawMessage.hasPrefix("$") else { return nil }
        
        let rawContent = rawMessage.dropFirst()
        var calculatedChecksum: UInt8 = 0
        for byte in rawContent.utf8 {
            calculatedChecksum ^= byte
        }
        
        let checksumHex = String(format: "%02X", calculatedChecksum)
        
        return "\(rawMessage)*\(checksumHex)\r\n"
    }
    
    // Helper to convert NMEA format (DDMM.MMMM, N/S/E/W) to decimal degrees
    static func convertToDecimal(latitude: String, northSouth: String) -> Double? {
        guard let dotIndex = latitude.firstIndex(of: ".") else { return nil }
        let ddmm = String(latitude.prefix(upTo: dotIndex))
        let mm_mmmm = String(latitude.suffix(from: dotIndex))
        
        guard ddmm.count >= 2, let degrees = Double(ddmm.dropLast(2)), let minutes = Double(ddmm.suffix(2) + mm_mmmm) else { return nil }
        
        var decimal = degrees + (minutes / 60.0)
        
        if northSouth == "S" || northSouth == "W" {
            decimal *= -1
        }
        return decimal
    }
    
    // Parses GGA sentence
    static func parseGga(_ components: [String]) -> NmeaData? {
        guard components.count >= 10 else { return nil }
        
        let timestamp = components[1].isEmpty ? nil : components[1]
        let lat = components[2]
        let ns = components[3]
        let lon = components[4]
        let ew = components[5]
        let fixTypeRaw = Int(components[6]) ?? 0
        let hDOP = Double(components[8])
        let altitude = Double(components[9])
        
        var fixType: String
        switch fixTypeRaw {
        case 1: fixType = "AUT Fix"
        case 2: fixType = "SBAS Fix" // Replaced DGPS with SBAS
        case 3: fixType = "PPS Fix"
        case 4: fixType = "RTK Fix"
        case 5: fixType = "RTK Float"
        case 6: fixType = "Estimated"
        default: fixType = "No Fix"
        }
        
        let decimalLat = convertToDecimal(latitude: lat, northSouth: ns)
        let decimalLon = convertToDecimal(latitude: lon, northSouth: ew)
        
        return NmeaData(
            timestamp: timestamp,
            latitude: decimalLat,
            longitude: decimalLon,
            altitude: altitude,
            fixType: fixType,
            hDOP: hDOP
        )
    }
    
    // Parses RMC sentence
    static func parseRmc(_ components: [String]) -> NmeaData? {
        guard components.count >= 10 else { return nil }
        
        let timestamp = components[1].isEmpty ? nil : components[1]
        let speed = Double(components[7])
        let course = Double(components[8])
        let date = components[9].isEmpty ? nil : components[9]
        
        return NmeaData(
            timestamp: timestamp,
            date: date,
            speed: speed,
            course: course
        )
    }
    
    // Parses GST sentence
    static func parseGst(_ components: [String]) -> NmeaData? {
        guard components.count >= 8 else { return nil }
        
        let timestamp = components[1].isEmpty ? nil : components[1]
        let latError = Double(components[6]) // Field 6: Latitude Error (meters)
        let lonError = Double(components[7]) // Field 7: Longitude Error (meters)
        
        var horizontalAccuracy: Double?
        if let latErr = latError, let lonErr = lonError {
            // Horizontal Accuracy = sqrt(latErr^2 + lonErr^2) (Pythagorean theorem)
            horizontalAccuracy = sqrt(pow(latErr, 2) + pow(lonErr, 2))
        }
        
        return NmeaData(
            timestamp: timestamp,
            horizontalAccuracy: horizontalAccuracy
        )
    }
}

// MARK: - 4. SwiftUI View
struct ContentView: View {
    @StateObject private var receiver = BadElfReceiver.shared
    @Environment(\.scenePhase) private var scenePhase // For foreground/background detection
    
    private var isConnected: Bool {
        receiver.connectionStatus.contains("Connected")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // --- Header: Receiver Info ---
            Group {
                Text("Bad Elf GNSS App")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 5)

                HStack {
                    Image(systemName: isConnected ? "antenna.radiowaves.left.and.right" : "xmark.octagon.fill")
                        .foregroundColor(isConnected ? .green : .red)
                    Text("**Status:** \(receiver.connectionStatus)")
                }
                .font(.headline)
                .padding(.bottom, 5)
                
                HStack(spacing: 20) {
                    Label(receiver.receiverName, systemImage: "sparkle.magnifyingglass")
                        .lineLimit(1)
                    Label(receiver.serialNumber, systemImage: "number.circle")
                        .lineLimit(1)
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            Divider().padding(.vertical, 10)
            
            // --- Realtime GPS Data Grid ---
            Group {
                Text("Realtime GPS Parameters")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.bottom, 10)
                
                //

//[Image of GNSS satellite system diagram]

                
                NmeaDataView(
                    icon: "clock.fill",
                    title: "Time (UTC)",
                    value: receiver.currentGnssData.timestamp ?? "N/A",
                    detail: receiver.currentGnssData.date.map { "Date: \($0)" }
                )
                
                NmeaDataView(
                    icon: "location.fill",
                    title: "Latitude / Longitude",
                    value: String(format: "%.7f / %.7f", receiver.currentGnssData.latitude ?? 0, receiver.currentGnssData.longitude ?? 0),
                    detail: ""
                )
                
                NmeaDataView(
                    icon: "mountain.2.circle",
                    title: "Altitude",
                    value: receiver.currentGnssData.latitude == nil ? "N/A" : "\(String(format: "%.1f", receiver.currentGnssData.altitude ?? 0))m",
                    detail: ""
                )
                
                NmeaDataView(
                    icon: "figure.walk",
                    title: "Speed",
                    value: receiver.currentGnssData.speed.map { "\(String(format: "%.1f", $0)) kts" } ?? "N/A",
                    detail: ""
                )
                
                NmeaDataView(
                    icon: "target",
                    title: "Horizontal Accuracy",
                    value: receiver.currentGnssData.horizontalAccuracy.map { String(format: "%.1f m", $0) } ?? "N/A",
                    detail: "" // Computed via Pythagoras (GST)"
                )
                
                NmeaDataView(
                    icon: "lock.fill",
                    title: "Fix Type",
                    value: "\(receiver.currentGnssData.fixType ?? "No Fix")",
                    detail: ""
                )
            }
            .opacity(receiver.currentGnssData.hasCoreData ? 1.0 : 0.6)
            .padding(.horizontal)
            
            Spacer()
            
            // --- Auto-Connect Toggle ---
            VStack {
                Divider()
                Toggle(isOn: $receiver.isAutoConnectEnabled.animation()) {
                    Label("Auto-Connect to GNSS Receiver", systemImage: "bolt.horizontal.fill")
                }
                .onChange(of: receiver.isAutoConnectEnabled) { newValue in
                    if newValue {
                        receiver.attemptConnection()
                    } else {
                        receiver.disconnectFromCurrent()
                    }
                }
                .padding()
            }
            .background(Color(.systemGray6))
        }
        .padding(.top)
        .onAppear {
            // Initial connection attempt
            receiver.attemptConnection()
        }
        .onChange(of: scenePhase) { newPhase in
            // Perform auto-connect logic when app comes to foreground
            if newPhase == .active {
                receiver.attemptConnection()
            }
        }
    }
}

// Custom View for Data Display
struct NmeaDataView: View {
    let icon: String
    let title: String
    let value: String
    let detail: String?
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: icon)
                .font(.title)
                .frame(width: 30)
                .foregroundColor(.accentColor)
                .padding(.trailing, 5)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                
                if let detail = detail {
                    Text(detail)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 5. App Entry Point
@main
struct BadElfGnssSampleApp: App {
    // Initialize the shared receiver manager to ensure it's available
    @StateObject private var receiver = BadElfReceiver.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
