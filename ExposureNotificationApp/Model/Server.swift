/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A class representing a local server that vends exposure data.
*/

import Foundation
import ExposureNotification

struct CodableDiagnosisKey: Codable, Equatable {
    let keyData: Data
    let rollingPeriod: ENIntervalNumber
    let rollingStartNumber: ENIntervalNumber
    let transmissionRiskLevel: ENRiskLevel
}

struct CodableExposureConfiguration: Codable {
    let minimumRiskScore: ENRiskScore
    let attenuationLevelValues: [ENRiskLevelValue]
    let attenuationWeight: Double
    let daysSinceLastExposureLevelValues: [ENRiskLevelValue]
    let daysSinceLastExposureWeight: Double
    let durationLevelValues: [ENRiskLevelValue]
    let durationWeight: Double
    let transmissionRiskLevelValues: [ENRiskLevelValue]
    let transmissionRiskWeight: Double
}

// Replace this class with your own class that communicates with your server.
class Server {
    
    static let shared = Server()
    
    // For testing purposes, this object stores all of the TEKs it receives locally on device
    // In a real implementation, these would be stored on a remote server
    @Persisted(userDefaultsKey: "diagnosisKeys", notificationName: .init("ServerDiagnosisKeysDidChange"), defaultValue: [])
    var diagnosisKeys: [CodableDiagnosisKey]
    func postDiagnosisKeys(_ diagnosisKeys: [ENTemporaryExposureKey], completion: (Error?) -> Void) {
        
        // Convert keys to something that can be encoded to JSON and upload them.
        let codableDiagnosisKeys = diagnosisKeys.compactMap { diagnosisKey -> CodableDiagnosisKey? in
            return CodableDiagnosisKey(keyData: diagnosisKey.keyData,
                                       rollingPeriod: diagnosisKey.rollingPeriod,
                                       rollingStartNumber: diagnosisKey.rollingStartNumber,
                                       transmissionRiskLevel: diagnosisKey.transmissionRiskLevel)
        }
        
        // In a real implementation, these keys would be uploaded with URLSession instead of being saved here.
        // Your server needs to handle de-duplicating keys.
        for codableDiagnosisKey in codableDiagnosisKeys where !self.diagnosisKeys.contains(codableDiagnosisKey) {
            self.diagnosisKeys.append(codableDiagnosisKey)
        }
        completion(nil)
    }
    func getDiagnosisKeyFileURLs(startingAt index: Int, completion: (Result<[URL], Error>) -> Void) {
        
        // In a real implementation, these URLs would be retrieved from a server with URLSession
        // This sample only returns one placeholder URL, because the diagnosis key file is generated in each call to downloadDiagnosisKeyFile
        let remoteURLs = [URL(string: "/url/to/file/")!]
        
        completion(.success(Array(remoteURLs[min(index, remoteURLs.count)...])))
    }
    
    // The URL passed to the completion is the local URL of the downloaded diagnosis key file
    func downloadDiagnosisKeyFile(at remoteURL: URL, completion: (Result<URL, Error>) -> Void) {
        
        // In a real implementation, the file at remoteURL would be downloaded from a server
        // This sample ignores the remote URL and just generates and saves a file based on the locally stored diagnosis keys
        let file = File.with { file in
            file.key = diagnosisKeys.map { diagnosisKey in
                Key.with { key in
                    key.keyData = diagnosisKey.keyData
                    key.rollingPeriod = diagnosisKey.rollingPeriod
                    key.rollingStartNumber = diagnosisKey.rollingStartNumber
                    key.transmissionRiskLevel = Int32(diagnosisKey.transmissionRiskLevel)
                }
            }
        }
        
        do {
            let data = try file.serializedData()
            let localURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("diagnosisKeys")
            try data.write(to: localURL)
            completion(.success(localURL))
        } catch {
            completion(.failure(error))
        }
    }
    
    func deleteDiagnosisKeyFile(at localURL: URL) throws {
        try FileManager.default.removeItem(at: localURL)
    }
    
    func getExposureConfiguration(completion: (Result<ENExposureConfiguration, Error>) -> Void) {
        
        let dataFromServer = """
        {"minimumRiskScore":0,
        "attenuationLevelValues":[1, 2, 3, 4, 5, 6, 7, 8],
        "attenuationWeight":50,
        "daysSinceLastExposureLevelValues":[1, 2, 3, 4, 5, 6, 7, 8],
        "daysSinceLastExposureWeight":50,
        "durationLevelValues":[1, 2, 3, 4, 5, 6, 7, 8],
        "durationWeight":50,
        "transmissionRiskLevelValues":[1, 2, 3, 4, 5, 6, 7, 8],
        "transmissionRiskWeight":50}
        """.data(using: .utf8)!
        
        do {
            let codableExposureConfiguration = try JSONDecoder().decode(CodableExposureConfiguration.self, from: dataFromServer)
            let exposureConfiguration = ENExposureConfiguration()
            exposureConfiguration.minimumRiskScore = codableExposureConfiguration.minimumRiskScore
            exposureConfiguration.attenuationLevelValues = codableExposureConfiguration.attenuationLevelValues as [NSNumber]
            exposureConfiguration.attenuationWeight = codableExposureConfiguration.attenuationWeight
            exposureConfiguration.daysSinceLastExposureLevelValues = codableExposureConfiguration.daysSinceLastExposureLevelValues as [NSNumber]
            exposureConfiguration.daysSinceLastExposureWeight = codableExposureConfiguration.daysSinceLastExposureWeight
            exposureConfiguration.durationLevelValues = codableExposureConfiguration.durationLevelValues as [NSNumber]
            exposureConfiguration.durationWeight = codableExposureConfiguration.durationWeight
            exposureConfiguration.transmissionRiskLevelValues = codableExposureConfiguration.transmissionRiskLevelValues as [NSNumber]
            exposureConfiguration.transmissionRiskWeight = codableExposureConfiguration.transmissionRiskWeight
            completion(.success(exposureConfiguration))
        } catch {
            completion(.failure(error))
        }
    }
    
    func verifyUniqueTestIdentifier(_ identifier: String, completion: (Result<Bool, Error>) -> Void) {
        
        // In a real implementation, this identifer would be validated on a server
        completion(.success(identifier == "000000"))
    }
}
