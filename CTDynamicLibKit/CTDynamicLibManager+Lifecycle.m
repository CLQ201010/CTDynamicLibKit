//
//  CTDynamicLibManager+Lifecycle.m
//  CTDynamicLibKit
//
//  Created by casa on 6/30/15.
//  Copyright (c) 2015 casa. All rights reserved.
//

#import "CTDynamicLibManager+Lifecycle.h"
#import "CTDynamicLibManager+Handlers.h"
#import "CTDynamicLibKit.h"
#import <objc/runtime.h>

// error domain
NSString * const kCTDynamicLibManangerErrorDomainLifeCycle = @"CTDynamicLibMananger.lifecycle";

// package info file name
NSString * const kCTDynamicLibManangerPackageListFileName = @"CTDynamicLibPackageInfo.plist";

// property in category
static char kCTDynamicLibManangerProperty_LifeCycleDataSource[] = "kCTDynamicLibManangerProperty_LifeCycleDataSource";
static char kCTDynamicLibManangerProperty_LifeCycleDelegate[] = "kCTDynamicLibManangerProperty_LifeCycleDelegate";
static char kCTDynamicLibManangerProperty_PackageInfo[] = "kCTDynamicLibManangerProperty_PackageInfo";

// keys for package info when reading PackageInfo.plist
NSString * const kCTDynamicLibManangerPackageListKeyBundlePath = @"kCTDynamicLibManangerPackageListKeyBundlePath";

@interface CTDynamicLibManager ()

// recored the dynamic libraries in NSLibraryDirectory
@property (nonatomic, strong) NSMutableDictionary *packageInfo;

@end

@implementation CTDynamicLibManager (Lifecycle)

#pragma mark - public methods
- (void)loadDynamicLibs
{
    __block BOOL shouldLoadOtherLibBundle = NO;
    if (self.lifeCycleDataSource && [self.lifeCycleDataSource respondsToSelector:@selector(coreDynamicLibsForDynamicLibMananger:)]) {
        NSArray *coreLibNames = [self.lifeCycleDataSource coreDynamicLibsForDynamicLibMananger:self];
        [coreLibNames enumerateObjectsUsingBlock:^(NSString *bundleName, NSUInteger idx, BOOL *stop) {
            NSString *libBundlePath = [self latestBundlePathWithBundleName:bundleName];
            NSBundle *libBundle;
            NSError *error;
            
            if (libBundlePath) {
                libBundle = [NSBundle bundleWithPath:libBundlePath];
                if (libBundle && [libBundle loadAndReturnError:&error]) {
                    
                    shouldLoadOtherLibBundle = YES;
                    [self registHandlerFromDynamicLibBundle:libBundle error:&error];
                    
                    if (self.lifeCycleDelegate && [self.lifeCycleDelegate respondsToSelector:@selector(dynamicLibMananger:didSuccessedLoadBundle:)]) {
                        [self.lifeCycleDelegate dynamicLibMananger:self didSuccessedLoadBundle:libBundle];
                    }
                } else {
                    if (self.lifeCycleDelegate && [self.lifeCycleDelegate respondsToSelector:@selector(dynamicLibMananger:didFailedLoadBundleWithError:)]) {
                        [self.lifeCycleDelegate dynamicLibMananger:self didFailedLoadBundleWithError:error];
                    }
                }
            } else {
                error = [NSError errorWithDomain:kCTDynamicLibManangerErrorDomainLifeCycle
                                            code:CTDynamicLibManangerErrorCode_LoadLibBundleFail
                                        userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"can not find dynamic lib bundle for bundle name: %@", bundleName]}];
                if (self.lifeCycleDelegate && [self.lifeCycleDelegate respondsToSelector:@selector(dynamicLibMananger:didFailedLoadBundleWithError:)]) {
                    [self.lifeCycleDelegate dynamicLibMananger:self didFailedLoadBundleWithError:error];
                }
            }
        }];
    }
    
    if (shouldLoadOtherLibBundle) {
        [self.packageInfo enumerateKeysAndObjectsUsingBlock:^(NSString *bundleId, NSDictionary *packageInfo, BOOL *stop) {
            NSError *error;
            [self registHandlerFromDynamicLibPath:packageInfo[kCTDynamicLibManangerPackageListKeyBundlePath] error:&error];
            if (error) {
                if (self.lifeCycleDelegate && [self.lifeCycleDelegate respondsToSelector:@selector(dynamicLibMananger:didFailedLoadBundleWithError:)]) {
                    [self.lifeCycleDelegate dynamicLibMananger:self didFailedLoadBundleWithError:error];
                }
            }
        }];
    }
}

