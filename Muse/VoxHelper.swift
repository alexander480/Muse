//
//  VoxHelper.swift
//  Muse
//
//  Created by Marco Albera on 29/12/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

import ScriptingBridge

@objc fileprivate protocol VoxApplication: class {
    var isRunning: Bool { get }
    
    // Track properties
    @objc optional var track: String { get }
    @objc optional var artist: String { get }
    @objc optional var album: String { get }
    @objc optional var totalTime: Double { get }
    @objc optional var artworkImage: NSImage { get }
    
    // Playback properties
    @objc optional var currentTime: Double { get }
    @objc optional var playerState: VoxEPlS { get }
    @objc optional var playerVolume: Double { get }
    @objc optional var repeatState: VoxERpS { get }
    
    // Playback control functions
    @objc optional func playpause()
    @objc optional func previous()
    @objc optional func next()
    @objc optional func shuffle()
    
    // Playback properties - setters
    @objc optional func setCurrentTime(_ time: Double)
    @objc optional func setPlayerState(_ state: VoxEPlS)
    @objc optional func setPlayerVolume(_ volume: Double)
    @objc optional func setRepeatState(_ state: VoxERpS)
}

// Protocols will implemented and populated through here
extension SBApplication: VoxApplication { }

class VoxHelper: PlayerHelper {
    
    // Singleton contructor
    static let shared = VoxHelper()
    
    // The SBApplication object buond to the helper class
    private let application: VoxApplication = SBApplication.init(bundleIdentifier: BundleIdentifier)!
    
    // MARK: Player availability
    
    var isAvailable: Bool {
        // Returns if the application is running
        // ( implemented by SBApplication )
        return application.isRunning
    }
    
    // MARK: Player features
    
    let doesSendPlayPauseNotification = false
    
    // MARK: Song data
    
    var song: Song {
        return Song(name: application.track!,
                    artist: application.artist!,
                    album: application.album!,
                    duration: application.totalTime!)
    }
    
    // MARK: Playback controls
    
    func togglePlayPause() {
        application.playpause!()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(10), execute: {
            self.playPauseHandler()
        })
    }
    
    func nextTrack() {
        application.next!()
        
        trackChangedHandler()
    }
    
    func previousTrack() {
        application.previous!()
        
        trackChangedHandler()
    }
    
    // MARK: Playback status
    
    var isPlaying: Bool {
        let isPlaying = application.playerState == .playing
        
        // Return current playback status ( R/O )
        return isPlaying
    }
    
    var playbackPosition: Double {
        set {
            // Set the position on the player
            application.setCurrentTime!(newValue)
        }
        
        get {
            guard let playbackPosition = application.currentTime else { return 0 }
            
            // Return current playback position
            return playbackPosition
        }
    }
    
    var trackDuration: Double {
        guard let trackDuration = application.totalTime else { return 0 }
        
        // Return current track duration
        return trackDuration
    }
    
    func scrub(to doubleValue: Double? = nil, touching: Bool = false) {
        if !touching, let value = doubleValue {
            playbackPosition = value * trackDuration
        }
        
        timeChangedHandler(touching, doubleValue)
    }
    
    // MARK: Playback options
    
    var volume: Int {
        set {
            // Set the volume on the player
            application.setPlayerVolume!(Double(newValue))
        }
        
        get {
            guard let volume = application.playerVolume else { return 0 }
            
            // Get current volume
            // casting to Integer because Vox provides a Double
            return Int(volume)
        }
    }
    
    // TODO: This is broken!
    // Vox AppleScript command for getting and toggling
    // repeat does not work (always returns 0, set does nothing)
    var repeating: Bool {
        set {
            let repeating: VoxERpS = newValue ? .repeatAll : .none
            
            // Toggle repeating on the player
            application.setRepeatState!(repeating)
            
            // Call the ghandler with new repeat value
            shuffleRepeatChangedHandler(nil, newValue)
        }
        
        get {
            guard let repeating = application.repeatState else { return false }
            
            // return current repeating status
            // 1: repeat one, 2: repeat all 
            return (repeating == .repeatOne || repeating == .repeatAll)
        }
    }
    
    var shuffling: Bool {
        set {
            // Toggle shuffling on the player
            application.shuffle!()
            
            // Call the handler with new shuffle value
            shuffleRepeatChangedHandler(false, nil)
        }
        
        get {
            // Vox does not provide information on shuffling
            // only a toggle function
            return false
        }
    }
    
    // MARK: Artwork
    
    func artwork() -> Any? {
        return application.artworkImage
    }
    
    // MARK: Callbacks
    
    var playPauseHandler: () -> () = { }
    
    var trackChangedHandler: () -> () = { }
    
    var timeChangedHandler: (Bool, Double?) -> () = { _, _ in }
    
    var shuffleRepeatChangedHandler: (Bool?, Bool?) -> () = { _, _ in }
    
    // MARK: Application identifier
    
    static let BundleIdentifier = "com.coppertino.Vox"
    
    // MARK: Notification ID
    
    static let TrackChangedNotification = BundleIdentifier + ".trackChanged"
    
}