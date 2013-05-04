//
//  ViewController.m
//  ShakeLight
//
//  Created by yin yi on 2013/03/10.
//  Copyright (c) 2013年 yin yi. All rights reserved.
//

#import "ViewController.h"
#import "SetingViewController.h"
#import <CoreLocation/CLHeading.h>
#import "URBAlertView.h"
#import "math.h"
#include <sys/socket.h>
#include <ifaddrs.h>
#import "Toast.h"
#import <AudioToolbox/AudioToolbox.h>

#define toRad(X) (X*M_PI/180.0)
#define toDeg(X) (X*180.0/M_PI)

@interface ViewController (){
    AVCaptureDevice *device;
    BOOL close;
    BOOL isFlash;
    BOOL deleteAD;
    BOOL sosFlag;
    NSTimeInterval now;
    UIAlertView *alertProcess;
    
    CLLocationCoordinate2D currentLocation;
    CLLocationDirection currentHeading;
    int mosCode;
    BOOL sosSwitch;
    CGSize compassSize;
}

//隐藏在.m文件中的方法
-(NSString*)fileTextPath;
-(void)lightSwitch;
-(void)mosCodeInit;
-(void)mosCodeClose;
-(void)terminate;

-(void)onSOS;
-(void)onSet;
-(void)onCommit;
-(void)BtnAdd;
-(uint32_t)getNetType;

@end

@implementation ViewController

@synthesize myBtn,mySetBt,myBg,compassView,locationManager,timerShine,mySOSbt,myCommitBt,bar,url,myAdBar;

-(id)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder:aDecoder]) {
        
        device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        close = YES;
        isFlash = NO;
        sosSwitch = NO;
        deleteAD = NO;
        now = [[NSDate date] timeIntervalSinceReferenceDate]*1000;
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    UIImage* compass = [UIImage imageNamed:@"compass.png"];
    compassView = [[UIImageView alloc] initWithImage:compass];
    compassSize = compass.size;
    [compassView setFrame:CGRectMake(215, 6, compass.size.width/2, compass.size.height/2)];
    [compassView setAutoresizesSubviews:NO];
    [self.view addSubview:compassView];
    
    if (iPhone5) {
        [myBg setFrame:CGRectMake(0, 0, 320, 568)];
    }
    
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"twiceLaunch"] == nil){
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"twiceLaunch"];
        URBAlertView *alertView = [URBAlertView dialogWithTitle:@"温馨提示" subtitle:@"亲，感谢您对我们产品的使用！仅当您的手机处于wifi状态下时，我们才会给您进行广告推送，wifi状态下不会产生付费流量，希望得到您的谅解！"];
        alertView.blurBackground = NO;
        [alertView setFrame:CGRectMake(alertView.bounds.origin.x, alertView.bounds.origin.y, alertView.bounds.size.width, alertView.bounds.size.height + 30)];
        [alertView addButtonWithTitle:@"确定"];
        [alertView setHandlerBlock:^(NSInteger buttonIndex, URBAlertView *alertView) {
            [[ToastSettings getSharedSettings] setGravity:ToastGravityBottom];
            Toast* mToast = [Toast makeText:@"摇一摇就可以控制手电筒的开关呦！"];
            [mToast setDuration:4000];
            [mToast show];
            [alertView hideWithCompletionBlock:^{
                // stub
            }];
        }];
        [alertView showWithAnimation:URBAlertAnimationFlipHorizontal];
    }else{
        if (![device hasTorch]) {
            URBAlertView *alertView = [URBAlertView dialogWithTitle:@"警告" subtitle:@"对不起，您的设备无背光灯！此应用无法使用。"];
            alertView.blurBackground = NO;
            [alertView addButtonWithTitle:@"确定"];
            [alertView setHandlerBlock:^(NSInteger buttonIndex, URBAlertView *alertView) {
                [alertView hideWithCompletionBlock:^{
                    // stub
                }];
            }];
            [alertView showWithAnimation:URBAlertAnimationFlipHorizontal];
        }
    }
    
    //指南针相关
    currentHeading = 0.0;
    [self startLocationHeadingEvents];
    //摩斯码sos
    //    [self mosCodeInit];
    
    //设置里的模式
    int mode = [[NSUserDefaults standardUserDefaults] integerForKey:@"audioMode"];
    [SetingViewController setMode:(mode == 0)?[SetingViewController getMode]:mode];
    
    //加载动态按钮
    [self BtnAdd];
    
    //重力加速器接口
    UIAccelerometer *accelerometer = [UIAccelerometer sharedAccelerometer];
    accelerometer.delegate = self;
    accelerometer.updateInterval = 1.0/30.0f;
    
    if ([SetingViewController getMode] == 2) {
        [self lightSwitch];
    }
}

