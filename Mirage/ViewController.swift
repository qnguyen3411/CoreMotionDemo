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
  case fast = 0.17
  case veryFast = 0.22
}


class RingStack {
  var rings: [ImageRing] = []
  var containingView: UIView
  var numRings:Int {
    return rings.count
  }
  
  init(numRings: Int, toView view: UIView, withBaseImage baseImage: UIImageView ) {
    self.containingView = view
    
    for i in 0..<numRings {
      addRingFromCenter(of: containingView, withBaseImage: baseImage)
      if let thisRing = rings.last {
        thisRing.updateRadius(Double(i) * 30)
      }
    }
  }
  
  func addRingFromEdge(of view: UIView, withBaseImage imageView: UIImageView) {
    let newRing = ImageRing(
      baseImageView: imageView,
      numImage: Int.random(in: 5...9),
      radius: 400,
      center: view.center,
      imageSize: randomSize(),
      color: randomColor(),
      expandRateMultiplier: randomExpandRate(from: 1, to: 3),
      spinRate: randomSpinRate(),
      toView: view
    )
    
    rings.append(newRing)
  }
  
  func addRingFromCenter(of view: UIView, withBaseImage imageView: UIImageView) {
    
    let newRing = ImageRing(
      baseImageView: imageView,
      numImage: Int.random(in: 5...9),
      radius: 20,
      center: view.center,
      imageSize: randomSize(),
      color: randomColor(),
      expandRateMultiplier: randomExpandRate(from: 1, to: 5),
      spinRate: randomSpinRate(),
      toView: view
    )
    
    rings.append(newRing)
    
  }
  
  func removeRing(atIndex index: Int) {
    rings.remove(at: index)
  }
  
  // Check each ring if they have gone off the edge or collapsed at the center
  // Returns list of indexes
  func checkAndRefreshRing() {
    for i in 0..<numRings {
      
      if rings[i].tooSmall() {
        print("RING \(i) TOO SMALL")
        addRingFromEdge(of: containingView, withBaseImage: rings[i].images[0])
        removeRing(atIndex: i)
        
      } else if rings[i].tooBig() {
        print("RING \(i) TOO BIG")
        addRingFromCenter(of: containingView, withBaseImage: rings[i].images[0])
        removeRing(atIndex: i)
      }
    }
  }
  
  func randomSize() -> CGSize {
    return CGSize(width: Int.random(in: 20...75), height: Int.random(in: 20...75))
  }
  
  func randomSpinRate() -> SpinRate {
    // randomize spinRate
    let spinRateToGetRandomly:[SpinRate] = [.verySlow, .slow, .normal, .fast, .veryFast]
    let randIndex = Int.random(in: 0..<spinRateToGetRandomly.count)
    return spinRateToGetRandomly[randIndex]
  }
  
  func randomExpandRate(from lowBound: Double, to upBound: Double) -> Double{
    // randomize expandRate
    // get a random Int from 0 to 100
    let randInt = Int.random(in: 0...100)
    // cast as double, divide by 100 multiply by total range (upbound - lowbound)
    let randDouble = Double(randInt) / 100.0 * (upBound - lowBound)
    // add to lowbound
    return lowBound + randDouble
    
  }
  
  func randomColor() -> UIColor {
    let colorsToGetRandomly = [
      UIColor(red: 247.0/255.0, green: 244.0/255.0, blue: 234.0/255.0, alpha: 1.0),
      UIColor(red: 222.0/255.0, green: 217.0/255.0, blue: 226.0/255.0, alpha: 1.0),
      UIColor(red: 192.0/255.0, green: 185.0/255.0, blue: 221.0/255.0, alpha: 1.0),
      UIColor(red: 128.0/255.0, green: 161.0/255.0, blue: 212.0/255.0, alpha: 1.0),
      UIColor(red: 117.0/255.0, green: 201.0/255.0, blue: 200.0/255.0, alpha: 1.0)
      
    ]
    let randIndex = Int.random(in: 0..<colorsToGetRandomly.count)
    return colorsToGetRandomly[randIndex]
  }
  
  
}

class ImageRing {
  
  var images: [UIImageView] = []
  var numImages: Int {
    return images.count
  }
  var radius: Double
  var center: CGPoint
  var imageSize: CGSize
  var color: UIColor
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
       imageSize: CGSize = CGSize(width: 50, height: 50),
       color: UIColor = .white,
       expandRateMultiplier: Double = 1,
       spinRate: SpinRate = .none,
       toView view: UIView) {
    
    self.radius = radius
    self.center = center
    self.expandRateMultiplier = expandRateMultiplier
    self.spinRate = spinRate
    self.imageSize = imageSize
    self.color = color
    
    // Make images
    for i in 0..<numImage {
      let thisImage = UIImageView(image: baseImageView.image)
      let imagePos = self.imagePosition(position: i, outOf: numImage)
      thisImage.frame = CGRect(
        origin:imagePos, size: imageSize)
      
      // Debug backgorund color
      thisImage.backgroundColor = color
      
      self.images.append(thisImage)
      view.addSubview(thisImage)
    }
  }
  
  func updateRadius(_ radIncrement: Double) {
    self.radius += radIncrement
    for i in 0..<numImages {
      let imagePos = self.imagePosition(
        position: i, outOf: numImages, offSetInRadians: currSpinOffset)
      
      images[i].frame = CGRect(
        origin:imagePos, size: imageSize)
    } // endfor
  }
  
  func spin() {
    currSpinOffset += spinRate.rawValue
  }
  
  
  func updateToCMData(_ data: CMDeviceMotion) {
    updateRadius(data.attitude.pitch * 10 * expandRateMultiplier)
    rotateImages(byRadians: data.attitude.pitch + Double.pi, speed: 4.0)
  }
  
  
  func updateSpin(accordingTo pitch: Double) {
    
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
  
  func tooSmall() -> Bool {
    return radius < 10
  }
  
  func tooBig() -> Bool {
    return radius > 500
  }
  
  deinit {
    for image in self.images {
      image.removeFromSuperview()
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
    

      let ringStack = RingStack(
        numRings: 6, toView: mainView, withBaseImage: testImage)
    
      testImage.isHidden = true
      if motionManager.isDeviceMotionAvailable {
        print("We can detect device motion")
        startReadingMotionData(for: ringStack)
      }
      else {
        print("We cannot detect device motion")
      }
  }
  
  
  func startReadingMotionData(for ringStack: RingStack) {
    // set read speed
    motionManager.deviceMotionUpdateInterval = 0.1
    // start reading
    motionManager.startDeviceMotionUpdates(to: opQueue) { (data: CMDeviceMotion?, error: Error?) in
      
      guard let mydata = data else {
        return
      }
      // Send to main thread
      DispatchQueue.main.async {
        ringStack.checkAndRefreshRing()
        for i in 0..<ringStack.numRings {
          ringStack.rings[i].updateToCMData(mydata)
          ringStack.rings[i].spin()
        }
      }
    
    }
  }
  

  func degrees(_ radians: Double) -> Double {
    return 180/Double.pi * radians
  }
  
}



