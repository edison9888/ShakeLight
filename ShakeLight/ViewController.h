//
//  ViewController.h
//  ShakeLight
//
//  Created by yin yi on 2013/03/10.
//  Copyright (c) 2013年 yin yi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <StoreKit/StoreKit.h>
#import "MobiSageSDK.h"
#import <CoreLocation/CLLocationManagerDelegate.h>
#import "RNExpandingButtonBar.h"

@interface ViewController : UIViewController<MobiSageRecommendDelegate,MobiSageAdViewDelegate,CLLocationManagerDelegate,RNExpandingButtonBarDelegate,UIAccelerometerDelegate>{
    
}

@property(nonatomic,strong)IBOutlet UIButton *myBtn;
@property(nonatomic,strong) UIButton *mySetBt;
@property(nonatomic,strong) UIButton *mySOSbt;
@property(nonatomic,strong) UIButton *myCommitBt;
@property(nonatomic,strong)IBOutlet UIImageView *myBg;
//指南针部分
@property(nonatomic,strong) UIImageView *compassView;
@property(nonatomic, strong)CLLocationManager *locationManager;
@property(nonatomic, strong)NSTimer *timerShine;

@property (nonatomic, strong) RNExpandingButtonBar *bar;
//url
@property (nonatomic, strong)NSString *url;
@property (nonatomic, strong)MobiSageAdBanner *myAdBar;

-(void)openTorch:(BOOL)_close;
-(IBAction)btnDown:(id)sender;
-(void)addRecommend;

@end