-(void)BtnAdd{
    /* ---------------------------------------------------------
     * Create images that are used for the main button
     * -------------------------------------------------------*/
    UIImage *image = [UIImage imageNamed:@"plus.png"];
    UIImage *selectedImage = [UIImage imageNamed:@"plusDown.png"];
    UIImage *toggledImage = [UIImage imageNamed:@"x.png"];
    UIImage *toggledSelectedImage = [UIImage imageNamed:@"xDown.png"];
    
    /* ---------------------------------------------------------
     * Create the center for the main button and origin of animations
     * -------------------------------------------------------*/
    CGPoint center;
    if (iPhone5) {
        center = CGPointMake(280.0f, 480.0f);
    }else{
        center = CGPointMake(280.0f, 400.0f);
    }
    
    /* ---------------------------------------------------------
     * Setup buttons
     * Note: I am setting the frame to the size of my images
     * -------------------------------------------------------*/
    CGRect buttonFrame = CGRectMake(0, 0, 35.0f, 35.0f);
    mySOSbt = [UIButton buttonWithType:UIButtonTypeCustom];
    [mySOSbt setFrame:buttonFrame];
    [mySOSbt setImage:[UIImage imageNamed:@"sosOff.png"] forState:UIControlStateNormal];
    [mySOSbt addTarget:self action:@selector(onSOS) forControlEvents:UIControlEventTouchUpInside];
    mySetBt = [UIButton buttonWithType:UIButtonTypeCustom];
    [mySetBt setImage:[UIImage imageNamed:@"setting.png"] forState:UIControlStateNormal];
    [mySetBt setFrame:buttonFrame];
    [mySetBt addTarget:self action:@selector(onSet) forControlEvents:UIControlEventTouchUpInside];
    myCommitBt = [UIButton buttonWithType:UIButtonTypeCustom];
    [myCommitBt setImage:[UIImage imageNamed:@"commit.png"] forState:UIControlStateNormal];
    [myCommitBt setFrame:buttonFrame];
    [myCommitBt addTarget:self action:@selector(onCommit) forControlEvents:UIControlEventTouchUpInside];
    NSArray *buttons = [NSArray arrayWithObjects:mySOSbt, mySetBt, myCommitBt, nil];
    
    /* ---------------------------------------------------------
     * Init method, passing everything the bar needs to work
     * -------------------------------------------------------*/
    bar = [[RNExpandingButtonBar alloc] initWithImage:image selectedImage:selectedImage toggledImage:toggledImage toggledSelectedImage:toggledSelectedImage buttons:buttons center:center];
    
    /* ---------------------------------------------------------
     * Settings
     * -------------------------------------------------------*/
    [bar setDelegate:self];
    [bar setSpin:YES];
    
    /* ---------------------------------------------------------
     * Set our property and add it to the view
     * -------------------------------------------------------*/
    [self.view addSubview:bar];
}

-(void)mosCodeInit{
    mosCode = 0;
    sosFlag = YES;
    if (timerShine) {
        [timerShine invalidate];
        timerShine = nil;
    }
    timerShine = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(sosFlash) userInfo:nil repeats:YES];
}

-(void)mosCodeClose{
    if (timerShine) {
        [timerShine invalidate];
        timerShine = nil;
    }
    sosFlag = NO;
}

