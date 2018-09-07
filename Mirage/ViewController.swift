//
//  ViewController.swift
//  Mirage
//
//  Created by Archana Panda on 9/6/18.
//  Copyright © 2018 Archana Panda. All rights reserved.
//

import UIKit
import CoreMotion

enum SpinRate: Double {
  case none = 0
  case verySlow =  0.06
  case slow = 0.1
  case normal = 0.15
  case fast = 0.22
  case veryFast = 0.3
}

class RingStack {
  
}

class ImageRing {
  
  var images: [UIImageView] = []
  var numImages: Int {
    return images.count
  }
  var radius: Double
  var center: CGPoint
  
  // The multiplier for how fast the ring expand/contracts
  var expandRateMultiplier: Double
  
  // Current offset of the image's position on the ring
  var currSpinOffset: Double = 0
  
  // The rate at which the images spin around the ring
  var spinRate = SpinRate.none
  
  init(baseImageView: UIImageView,
       numImage: Int,
       radius: Double,
       center:CGPoint,
       expandRateMultiplier: Double = 1,
       spinRate: SpinRate = .none,
       toView view: UIView) {
    
    self.radius = radius
    self.center = center
    self.expandRateMultiplier = expandRateMultiplier
    self.spinRate = spinRate
    
    // Make images
    for i in 0..<numImage {
      let thisImage = UIImageView(image: baseImageView.image)
      let imagePos = self.imagePosition(position: i, outOf: numImage)
      thisImage.frame = CGRect(
        x: imagePos.x, y: imagePos.y, width: 50, height:50)
      
      // Debug backgorund color
      thisImage.backgroundColor = .blue
      
      self.images.append(thisImage)
      view.addSubview(thisImage)
    }
  }
  
  func updateRadius(_ radius: Double) {
    self.radius = radius
    for i in 0..<numImages {
      let imagePos = self.imagePosition(
        position: i, outOf: numImages, offSetInRadians: currSpinOffset)
      
      images[i].frame = CGRect(
        x: imagePos.x, y: imagePos.y, width: 50, height:50)
    } // endfor
  }
  
  func spin() {
    currSpinOffset += spinRate.rawValue
  }
  
  
  func updateToCMData(_ data: CMDeviceMotion) {
    updateRadius(data.attitude.pitch * 500 * expandRateMultiplier)
    rotateImages(byRadians: data.attitude.pitch + Double.pi, speed: 4.0)
  }
  
  
  // Return the image position for image `position` in `totalCount` images
  func imagePosition(position:Int, outOf totalCount: Int, offSetInRadians: Double = 0) -> CGPoint {
    
    return CGPoint(
      x: radius * cos(Double(position)/Double(totalCount) * 2 * Double.pi + offSetInRadians) + Double(center.x),
      y: radius * sin(Double(position)/Double(totalCount) * 2 * Double.pi + offSetInRadians) + Double(center.y)
    )
  }
  
  // Rotate each images in ring by `rotateRad` * `speed` amount
  func rotateImages(byRadians rotateRad: Double, speed: Double = 1) {
    for image in images {
      image.transform = CGAffineTransform(
        rotationAngle: CGFloat(rotateRad * speed)
      )
    }
  }
  
  
}


class ViewController: UIViewController {
  
  @IBOutlet weak var testImage: UIImageView!
  
  var motionManager = CMMotionManager()
  let opQueue = OperationQueue()
  
  
  override func viewDidLoad() {
      super.viewDidLoad()
    guard let mainView = view else {
      return
    }
    
    let rings = [
      ImageRing(
        baseImageView: testImage,
        numImage: 6,
        radius: 75,
        center: mainView.center,
        spinRate: .slow,
        toView: view
      ),
    
      ImageRing(
        baseImageView: testImage,
        numImage: 8,
        radius: 95,
        center: mainView.center,
        expandRateMultiplier: 2,
        spinRate: .normal,
        toView: view
      )
    ]
      testImage.isHidden = true
      if motionManager.isDeviceMotionAvailable {
        print("We can detect device motion")
        startReadingMotionData(for: rings)
      }
      else {
        print("We cannot detect device motion")
      }
  }
  
  
  func startReadingMotionData(for rings: [ImageRing]) {
    // set read speed
    motionManager.deviceMotionUpdateInterval = 0.1
    // start reading
    motionManager.startDeviceMotionUpdates(to: opQueue) { (data: CMDeviceMotion?, error: Error?) in
      
      guard let mydata = data else {
        return
      }
      // Send to main thread
      DispatchQueue.main.async {
        for i in 0..<rings.count {
          rings[i].updateToCMData(mydata)
          rings[i].spin()
        }
      }
    
    }
  }
  

  func degrees(_ radians: Double) -> Double {
    return 180/Double.pi * radians
  }
  
}



