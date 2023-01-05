/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Defines an interface to wrap Watch Connectivity APIs and bridge the UI.
*/

import UIKit
import WatchConnectivity

// Define an interface to wrap Watch Connectivity APIs and bridge the UI.
//
protocol SessionCommands {
    func updateAppContext(_ context: [String: Any])
    func sendMessage(_ message: [String: Any])
    func sendMessageData(_ messageData: Data)
    func deleteData()
    func transferUserInfo(_ userInfo: [String: Any])
    func transferFile(_ file: URL, metadata: [String: Any])
    func transferCurrentComplicationUserInfo(_ userInfo: [String: Any])
}

// Implement the commands. Every command handles the communication and notifies clients
// when WCSession status changes or data flows.
//
extension SessionCommands {
    
    // Update the app context if the session is activated, and update UI with the command status.
    //
    func updateAppContext(_ context: [String: Any]) {
        var commandStatus = CommandStatus(command: .updateAppContext, phrase: .updated)
        commandStatus.timedColor = TimedColor(context)
        
        guard WCSession.default.activationState == .activated else {
            return handleSessionUnactivated(with: commandStatus)
        }
        do {
            try WCSession.default.updateApplicationContext(context)
        } catch {
            commandStatus.phrase = .failed
            commandStatus.errorMessage = error.localizedDescription
        }
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
    }

    // Send a message if the session is activated, and update the UI with the command status.
    //
    func sendMessage(_ message: [String: Any]) {
        var commandStatus = CommandStatus(command: .sendMessage, phrase: .sent)
        commandStatus.timedColor = TimedColor(message)

        guard WCSession.default.activationState == .activated else {
            return handleSessionUnactivated(with: commandStatus)
        }
        
        // A reply handler block runs asynchronously on a background thread and should return quickly.
        WCSession.default.sendMessage(message, replyHandler: { replyMessage in
            commandStatus.phrase = .replied
            commandStatus.timedColor = TimedColor(replyMessage)
            self.postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)

        }, errorHandler: { error in
            commandStatus.phrase = .failed
            commandStatus.errorMessage = error.localizedDescription
            self.postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
        })
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
    }
    
    func deleteData() {
        print("delete data")
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            if let dir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.nmslab") {
                let fileURLs = try fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
                for fileURL in fileURLs {
                    print ("Ext \(fileURL.pathExtension)")
                    if fileURL.pathExtension=="txt" ||  fileURL.pathExtension=="caf" || fileURL.pathExtension=="wav" {
                        print ("delete File1 \(fileURL)")
                        do {
                            try FileManager.default.removeItem(at: fileURL)
                        } catch let error as NSError {
                            print("Error: \(error.domain)")
                        }
                    }
                }
            }
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        }
        
    }
    
    // Send a piece of message data if the session is activated, and update the UI with the command status.
    //
    func sendMessageData(_ messageData: Data) {
        var commandStatus = CommandStatus(command: .sendMessageData, phrase: .sent)
        commandStatus.timedColor = TimedColor(messageData)
        
        guard WCSession.default.activationState == .activated else {
            return handleSessionUnactivated(with: commandStatus)
        }

        // A reply handler block runs asynchronously on a background thread and should return quickly.
        WCSession.default.sendMessageData(messageData, replyHandler: { replyData in
            commandStatus.phrase = .replied
            commandStatus.timedColor = TimedColor(replyData)
            self.postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)

        }, errorHandler: { error in
            commandStatus.phrase = .failed
            commandStatus.errorMessage = error.localizedDescription
            self.postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
        })
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
    }
    
    // Transfer a piece of user info if the session is activated, and update the UI with the command status.
    // Returns a WCSessionUserInfoTransfer object to monitor the progress or cancel the operation.
    //
    func transferUserInfo(_ userInfo: [String: Any]) {
        var commandStatus = CommandStatus(command: .transferUserInfo, phrase: .transferring)
        commandStatus.timedColor = TimedColor(userInfo)

        guard WCSession.default.activationState == .activated else {
            return handleSessionUnactivated(with: commandStatus)
        }

        commandStatus.userInfoTranser = WCSession.default.transferUserInfo(userInfo)
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
    }
    
    // Transfer a file if the session is activated, and update the UI with the command status.
    // Return a WCSessionFileTransfer object to monitor the progress or cancel the operation.
    //
    func transferFile(_ file: URL, metadata: [String: Any]) {
        var commandStatus = CommandStatus(command: .transferFile, phrase: .transferring)
        commandStatus.timedColor = TimedColor(metadata)

        guard WCSession.default.activationState == .activated else {
            return handleSessionUnactivated(with: commandStatus)
        }
        
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            if let dir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.nmslab") {
                let fileURLs = try fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
                for fileURL in fileURLs {
                    print ("Ext \(fileURL.pathExtension)")
                    if fileURL.pathExtension=="txt" ||  fileURL.pathExtension=="caf" || fileURL.pathExtension=="wav" {
                        print ("transfer File1 \(fileURL)")
                        commandStatus.fileTransfer = WCSession.default.transferFile(fileURL, metadata: metadata)
                        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
                    }
                }
            }
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        }
        
        print ("finish")
    }
    
    // Transfer a piece of user info for current complications if the session is activated,
    // and update the UI with the command status.
    // Return a WCSessionUserInfoTransfer object to monitor the progress or cancel the operation.
    //
    func transferCurrentComplicationUserInfo(_ userInfo: [String: Any]) {
        var commandStatus = CommandStatus(command: .transferCurrentComplicationUserInfo, phrase: .failed)
        commandStatus.timedColor = TimedColor(userInfo)

        guard WCSession.default.activationState == .activated else {
            return handleSessionUnactivated(with: commandStatus)
        }
        
        commandStatus.errorMessage = "Not supported on watchOS!"
        
        #if os(iOS)
        if WCSession.default.isComplicationEnabled {
            let userInfoTranser = WCSession.default.transferCurrentComplicationUserInfo(userInfo)
            commandStatus.phrase = .transferring
            commandStatus.errorMessage = nil
            commandStatus.userInfoTranser = userInfoTranser
            
        } else {
            commandStatus.errorMessage = "\nComplication is not enabled!"
        }
        #endif
        
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
    }
    
    // Post a notification from the main queue asynchronously.
    //
    private func postNotificationOnMainQueueAsync(name: NSNotification.Name, object: CommandStatus) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: name, object: object)
        }
    }

    // Handle unactivated session error. WCSession commands require an activated session.
    //
    private func handleSessionUnactivated(with commandStatus: CommandStatus) {
        var mutableStatus = commandStatus
        mutableStatus.phrase = .failed
        mutableStatus.errorMessage = "WCSession is not activated yet!"
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
    }
}
