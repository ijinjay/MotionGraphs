/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A view controller to display output from the accelerometer.
 */

import UIKit
import CoreMotion
import simd

class AccelerometerViewController: UIViewController, MotionGraphContainer {
    
    // MARK: Properties
    
    @IBOutlet weak var graphView: GraphView!
    @IBOutlet weak var gyroGraphView: GraphView!
    // MARK: MotionGraphContainer properties
    
    var motionManager: CMMotionManager?
    
    @IBOutlet weak var updateIntervalLabel: UILabel!
    
    @IBOutlet weak var updateIntervalSlider: UISlider!
    
    let updateIntervalFormatter = MeasurementFormatter()
    
    @IBOutlet var valueLabels: [UILabel]!
    @IBOutlet var gyroValueLabels: [UILabel]!
    @IBOutlet var timerLable: UILabel!
    @IBOutlet var sensorLable: UILabel!
    @IBOutlet var sensorSwitch: UISwitch!
    @IBOutlet var calibButton: UIButton!
    @IBOutlet var scollTextView: UITextView!
    
    // MARK: UIViewController overrides
    let acc_file = "acc.mat"
    let gyro_file = "gyro.mat"
    var currentCount = 0
    var myTimer: Timer?
    var accOutput: OutputStream?
    var gyrOutput: OutputStream?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateIntervalSlider.isEnabled = false
        sensorSwitch.addTarget(self, action: #selector(switchValueChanged(mySwitch:)), for: UIControlEvents.valueChanged)
        let DocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let accfileURL = DocumentDirURL.appendingPathComponent("acc").appendingPathExtension("txt")
        
        calibButton.addTarget(self, action: #selector(startCalibration), for: UIControlEvents.touchDown)
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: accfileURL.path) {
            calibButton.setTitle("开始标定", for: UIControlState.normal)
        }else{
            calibButton.setTitle("当前数据不可用", for: UIControlState.disabled)
            calibButton.isEnabled = false
        }
        
        scollTextView.text = "操作说明：\n1.静止放置手机，然后打开传感器，手机静止状态下大约50s的数据\n2.移动手机到不同的姿态，静止放置2秒以上\n3.切换姿态30次左右后点击开始标定按钮进行标定\n"
        let calibAccURL = accfileURL.appendingPathExtension("calib")
        print(calibAccURL)
        if fileManager.fileExists(atPath: calibAccURL.path) {
            let gyrfileURL = DocumentDirURL.appendingPathComponent("gyr").appendingPathExtension("txt")
            let calibGyrURL = gyrfileURL.appendingPathExtension("calib")
            do {
                print("here0")
                let textAcc = try String(contentsOf: calibAccURL, encoding: String.Encoding.utf8)
                let textGyr = try String(contentsOf: calibGyrURL, encoding: String.Encoding.utf8)
                print(textAcc)
                scollTextView.text = scollTextView.text + "Acc value:\n"
                scollTextView.text = scollTextView.text + textAcc
                scollTextView.text = scollTextView.text + "Gry Value:\n"
                scollTextView.text = scollTextView.text + textGyr
            }catch{
                print("IO error")
            }
        }
        
    }
    
    func startCalibration(){
        // File Path
        calibButton.isEnabled = false
        sensorSwitch.isEnabled = false
        let DocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let accfileURL = DocumentDirURL.appendingPathComponent("acc").appendingPathExtension("txt")
        let gyrfileURL = DocumentDirURL.appendingPathComponent("gyr").appendingPathExtension("txt")
        
        myTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: {_ in
            self.currentCount += 1
            self.timerLable.text = String(format: "正在标定中,已用时：%d秒", self.currentCount)
        })
        
