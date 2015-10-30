//
//  BluetoothAccess.swift
//  BluetoothExampleTV
//
//  Created by Noritaka Kamiya on 2015/10/30.
//  Copyright © 2015年 Noritaka Kamiya. All rights reserved.
//

import Foundation
import CoreBluetooth

typealias HeartRateRawData = NSData

enum HeartRateRawDataError: ErrorType {
    case Unknown
}

extension HeartRateRawData {
    
    func heartRateValue() throws -> Int {
        
        var buffer = [UInt8](count: self.length, repeatedValue: 0x00)
        self.getBytes(&buffer, length: buffer.count)
        
        var bpm:UInt16
        if (buffer.count >= 2){
            if (buffer[0] & 0x01 == 0){
                bpm = UInt16(buffer[1]);
            }else {
                bpm = UInt16(buffer[1]) << 8
                bpm =  bpm | UInt16(buffer[2])
            }
        } else {
            throw HeartRateRawDataError.Unknown
        }
        return Int(bpm)
        
    }
}

struct HeartRateService {
    static let UUID = CBUUID(string: "180D")
}

struct HeartRateMesurement {
    static var UUID : CBUUID = CBUUID(string: "2A37")
}

struct BodySensorLocation  {
    static var UUID : CBUUID = CBUUID(string: "2A38")
}

struct HeartRateControlUnit {
    static var UUID: CBUUID = CBUUID(string: "2A39")
}


typealias HeartRateUpdateHandler = (Int) -> (Void)

class BluetoothManager :NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var centralManager:CBCentralManager!
    var connectingPeripheral:CBPeripheral?
    var heartRateUpdateHandler: HeartRateUpdateHandler?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: dispatch_get_main_queue())
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch central.state {
        case .PoweredOn:
            startScan()
        default:
            break
        }
    }
    
    func startScan() -> Void {
        centralManager.scanForPeripheralsWithServices([HeartRateService.UUID], options: nil)
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        connectingPeripheral = peripheral
        centralManager.connectPeripheral(peripheral, options: nil)
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([HeartRateService.UUID])
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        
        peripheral.services?.forEach{ service in
            if (service.UUID == HeartRateService.UUID) {
                peripheral.discoverCharacteristics([HeartRateMesurement.UUID, BodySensorLocation.UUID, HeartRateControlUnit.UUID], forService: service)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        
        service.characteristics?.forEach { characteristic in
            switch characteristic.UUID {
            case HeartRateMesurement.UUID:
                peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                
            case BodySensorLocation.UUID:
                peripheral.readValueForCharacteristic(characteristic)
                
            default:
                break;
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        
        switch characteristic.UUID {
        case HeartRateMesurement.UUID:
            guard let value = characteristic.value else {
                break
            }
            guard let bpm = try? value.heartRateValue() else {
                break
            }
            self.heartRateUpdateHandler?(bpm)
            
        default:
            break;
        }
    }
}
