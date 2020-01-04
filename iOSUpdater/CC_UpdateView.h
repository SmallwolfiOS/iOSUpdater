//
//  CC_UpdateView.h
//  iOSUpdaterDemo
//
//  Created by Mahp on 2019/12/11.
//  Copyright © 2019 Mahp. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CC_UpdateView : UIView

+ (void)showUpdateViewSkip:(BOOL)showSkip UpdateBlock:(void(^)(void))updateBlock SkipBlock:(void(^)(void))skipBlock;
+ (void)dismiss;

@end

NS_ASSUME_NONNULL_END
