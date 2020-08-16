//
//  MSCaptureView.swift
//  MSCaptureView
//
//  Created by Steve Sheets on 8/13/20.
//  Copyright © 2020 Steve Sheets. All rights reserved.
//

import Cocoa
import AVFoundation

// MARK: MSCaptureView Class

/// NSView subclass to provied video capture and preview from Macintosh Cameria/Microphone
public class MSCaptureView: NSView, AVCaptureFileOutputRecordingDelegate {
    
    // MARK: Static Properties
    
    /// Version information (major, minor, patch)
    public static let version = (1, 0, 0)
    
    // MARK: Type Alias
    
    /// Closure type that is passed the current Capture View and returns nothing
    public typealias StatusChangedEventClosure = (MSCaptureView) -> Void

    /// Closure type that is passed nothing View and returns nothing
    public typealias AuthorizedEventClosure = () -> Void

    // MARK: Private Property
    
    private var captureSession: AVCaptureSession?
    private var capturePreviewLayer: AVCaptureVideoPreviewLayer?
    private var captureDeviceInputCamera: AVCaptureDeviceInput?
    private var captureDeviceInputMicrophone: AVCaptureDeviceInput?
    private var captureMovieFileOutput: AVCaptureMovieFileOutput?
    private var captureURL: URL?

    // MARK: Public Properties
    
    /// Closure evoked when the recording starts
    public var captureRecordingStartedEvent: StatusChangedEventClosure?
    
    /// Closure evoked when the recording stops (either by call or by error).
    public var captureRecordingStoppedEvent: StatusChangedEventClosure?

    // MARK: Public Read-Only Properties
    
    /// Calculated property showing if the app has been authorized to use camera and microphone
    public var hasCaptureAuthorization: Bool {
        get {
            let videoStatus = AVCaptureDevice.authorizationStatus(for: .video)
            let microphoneStatus = AVCaptureDevice.authorizationStatus(for: .audio)

            if case .authorized = videoStatus, case .authorized = microphoneStatus {
                return true
            }
            
            return false
        }
    }
    
    /// Calculated property showing if the app has preview turned on.
    public var hasPreview: Bool {
        get {
            guard let session = captureSession else { return false }
            
            return session.isRunning
        }
    }
    
    /// Calculated property showing if the app has output url set.
    public var hasURL: Bool {
        get {
            return captureURL != nil
        }
    }
    
    /// Calculated property showing if the app is currently capturing
    public var isCapturing: Bool {
        get {
            guard let output = captureMovieFileOutput else { return false }
            
            return output.isRecording
        }
    }
    
    // MARK: Private Static Functions
    
    private static func requestAudioAuthorization(success: @escaping AuthorizedEventClosure) {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
            case .authorized:
                success()
                return
            
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .audio) {granted in
                    guard granted else { return }
                        
                    success()
                }

            case .denied,
                .restricted:
                return
            
