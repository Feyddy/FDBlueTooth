//
//  FDMultipeerConnectivityViewController.m
//  BlueTooth
//
//  Created by t3 on 2017/4/26.
//  Copyright © 2017年 feyddy. All rights reserved.
//

/**
 * MultipeerConnectivity.framework并不仅仅支持蓝牙连接，准确的说它是一种支持Wi-Fi网络、P2P Wi-Fi已经蓝牙个人局域网的通信框架，它屏蔽了具体的连接技术，让开发人员有统一的接口编程方法。通过MultipeerConnectivity连接的节点之间可以安全的传递信息、流或者其他文件资源而不必通过网络服务。此外使用MultipeerConnectivity进行近场通信也不再局限于同一个应用之间传输，而是可以在不同的应用之间进行数据传输（当然如果有必要的话你仍然可以选择在一个应用程序之间传输）。
 
    广播（Advertisting）和发现（Disconvering），这很类似于一种Client-Server模式.
    A. 广播
    无论是作为服务器端区广播还是作为客户端去发现广播服务，两个设备必须要有不同的区分，使用MCPeerID对象来区分一台设备，在这个设备中可以指定给对方查看的名称。另外不管是哪一方，还必须建立一个会话MCSession用于发送和接受数据。通常情况下会在会话的-(void)session:(MCSession )session peer:(MCPeerID )peerID didChangeState:(MCSessionState)state代理方法中跟踪会话状态（已连接、正在连接、未连接）;在会话的-(void)session:(MCSession )session didReceiveData:(NSData )data fromPeer:(MCPeerID *)peerID代理方法中接收数据;同时还会调用会话的-(void)sendData: toPeers:withMode: error:方法去发送数据。
 
    广播作为一个服务器去发布自身服务，供周边设备发现连接。MultipeerConnectivity中使用MCAdvertiserAssistant来表示一个广播，通常创建广播时指定一个会话MCSession对象将广播服务和会话关联起来。一旦调用广播的start方法周边的设备就可以发现该广播并可以连接到此服务。在MCSession的代理方法中可以随时更新连接状态，一旦建立了连接之后就可以通过MCSession的connectedPeers获得已经连接的设备。
    B. 发现
    作为发现的客户端同样需要一个MCPeerID来标志一个客户端，同时会拥有一个MCSession来监听连接状态并发送、接受数据。而且要发现广播服务客户端就必须要随时查找服务来连接。在MultipeerConnectivity中提供了一个控制器MCBrowserViewController来展示可连接和已连接的设备（这类似于GameKit中的GKPeerPickerController），当然如果想要自己定制一个界面来展示设备连接的情况你可以选择自己开发一套UI界面。一旦通过MCBroserViewController选择一个节点去连接，那么作为广播的节点就会收到通知，询问用户是否允许连接。由于初始化MCBrowserViewController的过程已经指定了会话MCSession，所以连接过程中会随时更新会话状态，一旦建立了连接，就可以通过会话的connected属性获得已连接设备并且可以使用会话发送、接受数据。
 
    * 当两个设备应用连接之后，可以互传文件。注意：广播和发现的代码有点区别，所以下面我都标注过。一下面整体的是以广播的为主，注释部分为发现的
    缺点是能在iOS设备之间传播，但是可以再不同的应用之间传播
 */


#import "FDMultipeerConnectivityViewController.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface FDMultipeerConnectivityViewController ()<MCSessionDelegate,MCAdvertiserAssistantDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,MCBrowserViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *pictureImageView;

@property (strong,nonatomic) MCSession *session;
@property (strong,nonatomic) MCAdvertiserAssistant *advertiserAssistant;//创建一个广播对象
@property (strong,nonatomic) MCBrowserViewController *browserViewController;//创建一个发现显示对象
@property (strong,nonatomic) UIImagePickerController *imagePickerController;


@end

@implementation FDMultipeerConnectivityViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 创建节点，displayName是用于提供给周边设备查看和区分此服务的
    // 注意 peerID 在广播和发现的设备中是不一样的
    MCPeerID *peerID = [[MCPeerID alloc] initWithDisplayName:@"Feyddy"];// 发现的时候改成Feyddy2

    // 创建蓝牙连接会话
    _session = [[MCSession alloc] initWithPeer:peerID];
    _session.delegate = self;
    
    
    /*
     服务类型“cmj-photo”，这是唯一标识一个服务类型的标记，可以按照官方的要求命名，应该尽可能表达服务的作用。需要特别指出的是，如果广播命名为“cmj-photo”那么发现节点只有在MCBrowserViewController中指定为“cmj-photo”才能发现此服务。
     */
    
    // 创建广播
    _advertiserAssistant = [[MCAdvertiserAssistant alloc] initWithServiceType:@"cmj-stream" discoveryInfo:nil session:_session];
    _advertiserAssistant.delegate = self;
    
}

- (IBAction)startAdvertiserMethod:(id)sender {
    // 开始发布广播
    [self.advertiserAssistant start];
    
    /*
    // 发现的设备中使用下面的
    UIButton *btn = (UIButton *)sender;
    [btn setTitle:@"search" forState:UIControlStateNormal];
    _browserViewController = [[MCBrowserViewController alloc] initWithServiceType:@"cmj-stream" session:_session];
    _browserViewController.delegate = self;
    [self presentViewController:_browserViewController animated:YES completion:nil];
     */
}

- (IBAction)selectedMethod:(id)sender {
    // 打开相册选照片发送
    _imagePickerController = [[UIImagePickerController alloc] init];
    _imagePickerController.delegate = self;
    [self presentViewController:_imagePickerController animated:YES completion:nil];
}

/*
#pragma mark - MCBrowserViewController代理方法 发现的时候使用
-(void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController{
    NSLog(@"已选择");
    [self.browserViewController dismissViewControllerAnimated:YES completion:nil];
}
-(void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController{
    NSLog(@"取消浏览.");
    [self.browserViewController dismissViewControllerAnimated:YES completion:nil];
}
*/
#pragma mark - MCSession代理方法
-(void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
    
    NSLog(@"didChangeState");
    switch (state) {
        case MCSessionStateConnected:
            NSLog(@"连接成功.");
            break;
        case MCSessionStateConnecting:
            NSLog(@"正在连接...");
            break;
        default:
            NSLog(@"连接失败.");
            break;
    }
}
//接收数据
-(void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID{
    NSLog(@"开始接收数据...");
    UIImage *image=[UIImage imageWithData:data];
    [self.pictureImageView setImage:image];
    //保存到相册
    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    
}


#pragma mark - UIImagePickerController代理方法
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    
    UIImage *image=[info objectForKey:UIImagePickerControllerOriginalImage];
    [self.pictureImageView setImage:image];
    //发送数据给所有已连接设备
    NSError *error=nil;
    [self.session sendData:UIImagePNGRepresentation(image) toPeers:[self.session connectedPeers] withMode:MCSessionSendDataUnreliable error:&error];
    NSLog(@"开始发送数据...");
    if (error) {
        NSLog(@"发送数据过程中发生错误，错误信息：%@",error.localizedDescription);
    }
    [self.imagePickerController dismissViewControllerAnimated:YES completion:nil];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [self.imagePickerController dismissViewControllerAnimated:YES completion:nil];
}

@end
