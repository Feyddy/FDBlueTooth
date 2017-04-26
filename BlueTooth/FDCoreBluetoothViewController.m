//
//  FDCoreBluetoothViewController.m
//  BlueTooth
//
//  Created by t3 on 2017/4/26.
//  Copyright © 2017年 feyddy. All rights reserved.
//

/**
 * CoreBluetooth设计同样也是类似于客户端-服务器端的设计，作为服务器端的设备称为外围设备（Peripheral），作为客户端的设备叫做中央设备（Central），CoreBlueTooth整个框架就是基于这两个概念来设计的。
 
    完全基于BLE4.0标准并且支持非iOS设备。当前BLE应用相当广泛，不再仅仅是两个设备之间的数据传输，它还有很多其他应用市场，例如室内定位、无线支付、智能家居等等
 
     外围设备和中央设备在CoreBluetooth中使用CBPeripheralManager和CBCentralManager表示。
     
     CBPeripheralManager：外围设备通常用于发布服务、生成数据、保存数据。外围设备发布并广播服务，告诉周围的中央设备它的可用服务和特征。
     
     CBCentralManager：中央设备使用外围设备的数据。中央设备扫描到外围设备后会就会试图建立连接，一旦连接成功就可以使用这些服务和特征。
 
    一台iOS设备（注意iPhone4以下设备不支持BLE，另外iOS7.0、8.0模拟器也无法模拟BLE）既可以作为外围设备又可以作为中央设备，但是不能同时即是外围设备又是中央设备，同时注意建立连接的过程不需要用户手动选择允许，这一点和前面两个框架是不同的，这主要是因为BLE应用场景不再局限于两台设备之间资源共享了。
 
 A.外围设备
 
 创建一个外围设备通常分为以下几个步骤：
 1. 创建外围设备CBPeripheralManager对象并指定代理。
 2. 创建特征CBCharacteristic、服务CBSerivce并添加到外围设备
 3. 外围设备开始广播服务（startAdvertisting:）。
 4. 和中央设备CBCentral进行交互。
 
 B.中央设备
 
 中央设备的创建一般可以分为如下几个步骤：
 
 创建中央设备管理对象CBCentralManager并指定代理。 扫描外围设备，一般发现可用外围设备则连接并保存外围设备。 查找外围设备服务和特征，查找到可用特征则读取特征数据。
 
 
 注意：中心设备和外围设备的代码不一样，下面主要显示 的是外围设备，中心设备的代码被注释掉。
 *
 */

#import "FDCoreBluetoothViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import <AdSupport/AdSupport.h>
#define KPeripheralName @"Feyddy's Device"
//#define KServiceUUID [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString]
#define kServiceUUID @"C4FB2349-72FE-4CA2-94D6-1F3CB16331EE" //服务的UUID
#define kCharacteristicUUID @"6A3E4B28-522D-4B3B-82A9-D5E2004534FC" //特征的UUID

@interface FDCoreBluetoothViewController ()<CBPeripheralManagerDelegate,CBCentralManagerDelegate>

// 外围设备
@property (strong,nonatomic) CBPeripheralManager *peripheralManager;//外围设备管理器
@property (strong,nonatomic) NSMutableArray *centralM;//订阅此外围设备特征的中心设备
@property (strong,nonatomic) CBMutableCharacteristic *characteristicM;//特征

// 中心设备
@property (strong,nonatomic) CBCentralManager *centralManager;//中心设备管理器
@property (strong,nonatomic) NSMutableArray *peripherals;//连接的外围设备

@property (weak, nonatomic) IBOutlet UITextView *detailTextView;
@end

@implementation FDCoreBluetoothViewController


#pragma mark -属性
// 外围设备代码
-(NSMutableArray *)centralM{
    if (!_centralM) {
        _centralM=[NSMutableArray array];
    }
    return _centralM;
}

