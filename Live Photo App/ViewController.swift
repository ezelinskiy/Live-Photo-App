//
//  ViewController.swift
//  Live Photo App
//
//  Created by Evgeniy Zelinskiy on 21.02.2024.
//

import UIKit
import SceneKit
import SpriteKit
import ARKit
import AVFoundation

class ViewController: UIViewController, ARSCNViewDelegate, SCNSceneRendererDelegate {

    @IBOutlet var sceneView: ARSCNView!
//    var spriteKitScene = SKScene()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        sceneView.delegate = self
        sceneView.showsStatistics = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARImageTrackingConfiguration()
        if let trackingImages = ARReferenceImage.referenceImages(inGroupNamed: "LivePhotoGroupImages", bundle: Bundle.main) {
            configuration.trackingImages = trackingImages
            configuration.maximumNumberOfTrackedImages = 2
        }
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        if let imageAnchor = anchor as? ARImageAnchor {
            let spriteKitScene = SKScene(size: CGSize(width: sceneView.frame.width, height: sceneView.frame.height))
            spriteKitScene.scaleMode = .aspectFit
            
            // Create a video player, which will be responsible for the playback of the video material
            let videoUrl = Bundle.main.url(forResource: imageAnchor.name == "live-photo-1" ? "live-video-1" : "live-video-2", withExtension: "mov")!
            let videoPlayer = AVPlayer(url: videoUrl)
            
            // To make the video loop
            videoPlayer.actionAtItemEnd = .none
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(ViewController.playerItemDidReachEnd),
                name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                object: videoPlayer.currentItem)
            
            // Create the SpriteKit video node, containing the video player
            let videoSpriteKitNode = SKVideoNode(avPlayer: videoPlayer)
            videoSpriteKitNode.position = CGPoint(x: spriteKitScene.size.width / 2.0, y: spriteKitScene.size.height / 2.0)
            videoSpriteKitNode.size = spriteKitScene.size
            videoSpriteKitNode.yScale = -1.0
            videoSpriteKitNode.play()
            spriteKitScene.addChild(videoSpriteKitNode)
            
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
            plane.firstMaterial?.diffuse.contents = spriteKitScene
            let planeNode = SCNNode(geometry: plane)
            planeNode.eulerAngles.x = -.pi / 2
            node.addChildNode(planeNode)
        }
        return node
    }
    
    @objc func playerItemDidReachEnd(notification: NSNotification) {
        if let playerItem: AVPlayerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: CMTime.zero)
        }
    }
}
