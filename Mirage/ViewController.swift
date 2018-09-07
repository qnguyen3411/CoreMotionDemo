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
  var baseImageView: UIImageView
  var rings: [ImageRing] = []
  var containingView: UIView
  var colorTheme : [UIColor]
  var numRings:Int {
    return rings.count
  }
  
  init(numRings: Int, toView view: UIView,
       withBaseImage baseImage: UIImageView,
       colorTheme:[UIColor] = [.white] ) {
    self.containingView = view
    self.colorTheme = colorTheme
    self.baseImageView = baseImage
    
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
      expandRateMultiplier: randomExpandRate(from: 1, to: 2),
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
      expandRateMultiplier: randomExpandRate(from: 1, to: 2),
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
        addRingFromEdge(of: containingView, withBaseImage: baseImageView)
        removeRing(atIndex: i)
        
      } else if rings[i].tooBig() {
        print("RING \(i) TOO BIG")
        addRingFromCenter(of: containingView, withBaseImage: baseImageView)
        removeRing(atIndex: i)
      }
    }
  }
  
  func updateTheme(_ theme: [UIColor]) {
    self.colorTheme = theme
  }
  
  func updateBaseImage(_ newImage: UIImageView) {
    self.baseImageView = newImage
  }
  
  
  func randomSize() -> CGSize {
    return CGSize(width: Int.random(in: 20...75), height: Int.random(in: 20...75))
  }
  
  func randomSpinRate() -> Double {
    // randomize spinRate
    let spinRateToGetRandomly:[Double] = [0.06, 0.08, 0.11, 0.14, 0.17]
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
    let colorsToGetRandomly = colorTheme
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
  var spinRate = 0.0
  
  init(baseImageView: UIImageView,
       numImage: Int,
       radius: Double,
       center:CGPoint,
       imageSize: CGSize = CGSize(width: 50, height: 50),
       color: UIColor = .white,
       expandRateMultiplier: Double = 1,
       spinRate: Double = 0.0,
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
    currSpinOffset += spinRate
  }
  
  
  func updateToCMData(_ data: CMDeviceMotion) {
    updateRadius(data.attitude.pitch * 10 * expandRateMultiplier)
    rotateImages(byRadians: data.attitude.pitch + Double.pi, speed: 12.0)
    updateSpin(accordingTo: data.attitude.pitch)
  }
  
  
  func updateSpin(accordingTo pitch: Double) {
    spinRate = spinRate * sin(pitch) * 3 + 0.005
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
  
  @IBOutlet var imageList: [UIImageView]!
  
  @IBAction func themeButtonPressed(_ sender: UIButton) {
    for ringStack in ringStacks {
      ringStack.updateTheme(themeList[themeCycle])
    }
    
    themeCycle += 1
    if themeCycle > themeList.count - 1 {
      themeCycle = 0
    }
    
  }
  
  @IBAction func imgButtonPressed(_ sender: UIButton) {
    for ringStack in ringStacks {
      ringStack.updateBaseImage(imageList[imgCycle])
    }
    
    imgCycle += 1
    if imgCycle > imageList.count - 1 {
      imgCycle = 0
    }
  }
  
  
  var ringStacks:[RingStack] = []
  var themeCycle = 0
  var imgCycle = 0
  
  var motionManager = CMMotionManager()
  let opQueue = OperationQueue()
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    guard let mainView = view else {
      return
    }
    
    ringStacks.append(
      RingStack(numRings: 6, toView: mainView,
        withBaseImage: imageList[0], colorTheme: primaryTheme)
//      RingStack(numRings: 3, toView: mainView,
//        withBaseImage: butterfly, colorTheme: pastelsTheme),
      )
    
    for image in imageList {
      image.isHidden = true
    }
    if motionManager.isDeviceMotionAvailable {
      print("We can detect device motion")
      startReadingMotionData(for: ringStacks)
    }
    else {
      print("We cannot detect device motion")
    }
  }
  
  
  func startReadingMotionData(for ringStacks: [RingStack]) {
    // set read speed
    motionManager.deviceMotionUpdateInterval = Double(1/24)
    // start reading
    motionManager.startDeviceMotionUpdates(to: opQueue) { (data: CMDeviceMotion?, error: Error?) in
      
      guard let mydata = data else {
        return
      }
      // Send to main thread
      DispatchQueue.main.async {
        for ringStack in ringStacks {
          ringStack.checkAndRefreshRing()
          for i in 0..<ringStack.numRings {
            ringStack.rings[i].updateToCMData(mydata)
            ringStack.rings[i].spin()
          }
        }
      }
    
    }
  }
  

  func degrees(_ radians: Double) -> Double {
    return 180/Double.pi * radians
  }
  
}