- (void)updateDynamicLibWithTmpPath:(NSString *)path
{
    NSBundle *testBundle = [NSBundle bundleWithPath:path];
    NSError *error;
    
    if (testBundle.bundleIdentifier) {
        NSString *targetPath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.framework", testBundle.bundleIdentifier]];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:targetPath]) {
            if (![[NSFileManager defaultManager] removeItemAtPath:targetPath error:&error]) {
                if (self.lifeCycleDelegate && [self.lifeCycleDelegate respondsToSelector:@selector(dynamicLibMananger:didFailedLoadBundleWithError:)]) {
                    [self.lifeCycleDelegate dynamicLibMananger:self didFailedLoadBundleWithError:error];
                }
                return;
            }
        }
        
        if ([[NSFileManager defaultManager] moveItemAtPath:path toPath:targetPath error:&error]) {
            if ([self registHandlerFromDynamicLibPath:targetPath error:&error]) {
                self.packageInfo[testBundle.bundleIdentifier] = @{kCTDynamicLibManangerPackageListKeyBundlePath:targetPath};
                [self.packageInfo writeToFile:[[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:kCTDynamicLibManangerPackageListFileName] atomically:YES];
                
                if (self.lifeCycleDelegate && [self.lifeCycleDelegate respondsToSelector:@selector(dynamicLibMananger:didSuccessedLoadBundle:)]) {
                    [self.lifeCycleDelegate dynamicLibMananger:self didSuccessedLoadBundle:testBundle];
                }
            } else {
                // failed to regist handler
                if (self.lifeCycleDelegate && [self.lifeCycleDelegate respondsToSelector:@selector(dynamicLibMananger:didFailedLoadBundleWithError:)]) {
                    [self.lifeCycleDelegate dynamicLibMananger:self didFailedLoadBundleWithError:error];
                }
            }
        } else {
            // failed to move to library path
            if (self.lifeCycleDelegate && [self.lifeCycleDelegate respondsToSelector:@selector(dynamicLibMananger:didFailedLoadBundleWithError:)]) {
                [self.lifeCycleDelegate dynamicLibMananger:self didFailedLoadBundleWithError:error];
            }
        }
    } else {
        error = [NSError errorWithDomain:kCTDynamicLibManangerErrorDomainLifeCycle
                                    code:CTDynamicLibManangerErrorCode_UpdateLibBundleFail
                                userInfo:@{
                                           NSLocalizedDescriptionKey:[NSString stringWithFormat:@"path[%@] is not availble to load as a dynamic lib bundle", path]
                                           }];
        if (self.lifeCycleDelegate && [self.lifeCycleDelegate respondsToSelector:@selector(dynamicLibMananger:didFailedLoadBundleWithError:)]) {
            [self.lifeCycleDelegate dynamicLibMananger:self didFailedLoadBundleWithError:error];
        }
    }
}

#pragma mark - private methods
- (NSString *)latestBundlePathWithBundleName:(NSString *)bundleName
{
    NSString *librarySystemPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    NSString *libraryPath = [librarySystemPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.framework", bundleName]];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:libraryPath]) {
        libraryPath = [[NSBundle mainBundle] pathForResource:bundleName ofType:@"framework"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:libraryPath]) {
            libraryPath = nil;
        }
    }
    
    return libraryPath;
}

#pragma mark - getters and setters
- (id<CTDynamicLibManagerLifeCycleDataSource>)lifeCycleDataSource
{
    return objc_getAssociatedObject(self, kCTDynamicLibManangerProperty_LifeCycleDataSource);
}

- (void)setLifeCycleDataSource:(id<CTDynamicLibManagerLifeCycleDataSource>)lifeCycleDataSource
{
    objc_setAssociatedObject(self, kCTDynamicLibManangerProperty_LifeCycleDataSource, lifeCycleDataSource, OBJC_ASSOCIATION_ASSIGN);
}

- (NSMutableDictionary *)packageInfo
{
    NSMutableDictionary *_packageInfo = objc_getAssociatedObject(self, kCTDynamicLibManangerProperty_PackageInfo);
    
    if (_packageInfo == nil) {
        NSString *packageInfoPath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:kCTDynamicLibManangerPackageListFileName];
        if ([[NSFileManager defaultManager] fileExistsAtPath:packageInfoPath]) {
            _packageInfo = [NSMutableDictionary dictionaryWithContentsOfFile:packageInfoPath];
        } else {
            _packageInfo = [[NSMutableDictionary alloc] init];
        }
        [self setPackageInfo:_packageInfo];
    }
    
    return _packageInfo;
}

- (void)setPackageInfo:(NSMutableDictionary *)packageInfo
{
    objc_setAssociatedObject(self, kCTDynamicLibManangerProperty_PackageInfo, packageInfo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id<CTDynamicLibManagerLifeCycleDelegate>)lifeCycleDelegate
{
    return objc_getAssociatedObject(self, kCTDynamicLibManangerProperty_LifeCycleDelegate);
}

- (void)setLifeCycleDelegate:(id<CTDynamicLibManagerLifeCycleDelegate>)lifeCycleDelegate
{
    objc_setAssociatedObject(self, kCTDynamicLibManangerProperty_LifeCycleDelegate, lifeCycleDelegate, OBJC_ASSOCIATION_ASSIGN);
}

@end
