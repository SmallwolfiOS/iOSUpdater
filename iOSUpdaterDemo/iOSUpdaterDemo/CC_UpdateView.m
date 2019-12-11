//
//  CC_UpdateView.m
//  iOSUpdaterDemo
//
//  Created by Apple on 2019/12/11.
//  Copyright © 2019 Apple. All rights reserved.
//

#import "CC_UpdateView.h"
#import "Masonry.h"
// 屏幕宽高
#define kScreenWidth                    ([UIScreen mainScreen].bounds.size.width)
#define kScreenHeight                   ([UIScreen mainScreen].bounds.size.height)
#define ImageSource(x)                  [UIImage imageNamed:x]


@interface CC_UpdateView ()
@property (nonatomic,strong)UIImageView             * ccLogoView;
@property (nonatomic,strong)UILabel                 * titleLabel;
@property (nonatomic,strong)UILabel                 * detailLabel;
@property (nonatomic,strong)UIButton                * updateBtn;
@property (nonatomic,strong)UIButton                * skipNextTimeBtn;
@property (nonatomic,strong)UIImageView             * bottomImgView;
@property (nonatomic,assign)BOOL                    showSkip;
@property (nonatomic,  copy)   void(^updateBlock)(void);
@property (nonatomic,  copy)   void(^skipBlock)(void);
@end


@implementation CC_UpdateView


- (id)initWithShowSkip:(BOOL)showSkip{
    if (self = [super initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight)]) {
        [self addSubview:self.ccLogoView];
        [self addSubview:self.titleLabel];
        [self addSubview:self.detailLabel];
        [self addSubview:self.updateBtn];
        if (showSkip) {
            [self addSubview:self.skipNextTimeBtn];
            _showSkip = showSkip;
        }
        [self addSubview:self.bottomImgView];
        [self layoutSubviewsSnapKit];
    }
    return self;
}
#pragma mark -PublicFunciotns
+ (void)showUpdateViewSkip:(BOOL)showSkip UpdateBlock:(void(^)(void))updateBlock SkipBlock:(void(^)(void))skipBlock{
    CC_UpdateView * view = [[CC_UpdateView alloc]initWithShowSkip:showSkip];
    UIWindow * window = [UIApplication sharedApplication].windows[0];
    [window addSubview:view];
    view.skipBlock = skipBlock;
    view.updateBlock = updateBlock;
}
+ (void)dismiss{
    UIWindow * window = [UIApplication sharedApplication].keyWindow;
    [window.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:CC_UpdateView.class]) {
            [obj mas_updateConstraints:^(MASConstraintMaker *make) {
                make.top.mas_equalTo(kScreenHeight);
            }];
            [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                [obj.superview layoutIfNeeded];
            } completion:^(BOOL finished) {
                obj.hidden = YES;
                [obj removeFromSuperview];
            }];

        }
    }];
}
#pragma mark - Lazy
- (UIImageView *)ccLogoView{
    if (!_ccLogoView) {
        _ccLogoView = [[UIImageView alloc]init];
        [_ccLogoView setImage:ImageSource(@"CC_Update_logo")];
    }
    return _ccLogoView;
}
- (UILabel * )titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"升级到最新版本？" attributes:@{NSFontAttributeName: [UIFont fontWithName:@"PingFang SC" size: 25],NSForegroundColorAttributeName: [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0]}];
        [_titleLabel setAttributedText:string];
    }
    return _titleLabel;
}
- (UILabel * )detailLabel{
    if (!_detailLabel) {
        _detailLabel = [[UILabel alloc]init];
        _detailLabel.numberOfLines = 3;
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"您的App版本很旧了，\n小测都快忘记怎么为您服务了。\n立即升级，享受更好的使用体验吧！" attributes:@{NSFontAttributeName: [UIFont fontWithName:@"PingFang SC" size: 15],NSForegroundColorAttributeName: [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0]}];
        [string addAttributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:67/255.0 green:157/255.0 blue:249/255.0 alpha:1.0]} range:NSMakeRange(27, 4)];
        [_detailLabel setAttributedText:string];
    }
    return _detailLabel;
}
- (UIButton *)updateBtn{
    if (!_updateBtn) {
        _updateBtn = [[UIButton alloc]init];
        [_updateBtn setImage:ImageSource(@"CC_Update_go") forState:UIControlStateNormal];
        [_updateBtn addTarget:self action:@selector(update:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _updateBtn;
}
- (UIButton *)skipNextTimeBtn{
    if (!_skipNextTimeBtn) {
        _skipNextTimeBtn = [[UIButton alloc]init];
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"下次再说" attributes:@{NSFontAttributeName: [UIFont fontWithName:@"PingFang SC" size: 16],NSForegroundColorAttributeName: [UIColor colorWithRed:216/255.0 green:216/255.0 blue:216/255.0 alpha:1.0]}];
        [_skipNextTimeBtn setAttributedTitle:string forState:UIControlStateNormal];
        [_skipNextTimeBtn addTarget:self action:@selector(seeYouNextTime:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _skipNextTimeBtn;
}
- (UIImageView *)bottomImgView{
    if (!_bottomImgView) {
        _bottomImgView = [[UIImageView alloc]init];
        [_bottomImgView setImage:ImageSource(@"CC_Update_logo2")];
    }
    return _bottomImgView;
}
#pragma mark - Functions
- (void)update:(UIButton *)btn{
    self.updateBlock();
}
- (void)seeYouNextTime:(UIButton *)btn{
    self.skipBlock();
    [CC_UpdateView dismiss];
}
- (void)layoutSubviewsSnapKit{
    [self.ccLogoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(45.5);
        make.top.mas_equalTo(116);
        make.size.mas_equalTo(CGSizeMake(123.5, 33));
    }];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(45.5);
        make.top.equalTo(self.ccLogoView.mas_bottom).mas_offset(37);
        make.size.mas_equalTo(CGSizeMake(183, 23.5));
    }];
    [self.detailLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(45.5);
        make.right.mas_equalTo(-45.5);
        make.top.equalTo(self.titleLabel.mas_bottom).mas_offset(20);
        make.height.mas_equalTo(66);
    }];
    [self.updateBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(22);
        make.top.mas_equalTo(self.detailLabel.mas_bottom).mas_offset(57);
        make.size.mas_equalTo(CGSizeMake(201, 96));
        
    }];
    if (_showSkip) {
        [self.skipNextTimeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(45.5);
            make.top.mas_equalTo(self.updateBtn.mas_bottom).mas_offset(5);
            make.size.mas_equalTo(CGSizeMake(150, 25));
        }];
    }
    [self.bottomImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-32);
        make.bottom.mas_equalTo(-32);
        make.size.mas_equalTo(CGSizeMake(173, 149));
    }];
}
@end
