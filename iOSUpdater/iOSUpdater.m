//
//  iOSUpdater.m
//  iOSUpdaterDemo
//
//  Created by Mahp on 2019/12/10.
//  Copyright © 2019 Mahp. All rights reserved.
//

#import "iOSUpdater.h"
#import "CC_UpdateView.h"
#define Decoder(x) [NSJSONSerialization JSONObjectWithData:x options:NSJSONReadingAllowFragments error:nil]
NSString * const SkippedVersionDayTime         = @"User Decided To Skip Version Update Interval";
#define UserDefaults [NSUserDefaults standardUserDefaults]
@interface iOSUpdater()
@property (nonatomic, assign) UpdaterAlertType alertType;
@property (nonatomic, copy) NSString *installedVersion;
@property (nonatomic, copy) NSString *appStoreVersion;
@property (nonatomic, copy) NSString *appID;
@property (nonatomic, strong) NSDictionary <NSString *, id> *appData;//mahp

@end


@implementation iOSUpdater

#pragma mark - Initialization

+ (iOSUpdater *)shareInstance{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}
- (id)init {
    self = [super init];
    if (self) {
        _alertType = UpdaterAlertTypeOption;
        _installedVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    }
    return self;
}
#pragma mark - PublicFunctions
- (void)checkVersionType:(UpdaterAlertType)type{
    _alertType = type;
    if (type == UpdaterAlertTypeNone) {
        return;
    }
    if (!_window) {
        NSLog(@"[iOSUpdater]: Please make sure that you have set _presentationViewController before calling checkVersion, checkVersionDaily, or checkVersionWeekly.");
    } else {
        [self performVersionCheck];
    }
}
#pragma mark - Helpers
- (void)performVersionCheck {
    NSURL *storeURL = [self itunesURL];
//    storeURL = [NSURL URLWithString:@"https://itunes.apple.com/lookup?bundleId=com.cecelive.master"];
    NSURLRequest *request = [NSMutableURLRequest requestWithURL:storeURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                if ([data length] > 0 && !error) { // Success
                                                    [self parseResults:data];
                                                }
                                            }];
    [task resume];
}
- (void)parseResults:(NSData *)data {
    _appData = Decoder(data);
    if ([self isUpdateCompatibleWithDeviceOS:_appData]) {
        __typeof__(self) __weak weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary<NSString *, id> *results = [self.appData valueForKey:@"results"];
            NSString *releaseDateString = [[results valueForKey:@"currentVersionReleaseDate"] objectAtIndex:0];
            if (releaseDateString == nil) {
                return;
            }
            NSArray *versionsInAppStore = [results valueForKey:@"version"];
            if (versionsInAppStore == nil) {
                return;
            } else {
                if ([versionsInAppStore count]) {
                    weakSelf.appStoreVersion = [versionsInAppStore objectAtIndex:0];
                    if ([weakSelf isAppStoreVersionNewer:weakSelf.appStoreVersion]) {
                        [weakSelf appStoreVersionIsNewer:weakSelf.appStoreVersion];
                    }else{
                        [self printDebugMessage:@"installed is newer"];//mahp
                    }
                }
            }
        });
    } else {
        [self printDebugMessage:@"Device is incompatible with installed verison of iOS."];//mahp
    }
}
- (NSURL *)itunesURL {
    NSURLComponents *components = [NSURLComponents new];
    components.scheme = @"https";
    components.host = @"itunes.apple.com";
    components.path = @"/lookup";

    NSMutableArray<NSURLQueryItem *> *items = [@[[NSURLQueryItem queryItemWithName:@"bundleId" value:[NSBundle mainBundle].bundleIdentifier]] mutableCopy];
    components.queryItems = items;
    return components.URL;
}
- (BOOL)isUpdateCompatibleWithDeviceOS:(NSDictionary<NSString *, id> *)appData {
    NSArray<NSDictionary<NSString *, id> *> *results = appData[@"results"];
    if (results.count > 0) {
        NSString *requiresOSVersion = [results firstObject][@"minimumOsVersion"];
        if (requiresOSVersion != nil) {
            NSString *systemVersion = [UIDevice currentDevice].systemVersion;
            if (([systemVersion compare:requiresOSVersion options:NSNumericSearch] == NSOrderedDescending) ||
                ([systemVersion compare:requiresOSVersion options:NSNumericSearch] == NSOrderedSame)) {
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    } else {
        return false;
    }
}
- (BOOL)isAppStoreVersionNewer:(NSString *)currentAppStoreVersion {
    // Current installed version is the newest public version or newer (e.g., dev version)
    if ([[self installedVersion] compare:currentAppStoreVersion options:NSNumericSearch] == NSOrderedAscending) {
        return true;
    } else {
        return false;
    }
}
- (void)appStoreVersionIsNewer:(NSString *)currentAppStoreVersion {
    _appID = _appData[@"results"][0][@"trackId"];

    if (_appID == nil) {
        [self printDebugMessage:@"appID is nil"];
    } else {
        NSString * skipTime = [UserDefaults stringForKey:SkippedVersionDayTime];
        if ((skipTime.length && [skipTime compare:[self TodayString]] == NSOrderedAscending) || skipTime == nil ||_alertType == UpdaterAlertTypeForce) {
             __typeof__(self) __weak weakSelf = self;
             BOOL skip = _alertType == UpdaterAlertTypeForce ? NO :YES;
             [CC_UpdateView showUpdateViewSkip:skip UpdateBlock:^{
                 [self launchAppStore];
             } SkipBlock:^{
                 [UserDefaults setValue:[weakSelf TodayString] forKey:SkippedVersionDayTime];
                 [UserDefaults synchronize];
             }];
        }
    }
}
- (NSString *)TodayString{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYYMMdd"];
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"Asia/Shanghai"]];

    NSString *currentTimeString = [formatter stringFromDate:[NSDate date]];
    return currentTimeString;
}
#pragma mark - Logging

- (void)printDebugMessage:(NSString * _Nonnull)message {
    #ifdef DEBUG
         NSLog(@"[iOSUpdater]: %@", message);
    #else
        //do sth.
    #endif
}
#pragma mark - Alert Management

- (void)launchAppStore {
    NSString *iTunesString = [NSString stringWithFormat:@"https://itunes.apple.com/app/id%@", [self appID]];
    NSURL *iTunesURL = [NSURL URLWithString:iTunesString];

    dispatch_async(dispatch_get_main_queue(), ^{
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:iTunesURL options:@{} completionHandler:nil];
        } else {
            [[UIApplication sharedApplication] openURL:iTunesURL];
        }
    });
}




@end