- (UIViewController *)viewControllerForPresentingModalView {
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)openTorch:(BOOL)_close{
    if ([device hasTorch] && _close) {
        
        [device lockForConfiguration:nil];
        
        [device setTorchMode: AVCaptureTorchModeOn];
        
        [device unlockForConfiguration];
        close = NO;
    }else if ([device hasTorch] && !_close){
        [device lockForConfiguration:nil];
        
        [device setTorchMode: AVCaptureTorchModeOff];
        
        [device unlockForConfiguration];
        close = YES;
    }
}

-(NSString*)fileTextPath{
    //NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDirectory, YES);
    NSString *documentsDirectory=NSTemporaryDirectory();
    return [documentsDirectory stringByAppendingPathComponent:@"sound.caf"];
}

-(IBAction)btnDown:(id)sender{
    if ([sender isEqual:myBtn]) {
        [self lightSwitch];
    }
}

-(void)lightSwitch{
    if (myBtn.tag == 0) {
        [myBtn setImage:[UIImage imageNamed:@"on.png"] forState:UIControlStateNormal];
        [self openTorch:YES];
        [myBg setImage:[UIImage imageNamed:@"lightOn.png"]];
        myBg.tag = 1;
        myBtn.tag = 1;
    }else{
        [myBtn setImage:[UIImage imageNamed:@"off.png"] forState:UIControlStateNormal];
        [self openTorch:NO];
        [myBg setImage:[UIImage imageNamed:@"lightOff.png"]];
        if ([SetingViewController getMode] == 2 && !sosFlag) {
            [[ToastSettings getSharedSettings] setGravity:ToastGravityCenter];
            Toast* mToast = [Toast makeText:@"极简模式，手电筒应用即将自动关闭！"];
            [mToast setDuration:3000];
            [mToast show];
            [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(terminate) userInfo:nil repeats:YES];
        }
        myBg.tag = 0;
        myBtn.tag = 0;
    }
}

-(void)terminate{
    [[UIApplication sharedApplication] performSelector:@selector(terminateWithSuccess)];
}

-(void)addRecommend{
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"xianMian"] boolValue]) {
        UIImage* img = [UIImage imageNamed:@"recommend.png"];
        MobiSageRecommendView *recommendView = [[MobiSageRecommendView alloc] initWithDelegate:self andImg:img];
        recommendView.frame = CGRectMake(0, 280, img.size.width, img.size.height);
        [self.view addSubview:recommendView];
        if ([[NSUserDefaults standardUserDefaults] integerForKey:@"deleteAD"] == 0) {
            if ([self getNetType] == 1) {
                myAdBar = [[MobiSageAdBanner alloc] initWithAdSize:Ad_320X50 withDelegate:self];
                [self.view addSubview:myAdBar];
                [compassView removeFromSuperview];
                [compassView setFrame:CGRectMake(215, 56, compassSize.width/2, compassSize.height/2)];
                [self.view addSubview:compassView];
            }
        }
    }
}

- (void)startLocationHeadingEvents{
    if (locationManager == nil) {
        CLLocationManager* theManager = [[CLLocationManager alloc] init];
        
        // Retain the object in a property.
        self.locationManager = theManager;
        locationManager.delegate = self;
    }
    
    // Start heading updates.
    if ([CLLocationManager headingAvailable]) {
        locationManager.headingFilter = 5;
        [locationManager startUpdatingHeading];
    }else{
        URBAlertView *alertView = [URBAlertView dialogWithTitle:@"警告" subtitle:@"您的设备不支持指南针功能！"];
        alertView.blurBackground = NO;
        [alertView addButtonWithTitle:@"确定"];
        [alertView setHandlerBlock:^(NSInteger buttonIndex, URBAlertView *alertView) {
            [alertView hideWithCompletionBlock:^{
                // stub
            }];
        }];
        [alertView showWithAnimation:URBAlertAnimationFlipHorizontal];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    if (newHeading.headingAccuracy < 0)
        return;
    
    // Use the true heading if it is valid.
    CLLocationDirection  theHeading = newHeading.trueHeading;
    //    ((newHeading.trueHeading > 0) ? newHeading.trueHeading : newHeading.magneticHeading);//trueHeading是地理上的方向，magneticHeading是磁极的方向
    
    currentHeading = theHeading;
    [self updateHeadingDisplays];
}

- (void)updateHeadingDisplays {
    // Animate Compass
    [UIView     animateWithDuration:0.3
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             CGAffineTransform headingRotation;
                             headingRotation = CGAffineTransformRotate(CGAffineTransformIdentity, (CGFloat)-toRad(currentHeading));
                             compassView.transform = headingRotation;
                         }
                         completion:^(BOOL finished) {
                             
                         }];
}

