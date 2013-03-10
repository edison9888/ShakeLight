//
//  main.m
//  ShakeLight
//
//  Created by yin yi on 2013/03/10.
//  Copyright (c) 2013年 yin yi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "MobiSageSDK.h"

int main(int argc, char *argv[])
{
    @autoreleasepool {
        [[MobiSageManager getInstance] setPublisherID:@"419e8481d22e4bee85ef0520f6f7d143"];
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
