//
//  Toast.h
//  LegendEngine
//
//  Created by yi yin on 12-9-19.
//  Copyright (c) 2012年 snda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum ToastGravity {
	ToastGravityTop = 1000001,
	ToastGravityBottom,
	ToastGravityCenter
}ToastGravity;

enum ToastDuration {
	ToastDurationLong = 10000,
	ToastDurationShort = 1000,
	ToastDurationNormal = 3000
}ToastDuration;

typedef enum ToastType {
	ToastTypeInfo = -100000,
	ToastTypeNotice,
	ToastTypeWarning,
	ToastTypeError,
	ToastTypeNone // For internal use only (to force no image)
}ToastType;


@class ToastSettings;

@interface Toast : NSObject {
	ToastSettings *_settings;
	NSInteger offsetLeft;
	NSInteger offsetTop;
    
	NSTimer *timer;
    
	UIView *view;
	NSString *text;
}

- (void) show;
- (void) show:(ToastType) type;
- (Toast *) setDuration:(NSInteger ) duration;
- (Toast *) setGravity:(ToastGravity) gravity 
			 offsetLeft:(NSInteger) left
              offsetTop:(NSInteger) top;
- (Toast *) setGravity:(ToastGravity) gravity;
- (Toast *) setPostion:(CGPoint) position;
+ (Toast *) makeText:(NSString *) text;
-(ToastSettings *) theSettings;

@end



@interface ToastSettings : NSObject<NSCopying>{
	NSInteger duration;
	ToastGravity gravity;
	CGPoint postition;
	ToastType toastType;
    
	NSDictionary *images;
    
	BOOL positionIsSet;
}


@property(assign) NSInteger duration;
@property(assign) ToastGravity gravity;
@property(assign) CGPoint postition;
@property(readonly) NSDictionary *images;


- (void) setImage:(UIImage *)img forType:(ToastType) type;
+ (ToastSettings *) getSharedSettings;

@end
