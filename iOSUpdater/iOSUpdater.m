//
//  iOSUpdater.m
//  iOSUpdaterDemo
//
//  Created by Apple on 2019/12/10.
//  Copyright © 2019 Apple. All rights reserved.
//

#import "iOSUpdater.h"

#define Decoder(x) [NSJSONSerialization JSONObjectWithData:x options:NSJSONReadingAllowFragments error:nil]
@interface iOSUpdater()

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
- (void)checkVersion {
    if (!_window) {
        NSLog(@"[iOSUpdater]: Please make sure that you have set _presentationViewController before calling checkVersion, checkVersionDaily, or checkVersionWeekly.");
    } else {
        [self performVersionCheck];
    }
}
#pragma mark - Helpers
- (void)performVersionCheck {
    NSURL *storeURL = [self itunesURL];
    storeURL = [NSURL URLWithString:@"https://itunes.apple.com/cn/lookup?id=xxwolo.com.master"];
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

            // Store version comparison date
//            weakSelf.lastVersionCheckPerformedOnDate = [NSDate date];
//            [[NSUserDefaults standardUserDefaults] setObject:[self lastVersionCheckPerformedOnDate] forKey:HarpyDefaultStoredVersionCheckDate];
//            [[NSUserDefaults standardUserDefaults] synchronize];
            NSDictionary<NSString *, id> *results = [self.appData valueForKey:@"results"];

            /**
             Checks to see when the latest version of the app was released.
             If the release date is greater-than-or-equal-to `_showAlertAfterCurrentVersionHasBeenReleasedForDays`,
             the user will prompted to update their app (if the version is newer - checked later on in this method).
             */

            NSString *releaseDateString = [[results valueForKey:@"currentVersionReleaseDate"] objectAtIndex:0];
            if (releaseDateString == nil) {
                return;
            } else {
//                NSInteger daysSinceRelease = [weakSelf daysSinceDateString:releaseDateString];
//                if (!(daysSinceRelease >= weakSelf.showAlertAfterCurrentVersionHasBeenReleasedForDays)) {
//                    NSString *message = [NSString stringWithFormat:@"Your app has been released for %ld days, but Harpy cannot prompt the user until %lu days have passed.", (long)daysSinceRelease, (unsigned long)weakSelf.showAlertAfterCurrentVersionHasBeenReleasedForDays];
//                    [self printDebugMessage:message];
//                    return;
//                }
            }

            /**
             Current version that has been uploaded to the AppStore.
             Used to contain all versions, but now only contains the latest version.
             Still returns an instance of NSArray.
             */

            NSArray *versionsInAppStore = [results valueForKey:@"version"];
            if (versionsInAppStore == nil) {
                return;
            } else {
                if ([versionsInAppStore count]) {
                    weakSelf.appStoreVersion = [versionsInAppStore objectAtIndex:0];
                    if ([weakSelf isAppStoreVersionNewer:weakSelf.appStoreVersion]) {
                        [weakSelf appStoreVersionIsNewer:weakSelf.appStoreVersion];
                    } else {
//                        [self printDebugMessage:@"Currently installed version is newer."];//mahp
                    }
                }
            }
        });
    } else {
//        [self printDebugMessage:@"Device is incompatible with installed verison of iOS."];//mahp
    }
}
- (NSURL *)itunesURL {
    NSURLComponents *components = [NSURLComponents new];
    components.scheme = @"https";
    components.host = @"itunes.apple.com";
    components.path = @"/cn/lookup";

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
        [self printDebugMessage:@"appID is nil, which means to the trackId key is missing from the JSON results that Apple returned for your bundleID. If a version of your app is in the store and you are seeing this message, please open up an issue http://github.com/ArtSabintsev/Harpy and provide as much detail about your app as you can. Thanks!"];
    } else {
        [self localizeAlertStringsForCurrentAppStoreVersion:currentAppStoreVersion];
        [self alertTypeForVersion:currentAppStoreVersion];
        [self showAlertIfCurrentAppStoreVersionNotSkipped:currentAppStoreVersion];
    }
}
#pragma mark - Logging

- (void)printDebugMessage:(NSString * _Nonnull)message {
    #ifdef DEBUG
         NSLog(@"[Harpy]: %@", message);
    #else
        //do sth.
    #endif
}
#pragma mark - Alert Management
- (void)showAlertIfCurrentAppStoreVersionNotSkipped:(NSString *)currentAppStoreVersion {//mahp
    // Check if user decided to skip this version in the past
//    NSString *storedSkippedVersion = [[NSUserDefaults standardUserDefaults] objectForKey:HarpyDefaultSkippedVersion];
//
//    if (![storedSkippedVersion isEqualToString:currentAppStoreVersion]) {
//        [self showAlertWithAppStoreVersion:currentAppStoreVersion];
//    } else {
//        // Don't show alert.
//        return;
//    }
}