-(void)sosFlash{
    switch (mosCode) {
        case 2:
            [self lightSwitch];
            break;
        case 4:
            [self lightSwitch];
            break;
        case 6:
            [self lightSwitch];
            break;
        case 8:
            [self lightSwitch];
            break;
        case 10:
            [self lightSwitch];
            break;
        case 12:
            [self lightSwitch];
            break;
        case 17:
            [self lightSwitch];
            break;
        case 21:
            [self lightSwitch];
            break;
        case 23:
            [self lightSwitch];
            break;
        case 27:
            [self lightSwitch];
            break;
        case 29:
            [self lightSwitch];
            break;
        case 33:
            [self lightSwitch];
            break;
        case 38:
            [self lightSwitch];
            break;
        case 40:
            [self lightSwitch];
            break;
        case 42:
            [self lightSwitch];
            break;
        case 44:
            [self lightSwitch];
            break;
        case 46:
            [self lightSwitch];
            break;
        case 48:
            [self lightSwitch];
            break;
        case 59:
            mosCode = -1;
            break;
            
        default:
            break;
    }
    mosCode++;
}

- (void) onSOS
{
    /* ---------------------------------------------------------
     * Hide the buttons with an animation
     * -------------------------------------------------------*/
    if (sosSwitch) {
        [self mosCodeClose];
        [mySOSbt setImage:[UIImage imageNamed:@"sosOff.png"] forState:UIControlStateNormal];
        sosSwitch = NO;
        [self openTorch:NO];
    }else{
        [self mosCodeInit];
        [mySOSbt setImage:[UIImage imageNamed:@"sosOn.png"] forState:UIControlStateNormal];
        sosSwitch = YES;
    }
}

- (void) onSet
{
    /* ---------------------------------------------------------
     * Hide the buttons without an animation
     * -------------------------------------------------------*/
    [[self bar] hideButtonsAnimated:NO];
    if (myBtn.tag == 1){
        [myBtn setImage:[UIImage imageNamed:@"off.png"] forState:UIControlStateNormal];
        [self openTorch:NO];
        [myBg setImage:[UIImage imageNamed:@"lightOff.png"]];
        myBg.tag = 0;
        myBtn.tag = 0;
    }
    UIViewController* nextController = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"SetingViewController"];
    [self presentViewController:nextController animated:YES completion:nil];
}

