//
//  ViewController.m
//  BlueTooth
//
//  Created by t3 on 2017/4/26.
//  Copyright © 2017年 feyddy. All rights reserved.
//

#import "ViewController.h"
#import "FDGameKitViewController.h"
#import "FDMultipeerConnectivityViewController.h"
#import "FDCoreBluetoothViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)GameKitMethod:(id)sender {
    //1.加载storyboard,（注意：这里仅仅是加载名称为test的storyboard,并不会创建storyboard中的控制器和控件）
    UIStoryboard *storyboard=[UIStoryboard storyboardWithName:@"FDGameKitViewController" bundle:nil];
    //2.下面这个方法代表着创建storyboard中箭头指向的控制器（初始控制器）
    FDGameKitViewController *controller = [storyboard instantiateInitialViewController];
    [self presentViewController:controller animated:YES completion:^{
        
    }];
}


- (IBAction)MultipeerConnectivityMethod:(id)sender {
    FDMultipeerConnectivityViewController *controller = [[FDMultipeerConnectivityViewController alloc] init];
    [self presentViewController:controller animated:YES completion:^{
        
    }];
}

- (IBAction)CoreBluetoothMethod:(id)sender {
    FDCoreBluetoothViewController *controller = [[FDCoreBluetoothViewController alloc] init];
    [self presentViewController:controller animated:YES completion:^{
        
    }];
}

@end