// 中心设备代码
-(NSMutableArray *)peripherals{
    if(!_peripherals){
        _peripherals=[NSMutableArray array];
    }
    return _peripherals;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
}

// 创建外围设备或者中心设备管理器
- (IBAction)startMethod:(UIButton *)sender {
    // 外围设备创建
    _peripheralManager=[[CBPeripheralManager alloc]initWithDelegate:self queue:nil];
    
//    //创建中心设备管理器并设置当前控制器视图为代理
//    _centralManager=[[CBCentralManager alloc]initWithDelegate:self queue:nil];
}

// 更新数据。如果是中心设备的话可以去掉
- (IBAction)UpdateMethod:(UIButton *)sender {
    [self updateCharacteristicValue];
}


#pragma mark - CBPeripheralManager代理方法
//外围设备状态发生变化后调用
-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral{
    switch (peripheral.state) {
        case CBPeripheralManagerStatePoweredOn:
            NSLog(@"BLE已打开.");
            [self writeToLog:@"BLE已打开."];
            //添加服务
            [self setupService];
            break;
            
        default:
            NSLog(@"此设备不支持BLE或未打开蓝牙功能，无法作为外围设备.");
            [self writeToLog:@"此设备不支持BLE或未打开蓝牙功能，无法作为外围设备."];
            break;
    }
}
//外围设备添加服务后调用
-(void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error{
    if (error) {
        NSLog(@"向外围设备添加服务失败，错误详情：%@",error.localizedDescription);
        [self writeToLog:[NSString stringWithFormat:@"向外围设备添加服务失败，错误详情：%@",error.localizedDescription]];
        return;
    }
    
    //添加服务后开始广播
    NSDictionary *dic=@{CBAdvertisementDataLocalNameKey:KPeripheralName};//广播设置
    [self.peripheralManager startAdvertising:dic];//开始广播
    NSLog(@"向外围设备添加了服务并开始广播...");
    [self writeToLog:@"向外围设备添加了服务并开始广播..."];
}
-(void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error{
    if (error) {
        NSLog(@"启动广播过程中发生错误，错误信息：%@",error.localizedDescription);
        [self writeToLog:[NSString stringWithFormat:@"启动广播过程中发生错误，错误信息：%@",error.localizedDescription]];
        return;
    }
    NSLog(@"启动广播...");
    [self writeToLog:@"启动广播..."];
}
//订阅特征
-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic{
    NSLog(@"中心设备：%@ 已订阅特征：%@.",central,characteristic);
    [self writeToLog:[NSString stringWithFormat:@"中心设备：%@ 已订阅特征：%@.",central.identifier.UUIDString,characteristic.UUID]];
    //发现中心设备并存储
    if (![self.centralM containsObject:central]) {
        [self.centralM addObject:central];
    }
    /*中心设备订阅成功后外围设备可以更新特征值发送到中心设备,一旦更新特征值将会触发中心设备的代理方法：
     -(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
     */
    
    //    [self updateCharacteristicValue];
}
//取消订阅特征
-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic{
    NSLog(@"didUnsubscribeFromCharacteristic");
}
-(void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(CBATTRequest *)request{
    NSLog(@"didReceiveWriteRequests");
}
-(void)peripheralManager:(CBPeripheralManager *)peripheral willRestoreState:(NSDictionary *)dict{
    NSLog(@"willRestoreState");
}



#pragma mark - 私有方法
//创建特征、服务并添加服务到外围设备
-(void)setupService{
    /*1.创建特征*/
    //创建特征的UUID对象
    CBUUID *characteristicUUID=[CBUUID UUIDWithString:kCharacteristicUUID];
    //特征值
    //    NSString *valueStr=kPeripheralName;
    //    NSData *value=[valueStr dataUsingEncoding:NSUTF8StringEncoding];
    //创建特征
    /** 参数
     * uuid:特征标识
     * properties:特征的属性，例如：可通知、可写、可读等
     * value:特征值
     * permissions:特征的权限
     */
    CBMutableCharacteristic *characteristicM=[[CBMutableCharacteristic alloc]initWithType:characteristicUUID properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable];
    self.characteristicM=characteristicM;
    //    CBMutableCharacteristic *characteristicM=[[CBMutableCharacteristic alloc]initWithType:characteristicUUID properties:CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable];
    //    characteristicM.value=value;
    
    /*创建服务并且设置特征*/
    //创建服务UUID对象
    CBUUID *serviceUUID=[CBUUID UUIDWithString:kServiceUUID];
    //创建服务
    CBMutableService *serviceM=[[CBMutableService alloc]initWithType:serviceUUID primary:YES];
    //设置服务的特征
    [serviceM setCharacteristics:@[characteristicM]];
    
    
    /*将服务添加到外围设备*/
    [self.peripheralManager addService:serviceM];
}
//更新特征值
-(void)updateCharacteristicValue{
    //特征值
    NSString *valueStr=[NSString stringWithFormat:@"%@ --%@",KPeripheralName,[NSDate   date]];
    NSData *value=[valueStr dataUsingEncoding:NSUTF8StringEncoding];
    //更新特征值
    [self.peripheralManager updateValue:value forCharacteristic:self.characteristicM onSubscribedCentrals:nil];
    [self writeToLog:[NSString stringWithFormat:@"更新特征值：%@",valueStr]];
}


/**
 *  记录日志
 *
 *  @param info 日志信息
 */
-(void)writeToLog:(NSString *)info{
    self.detailTextView.text=[NSString stringWithFormat:@"%@\r\n%@",self.detailTextView.text,info];
}








/**
 * 中心设备的时候管理方法,如果是创建外围的话就不用
 */

#pragma mark - CBCentralManager代理方法
//中心服务器状态更新后
-(void)centralManagerDidUpdateState:(CBCentralManager *)central{
    switch (central.state) {
        case CBPeripheralManagerStatePoweredOn:
            NSLog(@"BLE已打开.");
            [self writeToLog:@"BLE已打开."];
            //扫描外围设备
            //            [central scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:kServiceUUID]] options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
            [central scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
            break;
            
        default:
            NSLog(@"此设备不支持BLE或未打开蓝牙功能，无法作为外围设备.");
            [self writeToLog:@"此设备不支持BLE或未打开蓝牙功能，无法作为外围设备."];
            break;
    }
}
/**
 *  发现外围设备
 *
 *  @param central           中心设备
 *  @param peripheral        外围设备
 *  @param advertisementData 特征数据
 *  @param RSSI              信号质量（信号强度）
 */
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    NSLog(@"发现外围设备...");
    [self writeToLog:@"发现外围设备..."];
    //停止扫描
    [self.centralManager stopScan];
    //连接外围设备
    if (peripheral) {
        //添加保存外围设备，注意如果这里不保存外围设备（或者说peripheral没有一个强引用，无法到达连接成功（或失败）的代理方法，因为在此方法调用完就会被销毁
        if(![self.peripherals containsObject:peripheral]){
            [self.peripherals addObject:peripheral];
        }
        NSLog(@"开始连接外围设备...");
        [self writeToLog:@"开始连接外围设备..."];
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
    
}
//连接到外围设备
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    NSLog(@"连接外围设备成功!");
    [self writeToLog:@"连接外围设备成功!"];
    //设置外围设备的代理为当前视图控制器
    peripheral.delegate=self;
    //外围设备开始寻找服务
    [peripheral discoverServices:@[[CBUUID UUIDWithString:kServiceUUID]]];
}
//连接外围设备失败
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"连接外围设备失败!");
    [self writeToLog:@"连接外围设备失败!"];
}

#pragma mark - CBPeripheral 代理方法
//外围设备寻找到服务后
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    NSLog(@"已发现可用服务...");
    [self writeToLog:@"已发现可用服务..."];
    if(error){
        NSLog(@"外围设备寻找服务过程中发生错误，错误信息：%@",error.localizedDescription);
        [self writeToLog:[NSString stringWithFormat:@"外围设备寻找服务过程中发生错误，错误信息：%@",error.localizedDescription]];
    }
    //遍历查找到的服务
    CBUUID *serviceUUID=[CBUUID UUIDWithString:kServiceUUID];
    CBUUID *characteristicUUID=[CBUUID UUIDWithString:kCharacteristicUUID];
    for (CBService *service in peripheral.services) {
        if([service.UUID isEqual:serviceUUID]){
            //外围设备查找指定服务中的特征
            [peripheral discoverCharacteristics:@[characteristicUUID] forService:service];
        }
    }
}
//外围设备寻找到特征后
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    NSLog(@"已发现可用特征...");
    [self writeToLog:@"已发现可用特征..."];
    if (error) {
        NSLog(@"外围设备寻找特征过程中发生错误，错误信息：%@",error.localizedDescription);
        [self writeToLog:[NSString stringWithFormat:@"外围设备寻找特征过程中发生错误，错误信息：%@",error.localizedDescription]];
    }
    //遍历服务中的特征
    CBUUID *serviceUUID=[CBUUID UUIDWithString:kServiceUUID];
    CBUUID *characteristicUUID=[CBUUID UUIDWithString:kCharacteristicUUID];
    if ([service.UUID isEqual:serviceUUID]) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ([characteristic.UUID isEqual:characteristicUUID]) {
                //情景一：通知
                /*找到特征后设置外围设备为已通知状态（订阅特征）：
                 *1.调用此方法会触发代理方法：-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
                 *2.调用此方法会触发外围设备的订阅代理方法
                 */
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                //情景二：读取
                //                [peripheral readValueForCharacteristic:characteristic];
                //                    if(characteristic.value){
                //                    NSString *value=[[NSString alloc]initWithData:characteristic.value encoding:NSUTF8StringEncoding];
                //                    NSLog(@"读取到特征值：%@",value);
                //                }
            }
        }
    }
}
//特征值被更新后
-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSLog(@"收到特征更新通知...");
    [self writeToLog:@"收到特征更新通知..."];
    if (error) {
        NSLog(@"更新通知状态时发生错误，错误信息：%@",error.localizedDescription);
    }
    //给特征值设置新的值
    CBUUID *characteristicUUID=[CBUUID UUIDWithString:kCharacteristicUUID];
    if ([characteristic.UUID isEqual:characteristicUUID]) {
        if (characteristic.isNotifying) {
            if (characteristic.properties==CBCharacteristicPropertyNotify) {
                NSLog(@"已订阅特征通知.");
                [self writeToLog:@"已订阅特征通知."];
                return;
            }else if (characteristic.properties ==CBCharacteristicPropertyRead) {
                //从外围设备读取新值,调用此方法会触发代理方法：-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
                [peripheral readValueForCharacteristic:characteristic];
            }
            
        }else{
            NSLog(@"停止已停止.");
            [self writeToLog:@"停止已停止."];
            //取消连接
            [self.centralManager cancelPeripheralConnection:peripheral];
        }
    }
}
//更新特征值后（调用readValueForCharacteristic:方法或者外围设备在订阅后更新特征值都会调用此代理方法）
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error) {
        NSLog(@"更新特征值时发生错误，错误信息：%@",error.localizedDescription);
        [self writeToLog:[NSString stringWithFormat:@"更新特征值时发生错误，错误信息：%@",error.localizedDescription]];
        return;
    }
    if (characteristic.value) {
        NSString *value=[[NSString alloc]initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        NSLog(@"读取到特征值：%@",value);
        [self writeToLog:[NSString stringWithFormat:@"读取到特征值：%@",value]];
    }else{
        NSLog(@"未发现特征值.");
        [self writeToLog:@"未发现特征值."];
    }
}


@end
