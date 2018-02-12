//
//  BluetoothManager.swift
//  Facesynth
//
//  Created by Daniel Kuntz on 2/9/18.
//  Copyright © 2018 Daniel Kuntz. All rights reserved.
//

import Foundation
import CoreBluetooth

var txCharacteristic : CBCharacteristic?
var rxCharacteristic : CBCharacteristic?
var gloveRxCharacteristic : CBCharacteristic?
var werkstattBluefruit : CBPeripheral?
var gloveBluefruit : CBPeripheral?
var characteristicASCIIValue = NSString()

class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    //Data
    var centralManager : CBCentralManager!
    var RSSIs = [NSNumber]()
    var data = NSMutableData()
    var writeData: String = ""
    var peripherals: [CBPeripheral] = []
    var characteristicValue = [CBUUID: NSData]()
    var timer = Timer()
    var characteristics = [String : CBCharacteristic]()
    var connected: Bool = false
    var sending: Bool = false
    var yInt: Int = 128
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    /*Okay, now that we have our CBCentalManager up and running, it's time to start searching for devices. You can do this by calling the "scanForPeripherals" method.*/
    
    func startScan() {
        peripherals = []
        print("Now Scanning...")
        self.timer.invalidate()
        centralManager?.scanForPeripherals(withServices: [BLEService_UUID] , options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
        Timer.scheduledTimer(timeInterval: 17, target: self, selector: #selector(self.cancelScan), userInfo: nil, repeats: false)
    }
    
    /*We also need to stop scanning at some point so we'll also create a function that calls "stopScan"*/
    @objc func cancelScan() {
        self.centralManager?.stopScan()
        print("Scan Stopped")
        print("Number of Peripherals Found: \(peripherals.count)")
    }
    
    func writeValue(data: String) {
        let valueString = (data as NSString).data(using: String.Encoding.utf8.rawValue)
        //change the "data" to valueString
        if let blePeripheral = werkstattBluefruit, connected {
            if let txCharacteristic = txCharacteristic {
                blePeripheral.writeValue(valueString!, for: txCharacteristic, type: CBCharacteristicWriteType.withoutResponse)
                sending = true
            }
        }
    }
    
    //-Terminate all Peripheral Connection
    /*
     Call this when things either go wrong, or you're done with the connection.
     This cancels any subscriptions if there are any, or straight disconnects if not.
     (didUpdateNotificationStateForCharacteristic will cancel the connection if a subscription is involved)
     */
    func disconnectFromDevice () {
        if let werkstatt = werkstattBluefruit {
            // We have a connection to the device but we are not subscribed to the Transfer Characteristic for some reason.
            // Therefore, we will just disconnect from the peripheral
            centralManager?.cancelPeripheralConnection(werkstatt)
        }
        
        if let glove = gloveBluefruit {
            centralManager?.cancelPeripheralConnection(glove)
        }
    }
    
    func restoreCentralManager() {
        //Restores Central Manager delegate if something went wrong
        centralManager?.delegate = self
    }
    
    /*
     Called when the central manager discovers a peripheral while scanning. Also, once peripheral is connected, cancel scanning.
     */
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if advertisementData["kCBAdvDataLocalName"] as? String == "Adafruit Bluefruit LE" {
            werkstattBluefruit = peripheral
            self.peripherals.append(peripheral)
            self.RSSIs.append(RSSI)
            peripheral.delegate = self
            if werkstattBluefruit == nil {
                print("Found new pheripheral devices with services")
                print("Peripheral name: \(String(describing: peripheral.name))")
                print("**********************************")
                print ("Advertisement Data : \(advertisementData)")
            }
            
            connectToDevice(werkstattBluefruit!)
        }
        
        if advertisementData["kCBAdvDataLocalName"] as? String == "Bluefruit Glove" {
            gloveBluefruit = peripheral
            self.peripherals.append(peripheral)
            self.RSSIs.append(RSSI)
            peripheral.delegate = self
            if gloveBluefruit == nil {
                print("Found new pheripheral devices with services")
                print("Peripheral name: \(String(describing: peripheral.name))")
                print("**********************************")
                print ("Advertisement Data : \(advertisementData)")
            }
            
            connectToDevice(gloveBluefruit!)
        }
    }
    
    //Peripheral Connections: Connecting, Connected, Disconnected
    
    //-Connection
    func connectToDevice(_ device: CBPeripheral) {
        centralManager?.connect(device, options: nil)
    }
    
    /*
     Invoked when a connection is successfully created with a peripheral.
     This method is invoked when a call to connect(_:options:) is successful. You typically implement this method to set the peripheral’s delegate and to discover its services.
     */
    //-Connected
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("*****************************")
        print("Connection complete")
        print("Peripheral info: \(String(describing: peripheral))")
        connected = true
        
        //Erase data that we might have
        data.length = 0
        
        //Discovery callback
        peripheral.delegate = self
        //Only look for services that matches transmit uuid
        peripheral.discoverServices(nil)
    }
    
    /*
     Invoked when the central manager fails to create a connection with a peripheral.
     */
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if error != nil {
            print("Failed to connect to peripheral")
            return
        }
    }
    
    func disconnectAllConnection() {
        if let werkstatt = werkstattBluefruit {
            centralManager.cancelPeripheralConnection(werkstatt)
        }
        
        if let glove = gloveBluefruit {
            centralManager.cancelPeripheralConnection(glove)
        }
    }
    
    /*
     Invoked when you discover the peripheral’s available services.
     This method is invoked when your app calls the discoverServices(_:) method. If the services of the peripheral are successfully discovered, you can access them through the peripheral’s services property. If successful, the error parameter is nil. If unsuccessful, the error parameter returns the cause of the failure.
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("*******************************************************")
        
        if ((error) != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else {
            return
        }
        //We need to discover the all characteristic
        for service in services {
            if service.uuid.uuidString == "180D" || peripheral == werkstattBluefruit {
                peripheral.discoverCharacteristics(nil, for: service)
            }
            
            // bleService = service
        }
        print("Discovered Services: \(services)")
    }
    
    /*
     Invoked when you discover the characteristics of a specified service.
     This method is invoked when your app calls the discoverCharacteristics(_:for:) method. If the characteristics of the specified service are successfully discovered, you can access them through the service's characteristics property. If successful, the error parameter is nil. If unsuccessful, the error parameter returns the cause of the failure.
     */
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        print("*******************************************************")
        
        if ((error) != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else {
            return
        }
        
        print("Found \(characteristics.count) characteristics!")
        
        for characteristic in characteristics {
            //looks for the right characteristic
            
            if characteristic.uuid.uuidString == "2A37" {
                gloveRxCharacteristic = characteristic
                
                //Once found, subscribe to the this particular characteristic...
                peripheral.setNotifyValue(true, for: gloveRxCharacteristic!)
                // We can return after calling CBPeripheral.setNotifyValue because CBPeripheralDelegate's
                // didUpdateNotificationStateForCharacteristic method will be called automatically
                peripheral.readValue(for: characteristic)
                //                readAccelerometerCharacteritic()
                print("Rx Characteristic: \(characteristic.uuid)")
            }
            
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Rx) {
                rxCharacteristic = characteristic
                
                //Once found, subscribe to the this particular characteristic...
                peripheral.setNotifyValue(true, for: rxCharacteristic!)
                // We can return after calling CBPeripheral.setNotifyValue because CBPeripheralDelegate's
                // didUpdateNotificationStateForCharacteristic method will be called automatically
                peripheral.readValue(for: characteristic)
                //                readAccelerometerCharacteritic()
                print("Rx Characteristic: \(characteristic.uuid)")
            }
            
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Tx){
                txCharacteristic = characteristic
                print("Tx Characteristic: \(characteristic.uuid)")
            }
            
            peripheral.discoverDescriptors(for: characteristic)
        }
    }
    
    // Getting Values From Characteristic
    
    /*After you've found a characteristic of a service that you are interested in, you can read the characteristic's value by calling the peripheral "readValueForCharacteristic" method within the "didDiscoverCharacteristicsFor service" delegate.
     */
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic == gloveRxCharacteristic {
            if let ASCIIstring = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue) {
                guard let int = Int(ASCIIstring as String, radix: 16) else { return }
                characteristicASCIIValue = ASCIIstring
                yInt = int
                print("Value Recieved: \(int)")
                NotificationCenter.default.post(name:NSNotification.Name(rawValue: "y_received"), object: nil)
            }
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        print("*******************************************************")
        
        if error != nil {
            print("\(error.debugDescription)")
            return
        }
        if ((characteristic.descriptors) != nil) {
            
            for x in characteristic.descriptors!{
                let descript = x as CBDescriptor!
                print("function name: DidDiscoverDescriptorForChar \(String(describing: descript?.description))")
                print("Rx Value \(String(describing: rxCharacteristic?.value))")
                print("Tx Value \(String(describing: txCharacteristic?.value))")
            }
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("*******************************************************")
        
        if (error != nil) {
            print("Error changing notification state:\(String(describing: error?.localizedDescription))")
            
        } else {
            print("Characteristic's value subscribed")
        }
        
        if (characteristic.isNotifying) {
            print ("Subscribed. Notification has begun for: \(characteristic.uuid)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected")
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("Error discovering services: error")
            return
        }
        print("Message sent")
        sending = false
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        guard error == nil else {
            print("Error discovering services: error")
            return
        }
        print("Succeeded!")
    }
    
    /*
     Invoked when the central manager’s state is updated.
     This is where we kick off the scan if Bluetooth is turned on.
     */
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn {
            // We will just handle it the easy way here: if Bluetooth is on, proceed...start scan!
            print("Bluetooth Enabled")
            startScan()
            
        } else {
            //If Bluetooth is off, display a UI alert message saying "Bluetooth is not enable" and "Make sure that your bluetooth is turned on"
            print("Bluetooth Disabled- Make sure your Bluetooth is turned on")
        }
    }
}
