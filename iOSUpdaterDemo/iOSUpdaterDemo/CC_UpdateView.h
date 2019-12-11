//
//  CC_UpdateView.h
//  iOSUpdaterDemo
//
//  Created by Apple on 2019/12/11.
//  Copyright © 2019 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CC_UpdateView : UIView

+ (void)showUpdateViewSkip:(BOOL)showSkip UpdateBlock:(void(^)(void))updateBlock SkipBlock:(void(^)(void))skipBlock;
+ (void)dismiss;

@end

NS_ASSUME_NONNULL_END