            @unknown default:
                return
        }
    }

    // MARK: Public Static Functions
    
    /// Check the audio & video authorization. If not determined, makes requrest for them (displaying UI).  If users has authorized both video and audio, then closure is invoked.
    /// - Parameter success: AuthorizedEventClosure to invoke if both video and audio is authorized.
    public static func requestCaptureAuthorization(success: @escaping AuthorizedEventClosure) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                requestAudioAuthorization(success: success)
                return
            
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    guard granted else { return }
                    
                    MSCaptureView.requestAudioAuthorization(success: success)
                }

            case .denied,
                .restricted:
                return
            
            @unknown default:
                return
        }
    }
    
    // MARK: Public Functions
    
    /// Set URL to output captured video to.
    ///
    /// If file already exists at this location, the file will be deleted as start of capture, not at setting the Capture URL.
    /// - Parameter url: URL to output.
    public func use(url: URL) {
        captureURL = url
    }
    
    /// Clears the capture URL (the URL used to save the captured file to).
    public func clearURL() {
        captureURL = nil
    }
    
    /// Attempts to turn on Preview layer on view.  Return success if this occurs.
    ///
    /// The actual video may take a second or two before it appears.  This call creates the majority of the internal settings.
    /// If the app is not authorized, or if the Preview is already turned on, this call does nothing.
    /// - Returns: BOOL if video is turned on, returns True.
    @discardableResult public func showPreview() -> Bool {
        guard hasCaptureAuthorization, captureSession==nil else { return true }
        
        self.wantsLayer = true

        let session = AVCaptureSession()
        session.sessionPreset = .high

        let layer = AVCaptureVideoPreviewLayer(session: session)
        
        guard let camera = AVCaptureDevice.default(for: AVMediaType.video), let cameraInput = try? AVCaptureDeviceInput(device: camera) else { return false }
        
        if session.canAddInput(cameraInput) {
            session.addInput(cameraInput)
        }

        guard let microphone = AVCaptureDevice.default(for: AVMediaType.audio), let microphoneInput = try? AVCaptureDeviceInput(device: microphone) else { return false }
        
        if session.canAddInput(microphoneInput) {
            session.addInput(microphoneInput)
        }

        let movieOutput = AVCaptureMovieFileOutput()
        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
        }
    
        layer.frame = self.bounds
        layer.videoGravity = .resizeAspectFill
        self.layer = layer
        self.layerContentsPlacement = .scaleAxesIndependently

        captureSession = session
        capturePreviewLayer = layer
        captureDeviceInputCamera = cameraInput
        captureDeviceInputMicrophone = microphoneInput
        captureMovieFileOutput = movieOutput

        session.startRunning()
        
        return true
    }
    
    /// Turns off the Preview layer on view.
    ///
    /// If the app is not authorized, or if the Preview is not turned on, this call does nothing.
    public func hidePreview() {
        guard hasCaptureAuthorization, let session = captureSession, let layer = capturePreviewLayer, let cameraInput = captureDeviceInputCamera, let microphoneInput = captureDeviceInputMicrophone, let movieOutput = captureMovieFileOutput else { return }
        
        session.stopRunning()
        
        self.layer = CALayer()
        self.wantsLayer = true

        layer.session = nil
        
        if session.canAddInput(cameraInput) {
            session.removeInput(cameraInput)
        }

        if session.canAddInput(microphoneInput) {
            session.removeInput(microphoneInput)
        }

        if session.canAddOutput(movieOutput) {
            session.removeOutput(movieOutput)
        }

        captureSession = nil
        capturePreviewLayer = nil
        captureDeviceInputCamera = nil
        captureDeviceInputMicrophone = nil
        captureMovieFileOutput = nil
    }
    
    /// Starts capturing the video to the output URL.
    ///
    /// If the app is not authroized, or if the Capture URL is not set, or if the capturing is already started, this call does nothing.
    /// If successful, the captureRecordingStartedEvent will be invoked.
    /// If the file has permission issues, the captureRecordingStoppedEvent will be invoked after captureRecordingStartedEvent.
    /// If the Capture URL points to a file that exists, this call will delete it before starting recording.
    public func startCapture() {
        guard hasCaptureAuthorization, let url = captureURL, let output = captureMovieFileOutput else { return }

        do {
            try FileManager.default.removeItem(at: url)
        }
        catch {
        }

        output.startRecording(to: url, recordingDelegate: self)
    }

    /// Stops capturing the video to the output URL.
    ///
    /// If the app is not authroized, or if the Capture URL is not set, or if the capturing is already started, this call does nothing.
    /// If succesfull, the captureRecordingStoppedEvent closure will be invoked.
    public func stopCapture() {
        guard hasCaptureAuthorization, let output = captureMovieFileOutput else { return }
        
        output.stopRecording()
    }
    
    // MARK: Delegate Functions
    
    public func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo: URL, from: [AVCaptureConnection]) {
        if let block = captureRecordingStartedEvent {
            block(self)
        }
    }
    
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let block = captureRecordingStoppedEvent {
            block(self)
        }

        if let error = error {
            print("AV File Capture Error: \(error.localizedDescription)")
        }
    }

}

