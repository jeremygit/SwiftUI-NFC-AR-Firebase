//
//  NFCView.swift
//  NavViewARStuff
//
//  Created by Jeremy Heritage on 15/8/20.
//  Copyright © 2020 Jeremy Heritage. All rights reserved.
//

import SwiftUI
import Combine
import CoreNFC

enum NFCAction {
    case scan, write
}

class NFCTagWriter: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
    
    @Published var writeData: String = ""
    
    private var session: NFCNDEFReaderSession?
    
    func startSession() {
        print("Start Write")

        guard NFCNDEFReaderSession.readingAvailable
        else {
            print("error: Scanning not supported")
            return
        }

        print("scanning suppported")

        self.session = NFCNDEFReaderSession(delegate: self, queue: DispatchQueue.main, invalidateAfterFirstRead: false)

        self.session?.alertMessage = "Hold phone near tag"

        self.session?.begin()

        print("scanning began")
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        //
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        //
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard let tag = tags.first
        else {
            self.session?.alertMessage = "Some tag error."
            self.session?.invalidate()
            return
        }
        
        session.connect(to: tag) { error in
            tag.queryNDEFStatus {status, _, error in
                if let error = error {
                    return
                }

                switch(status) {
                    case .notSupported:
                        print("not supported")
                        session.invalidate()
                    case .readOnly:
                        print("read only")
                        session.invalidate()
                    case .readWrite:
                        print("tag writeable")
                        //write tag
                        self.writeTag(tag: tag)
                    default:
                        return
                }
            }
        }
        
    }
    
    func writeTag(tag: NFCNDEFTag) {
         // payload
         guard let payload = self.writeData.data(using: .utf8)
         else {
             print("payload error")
             return
         }
         
        let ndefPayload = NFCNDEFPayload(
             format: .nfcWellKnown,
             type: Data(),
             identifier: Data(),
             payload: payload
         )
         
         // message
         let message = NFCNDEFMessage(records: [ndefPayload])
         
         tag.writeNDEF(message) { error in
            if let error = error {
                return
            }
            self.session?.alertMessage = "Wrote  data."
            self.session?.invalidate()
            self.clearWriteData()
         }
    }
    
    func clearWriteData() {
        self.writeData = ""
    }
    
    func write() {
        self.startSession()
    }
    
}

class NFCTagMessageReader: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
    
    private var session: NFCNDEFReaderSession?
    
    @Published var readDataStr: String = ""
    @Published var readDataArr: [String] = [String]()
    
    func startSession() {
        print("Start Write")

        guard NFCNDEFReaderSession.readingAvailable
        else {
            print("error: Scanning not supported")
            return
        }

        print("scanning suppported")

        self.session = NFCNDEFReaderSession(delegate: self, queue: DispatchQueue.main, invalidateAfterFirstRead: false)

        self.session?.alertMessage = "Hold phone near tag"

        self.session?.begin()

        print("scanning began")
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        //
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        print("did detect")
        for message in messages {
            for record in message.records {
                if let string = String(data: record.payload, encoding: .utf8) {
                    self.readDataStr += string
                }
            }
        }
        self.session?.invalidate()
    }
    
    func clearReadData() {
        self.readDataStr = ""
    }
    
    func read() {
        self.clearReadData()
        self.startSession()
    }
    
}

struct NFCView: View {
    
    @State private var payloadText: String = ""
    
    @ObservedObject var nfcReadable = NFCTagMessageReader()
    @ObservedObject var nfcWriteable = NFCTagWriter()
    
    var body: some View {
        VStack {
            Text("Data")
            TextField("Write text to tag", text: self.$nfcWriteable.writeData)
            Text("\(self.nfcReadable.readDataStr ?? "")")
            // NFCScanButton()
            Button("Scan NFC Object") {
                self.nfcReadable.read()
            }

            Button("Write NFC Object") {
                self.nfcWriteable.write()
            }
            Spacer()
        }.navigationBarTitle("Gummi NFC")
    }
}


struct NFCView_Previews: PreviewProvider {
    static var previews: some View {
        NFCView()
    }
}


struct NFCScanButton: UIViewRepresentable {
    
    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .system)
        
        button.setTitle("Scan NFC", for: .normal)
        
        button.addTarget(
            context.coordinator,
            action: #selector(Coordinator.startScan(_:)),
            for: .touchUpInside
        )
        
        return button
    }
    
    func updateUIView(_ uiView: UIButton, context: Context) {
        // nothing
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, NFCNDEFReaderSessionDelegate {
        
        private var session: NFCNDEFReaderSession?
        
        func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
            if let readerError = error as? NFCReaderError {
                if (readerError.code != .readerSessionInvalidationErrorFirstNDEFTagRead)
                    && (readerError.code != .readerSessionInvalidationErrorUserCanceled){
                    print("Error nfc read: \(readerError.localizedDescription)")
                    
                }
            }
            // to read a new tags
            self.session = nil
        }
        
        func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
            guard
                let nfcMessage = messages.first,
                let record = nfcMessage.records.first,
                record.typeNameFormat == .absoluteURI ||
                record.typeNameFormat == .nfcWellKnown,
                let payload = String(data: record.payload, encoding: .utf8)
            else {
                return
            }
            print(payload)
        }
        
        @objc func startScan(_ sender: Any) {
            
            print("button pressed")
            
            guard NFCNDEFReaderSession.readingAvailable
            else {
                print("error: Scanning not supported")
                return
            }
            
            self.session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
            
            self.session?.alertMessage = "Hold phone near tag"
            
            self.session?.begin()
        }
        
    }
}
