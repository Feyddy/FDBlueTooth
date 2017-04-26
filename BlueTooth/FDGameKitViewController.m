//
//  FDGameKitViewController.m
//  BlueTooth
//
//  Created by t3 on 2017/4/26.
//  Copyright © 2017年 feyddy. All rights reserved.
//


/** 从iOS7已经全部过期，苹果官方推荐使用MultipeerConnectivity代替
 * GKPeerPickerController：蓝牙查找、连接用的视图控制器，通常情况下应用程序A打开后会调用此控制器的show方法来展示一个蓝牙查找的视图，一旦发现了另一个同样在查找蓝牙连接的客户客户端B就会出现在视图列表中，此时如果用户点击连接B，B客户端就会询问用户是否允许A连接B，如果允许后A和B之间建立一个蓝牙连接。
 
   GKSession：连接会话，主要用于发送和接受传输数据。一旦A和B建立连接GKPeerPickerController的代理方法会将A、B两者建立的会话（GKSession）对象传递给开发人员，开发人员拿到此对象可以发送和接收数据。
 
    两个程序运行之后均调用GKPeerPickerController来发现周围蓝牙设备，一旦A发现了B之后就开始连接B，然后iOS会询问用户是否接受连接，一旦接受之后就会调用GKPeerPickerController的-(void)peerPickerController:(GKPeerPickerController )picker didConnectPeer:(NSString )peerID toSession:(GKSession *)session代理方法，在此方法中可以获得连接的设备id（peerID）和连接会话（session）；此时可以设置会话的数据接收句柄（相当于一个代理）并保存会话以便发送数据时使用；一旦一端（假设是A）调用会话的sendDataToAllPeers: withDataMode: error:方法发送数据，此时另一端（假设是B）就会调用句柄的- (void) receiveData:(NSData )data fromPeer:(NSString )peer inSession: (GKSession )session context:(void )context方法，在此方法可以获得发送数据并处理。
 
    缺点：仅仅支持iOS设备，传输内容仅限于沙盒或者照片库中用户选择的文件，并且只能在同一个应用之间进行传输（一个iOS设备安装应用A，另一个iOS设备上安装应用B是无法传输的）
 
 */

#import "FDGameKitViewController.h"
#import <GameKit/GameKit.h>

@interface FDGameKitViewController ()<GKPeerPickerControllerDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *pictureImageView;//照片显示
@property (strong,nonatomic) GKSession *session;//蓝牙连接会话
@end

@implementation FDGameKitViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    GKPeerPickerController *pearPickerController = [[GKPeerPickerController alloc] init];
    pearPickerController.delegate = self;
    [pearPickerController show];
}

- (IBAction)selectedAction:(id)sender {
    UIImagePickerController *pick = [[UIImagePickerController alloc] init];
    pick.delegate = self;
    [self presentViewController:pick animated:YES completion:nil];
}


- (IBAction)sendAction:(id)sender {
    NSData *data=UIImagePNGRepresentation(self.pictureImageView.image);
    NSError *error=nil;
    [self.session sendDataToAllPeers:data withDataMode:GKSendDataReliable error:&error];
    if (error) {
        NSLog(@"发送图片过程中发生错误，错误信息:%@",error.localizedDescription);
    }
}

#pragma mark - GKPeerPickerController代理方法
/**
 *  连接到某个设备
 *
 *  @param picker  蓝牙点对点连接控制器
 *  @param peerID  连接设备蓝牙传输ID
 *  @param session 连接会话
 */
-(void)peerPickerController:(GKPeerPickerController *)picker didConnectPeer:(NSString *)peerID toSession:(GKSession *)session{
    self.session=session;
    NSLog(@"已连接客户端设备:%@.",peerID);
    //设置数据接收处理句柄，相当于代理，一旦数据接收完成调用它的-receiveData:fromPeer:inSession:context:方法处理数据
    [self.session setDataReceiveHandler:self withContext:nil];
    
    [picker dismiss];//一旦连接成功关闭窗口
}

#pragma mark - 蓝牙数据接收方法
- (void) receiveData:(NSData *)data fromPeer:(NSString *)peer inSession: (GKSession *)session context:(void *)context{
    UIImage *image=[UIImage imageWithData:data];
    self.pictureImageView.image=image;
    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    NSLog(@"数据发送成功！");
}


#pragma mark - UIImagePickerController代理方法
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    self.pictureImageView.image=[info objectForKey:UIImagePickerControllerOriginalImage];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
