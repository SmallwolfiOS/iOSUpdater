//
//  iOSUpdater.h
//  iOSUpdaterDemo
//
//  Created by Mahp on 2019/12/10.
//  Copyright © 2019 Mahp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSUInteger, UpdaterAlertType){
    UpdaterAlertTypeForce = 1,    // Forces user to update your app
    UpdaterAlertTypeOption,       // (DEFAULT) Presents user with option to update app now or at next launch
    UpdaterAlertTypeNone          // Don't show the alert type , useful for skipping Patch, Minor, Major updates
};

@interface iOSUpdater : NSObject

@property (nonatomic, strong) NSString * appName;
@property (nonatomic, strong) UIWindow * window;



+ (iOSUpdater *)shareInstance;
- (void)checkVersionType:(UpdaterAlertType)type;




@end

NS_ASSUME_NONNULL_END