- (void)showAlertWithAppStoreVersion:(NSString *)currentAppStoreVersion {
    // Show Appropriate UIAlertView
    switch ([self alertType]) {

        case UpdaterAlertTypeForce: {

//            UIAlertController *alertController = [self createAlertController];
//            [alertController addAction:[self updateAlertAction]];
//
//            [self showAlertController:alertController];

        } break;

        case UpdaterAlertTypeOption: {

//            UIAlertController *alertController = [self createAlertController];
//            [alertController addAction:[self nextTimeAlertAction]];
//            [alertController addAction:[self updateAlertAction]];

//            [self showAlertController:alertController];

        } break;

//        case HarpyAlertTypeSkip: {
//
//            UIAlertController *alertController = [self createAlertController];
////            [alertController addAction:[self skipAlertAction]];
////            [alertController addAction:[self nextTimeAlertAction]];
////            [alertController addAction:[self updateAlertAction]];
//
//            [self showAlertController:alertController];
//
//        } break;

        case UpdaterAlertTypeNone: { //If the delegate is set, pass a localized update message. Otherwise, do nothing.
//            if ([self.delegate respondsToSelector:@selector(harpyDidDetectNewVersionWithoutAlert:)]) {
//                [self.delegate harpyDidDetectNewVersionWithoutAlert:_theNewVersionMessage];
//            }
        } break;
    }
}

- (void)showAlertController:(UIAlertController *)alertController {

    if (_window != nil) {
//        [_window presentViewController:alertController animated:YES completion:nil];
//
//        if (_alertControllerTintColor) {
//            [alertController.view setTintColor:_alertControllerTintColor];
//        }
    }

//    if ([self.delegate respondsToSelector:@selector(harpyDidShowUpdateDialog)]){
//        [self.delegate harpyDidShowUpdateDialog];
//    }
}


- (void)alertTypeForVersion:(NSString *)currentAppStoreVersion {
    // Check what version the update is, major, minor or a patch
    NSArray *oldVersionComponents = [[self installedVersion] componentsSeparatedByString:@"."];
    NSArray *newVersionComponents = [currentAppStoreVersion componentsSeparatedByString: @"."];

    BOOL oldVersionComponentIsProperFormat = (2 <= [oldVersionComponents count] && [oldVersionComponents count] <= 4);
    BOOL newVersionComponentIsProperFormat = (2 <= [newVersionComponents count] && [newVersionComponents count] <= 4);

//    if (oldVersionComponentIsProperFormat && newVersionComponentIsProperFormat) {
//        if ([newVersionComponents[0] integerValue] > [oldVersionComponents[0] integerValue]) { // A.b.c.d
//            if (_majorUpdateAlertType) _alertType = _majorUpdateAlertType;
//        } else if ([newVersionComponents[1] integerValue] > [oldVersionComponents[1] integerValue]) { // a.B.c.d
//            if (_minorUpdateAlertType) _alertType = _minorUpdateAlertType;
//        } else if ((newVersionComponents.count > 2) && (oldVersionComponents.count <= 2 || ([newVersionComponents[2] integerValue] > [oldVersionComponents[2] integerValue]))) { // a.b.C.d
//            if (_patchUpdateAlertType) _alertType = _patchUpdateAlertType;
//        } else if ((newVersionComponents.count > 3) && (oldVersionComponents.count <= 3 || ([newVersionComponents[3] integerValue] > [oldVersionComponents[3] integerValue]))) { // a.b.c.D
//            if (_revisionUpdateAlertType) _alertType = _revisionUpdateAlertType;
//        }
//    }
}

- (void)localizeAlertStringsForCurrentAppStoreVersion:(NSString *)currentAppStoreVersion {
    // Reference App's name
    _appName = _appName ? _appName : [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];

    // Force localization if _forceLanguageLocalization is set
//    if (_forceLanguageLocalization) {
//        _updateAvailableMessage = [self forcedLocalizedStringForKey:@"Update Available"];
//        _theNewVersionMessage = [NSString stringWithFormat:[self forcedLocalizedStringForKey:@"A new version of %@ is available. Please update to version %@ now."], _appName, currentAppStoreVersion];
//        _updateButtonText = [self forcedLocalizedStringForKey:@"Update"];
//        _nextTimeButtonText = [self forcedLocalizedStringForKey:@"Next time"];
//        _skipButtonText = [self forcedLocalizedStringForKey:@"Skip this version"];
//    } else {
//        _updateAvailableMessage = [self localizedStringForKey:@"Update Available"];
//        _theNewVersionMessage = [NSString stringWithFormat:[self localizedStringForKey:@"A new version of %@ is available. Please update to version %@ now."], _appName, currentAppStoreVersion];
//        _updateButtonText = [self localizedStringForKey:@"Update"];
//        _nextTimeButtonText = [self localizedStringForKey:@"Next time"];
//        _skipButtonText = [self localizedStringForKey:@"Skip this version"];
//    }
}

@end