        DispatchQueue.global(qos: .userInitiated).async {
            CPP_Wrapper.calibrate_cpp_wrapped(accfileURL.path, andGyr: gyrfileURL.path)
            DispatchQueue.main.async {
                let calibAccURL = accfileURL.appendingPathExtension("calib")
                let calibGyrURL = gyrfileURL.appendingPathExtension("calib")
                do {
                    let textAcc = try String(contentsOf: calibAccURL, encoding: String.Encoding.utf8)
                    let textGyr = try String(contentsOf: calibGyrURL, encoding: String.Encoding.utf8)
                    self.scollTextView.text = self.scollTextView.text + "Acc value:\n"
                    self.scollTextView.text = self.scollTextView.text + textAcc
                    self.scollTextView.text = self.scollTextView.text + "Gry Value:\n"
                    self.scollTextView.text = self.scollTextView.text + textGyr
                }catch{
                    print("IO error")
                }
                if self.myTimer != nil {
                    self.myTimer?.invalidate()
                    self.myTimer = nil
                }
                self.timerLable.text = "标定完成"
                self.calibButton.isEnabled = true
                self.sensorSwitch.isEnabled = true
            }
        }
    }
    func switchValueChanged(mySwitch: UISwitch){
        if mySwitch.isOn {
            sensorLable.text = String("传感器开启")
            startUpdates()
        }else{
            sensorLable.text = String("传感器关闭")
            stopUpdates()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopUpdates()
    }
    
    // MARK: Interface Builder actions
    
    @IBAction func intervalSliderChanged(_ sender: UISlider) {
        startUpdates()
    }
    
    // MARK: MotionGraphContainer implementation
    
    func startUpdates() {
        if self.currentCount != 0{
            self.currentCount = 0
        }
        calibButton.isEnabled = false
        // File Path
        let DocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let accfileURL = DocumentDirURL.appendingPathComponent("acc").appendingPathExtension("txt")
        let gyrfileURL = DocumentDirURL.appendingPathComponent("gyr").appendingPathExtension("txt")
        accOutput = OutputStream.init(url: accfileURL, append: false)
        gyrOutput = OutputStream.init(url: gyrfileURL, append: false)
        accOutput?.open()
        gyrOutput?.open()
        
        myTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: {_ in
            self.currentCount += 1
            self.timerLable.text = String(format: "已用时：%d秒", self.currentCount)
        })
        
        guard let motionManager = motionManager, motionManager.isAccelerometerAvailable else { return }
        
        updateIntervalLabel.text = formattedUpdateInterval
        
        motionManager.accelerometerUpdateInterval = TimeInterval(updateIntervalSlider.value)
        motionManager.gyroUpdateInterval = TimeInterval(updateIntervalSlider.value)
        motionManager.showsDeviceMovementDisplay = true
        
        motionManager.startAccelerometerUpdates(to: .main) { accelerometerData, error in
            guard let accelerometerData = accelerometerData else { return }
            
            let acceleration: double3 = [accelerometerData.acceleration.x, accelerometerData.acceleration.y, accelerometerData.acceleration.z]
            self.graphView.add(acceleration)
            self.setValueLabels(xyz: acceleration)
            // Save data to file
            
            let writeString = String(format:"%lf %lf %lf %lf\n", accelerometerData.timestamp, acceleration.x, acceleration.y, acceleration.z)
            //            let data: NSData = writeString.data(using: String.Encoding.utf8)! as NSData
            let data = [UInt8](writeString.utf8)
            self.accOutput?.write(data, maxLength: data.count)
        }
        motionManager.startGyroUpdates(to: .main) { gyroData, error in
            guard let gyroData = gyroData else { return }
            
            let rotationRate: double3 = [gyroData.rotationRate.x, gyroData.rotationRate.y, gyroData.rotationRate.z]
            self.gyroGraphView.add(rotationRate)
            self.setGyroValueLables(rollPitchYaw: rotationRate)
            let writeString = String(format:"%lf %lf %lf %lf\n", gyroData.timestamp, rotationRate.x, rotationRate.y, rotationRate.z)
            
            let data = [UInt8](writeString.utf8)
            self.gyrOutput?.write(data, maxLength: data.count)
            
        }
    }
    
    func stopUpdates() {
        guard let motionManager = motionManager, motionManager.isAccelerometerAvailable else { return }
        
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        if myTimer != nil {
            myTimer?.invalidate()
            myTimer = nil
            currentCount = 0
        }
        if accOutput != nil {
            accOutput?.close()
            accOutput = nil
        }
        if gyrOutput != nil {
            gyrOutput?.close()
            gyrOutput = nil
        }
        
        calibButton.isEnabled = true
        CPP_Wrapper.hello_cpp_wrapped()
        timerLable.text = String("点击开始标定求解参数")
    }
    func setGyroValueLables(rollPitchYaw: double3){
        gyroValueLabels[0].text = String(format: "Roll:  %+6.4f", rollPitchYaw[0])
        gyroValueLabels[1].text = String(format: "Pitch: %+6.4f", rollPitchYaw[1])
        gyroValueLabels[2].text = String(format: "Yaw:   %+6.4f", rollPitchYaw[2])
    }
}