- (void) onCommit
{
    [[self bar] hideButtonsAnimated:YES];
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"deleteAD"] == 1) {
        URBAlertView *alertView = [URBAlertView dialogWithTitle:@"感谢！" subtitle:@"亲，衷心感谢您对我们产品的使用！"];
        alertView.blurBackground = NO;
        [alertView addButtonWithTitle:@"确定"];
        [alertView setHandlerBlock:^(NSInteger buttonIndex, URBAlertView *alertView) {
            [alertView hideWithCompletionBlock:^{
                // stub
            }];
        }];
        [alertView showWithAnimation:URBAlertAnimationFlipHorizontal];
    }else if ([[NSUserDefaults standardUserDefaults] integerForKey:@"deleteAD"] == 2) {
        URBAlertView *alertView = [URBAlertView dialogWithTitle:@"去除广告" subtitle:@"亲，感谢您下载应用推荐中的应用，确定要去除广告吗？"];
        alertView.blurBackground = NO;
        [alertView addButtonWithTitle:@"确定"];
        [alertView addButtonWithTitle:@"取消"];
        [alertView setHandlerBlock:^(NSInteger buttonIndex, URBAlertView *alertView) {
            if (buttonIndex == 0) {
                [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"deleteAD"];
                [myAdBar removeFromSuperview];
                [compassView setFrame:CGRectMake(215, 6, compassSize.width/2, compassSize.height/2)];
            }
            [alertView hideWithCompletionBlock:^{
                // stub
            }];
        }];
        [alertView showWithAnimation:URBAlertAnimationFlipHorizontal];
    }else{
        URBAlertView *alertView = [URBAlertView dialogWithTitle:@"去除广告" subtitle:@"亲，点击应用推荐并成功下载一个应用就可以去除广告条哦！"];
        alertView.blurBackground = NO;
        [alertView addButtonWithTitle:@"确定"];
        [alertView setHandlerBlock:^(NSInteger buttonIndex, URBAlertView *alertView) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"pushedCommit"];
            [alertView hideWithCompletionBlock:^{
                // stub
            }];
        }];
        [alertView showWithAnimation:URBAlertAnimationFlipHorizontal];
    }
}

-(uint32_t)getNetType{
    BOOL ret = YES;
    struct ifaddrs * first_ifaddr, * current_ifaddr;
    NSMutableArray* activeInterfaceNames = [[NSMutableArray alloc] init];
    getifaddrs( &first_ifaddr );
    current_ifaddr = first_ifaddr;
    while( current_ifaddr!=NULL )
    {
        if( current_ifaddr->ifa_addr->sa_family == AF_INET )
        {
            [activeInterfaceNames addObject:[NSString stringWithFormat:@"%s", current_ifaddr->ifa_name]];
        }
        current_ifaddr = current_ifaddr->ifa_next;
    }
    
    ret = [activeInterfaceNames containsObject:@"en0"] || [activeInterfaceNames containsObject:@"en1"];
    
    return ret;
}
/* ---------------------------------------------------------
 * Delegate methods of MobiSageAdViewDelegate
 * -------------------------------------------------------*/
- (UIViewController *) viewControllerToPresent {
    return self;
}


/* ---------------------------------------------------------
 * Delegate methods of ExpandingButtonBarDelegate
 * -------------------------------------------------------*/
- (void) expandingBarDidAppear:(RNExpandingButtonBar *)bar
{
    
}

- (void) expandingBarWillAppear:(RNExpandingButtonBar *)bar
{
    
}

- (void) expandingBarDidDisappear:(RNExpandingButtonBar *)bar
{
    
}

- (void) expandingBarWillDisappear:(RNExpandingButtonBar *)bar
{
    
}

/* ---------------------------------------------------------
 * Delegate methods of UIAccelerometerDelegate
 * -------------------------------------------------------*/
- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration{    
    if (fabsf(acceleration.x)>1.8||
        fabsf(acceleration.y)>1.8||
        fabsf(acceleration.z)>1.8) {
        if ([[NSDate date] timeIntervalSinceReferenceDate]*1000 - now > 1000) {
            if ([SetingViewController getMode] != 3 && !sosFlag) {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                [self lightSwitch];
            }
            now = [[NSDate date] timeIntervalSinceReferenceDate]*1000;
        }
    }
}

//推荐页面弹出时通知
- (void)MobiSageWillOpenRecommendModalView {
    
}
//推荐页面弹出失败时通知
- (void)MobiSageFailToOpenRecommendModalView {
    
}
//推荐页面关闭时通知
- (void)MobiSageDidCloseRecommendModalView {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"pushedCommit"] && [[NSUserDefaults standardUserDefaults] integerForKey:@"deleteAD"] != 1) {
        [[NSUserDefaults standardUserDefaults] setInteger:2 forKey:@"deleteAD"];
    }
}

@end
