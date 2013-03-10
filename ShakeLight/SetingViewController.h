//
//  SetingViewController.h
//  AudioControlLight
//
//  Created by yin yi on 2013/01/31.
//  Copyright (c) 2013年 yin yi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SetingViewController : UIViewController

@property(nonatomic,strong)IBOutlet UIButton *myRadioBt1;
@property(nonatomic,strong)IBOutlet UIButton *myRadioBt2;
@property(nonatomic,strong)IBOutlet UIButton *myRadioBt3;
@property(nonatomic,strong)IBOutlet UIButton *myBackBt;

-(IBAction)btPressed:(id)sender;
+(int)getMode;
+(void)setMode:(int)mode;

@end
