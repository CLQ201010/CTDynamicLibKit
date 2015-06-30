//
//  CTDynamicLibManager+Lifecycle.m
//  CTDynamicLibKit
//
//  Created by casa on 6/30/15.
//  Copyright (c) 2015 casa. All rights reserved.
//

#import "CTDynamicLibManager+Lifecycle.h"
#import <objc/runtime.h>

// error domain
NSString * const kCTDynamicLibManangerErrorDomainLifeCycle = @"CTDynamicLibMananger.lifecycle";

// package info file name
NSString * const kCTDynamicLibManangerPackageListFileName = @"CTDynamicLibPackageInfo.plist";

// property in category
static const void *kCTDynamicLibManangerProperty_LifeCycleDataSource;
static const void *kCTDynamicLibManangerProperty_LifeCycleDelegate;
static const void *kCTDynamicLibManangerProperty_LoadedBundles;
static const void *kCTDynamicLibManangerProperty_PackageInfo;

// keys for package info when reading PackageInfo.plist
NSString * const kCTDynamicLibManangerPackageListKeyBundleName = @"kCTDynamicLibManangerPackageListKeyBundleName";
NSString * const kCTDynamicLibManangerPackageListKeyBundlePath = @"kCTDynamicLibManangerPackageListKeyBundlePath";
NSString * const kCTDynamicLibManangerPackageListKeyIsCoreBundle = @"kCTDynamicLibManangerPackageListKeyIsCoreBundle";

@interface CTDynamicLibManager ()

@property (nonatomic, strong) NSMutableDictionary *loadedBundles;
@property (nonatomic, strong) NSMutableDictionary *packageInfo;

@end

@implementation CTDynamicLibManager (Lifecycle)

#pragma mark - public methods
- (void)loadDefaultDynamicLibs
{
    if (self.lifeCycleDataSource && [self.lifeCycleDataSource respondsToSelector:@selector(coreDynamicLibsForDynamicLibMananger:)]) {
        NSArray *coreLibNames = [self.lifeCycleDataSource coreDynamicLibsForDynamicLibMananger:self];
        [coreLibNames enumerateObjectsUsingBlock:^(NSString *bundleName, NSUInteger idx, BOOL *stop) {
            NSBundle *libBundle = [self latestBundleWithBundleName:bundleName];
            NSError *error;
            [libBundle loadAndReturnError:&error];
        }];
    }
}

- (void)updateDynamicLibWithTmpPath:(NSString *)path
{
    
}

#pragma mark - private methods
- (NSBundle *)latestBundleWithBundleName:(NSString *)bundleName
{
    NSBundle *resultBundle;
    NSString *libraryPath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.framework", bundleName]];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:libraryPath]) {
        libraryPath = [[NSBundle mainBundle] pathForResource:bundleName ofType:@"framework"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:libraryPath]) {
            libraryPath = nil;
        }
    }
    
    resultBundle = [NSBundle bundleWithPath:libraryPath];
    return resultBundle;
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

- (NSMutableDictionary *)loadedBundles
{
    NSMutableDictionary *_loadedBundles = objc_getAssociatedObject(self, kCTDynamicLibManangerProperty_LoadedBundles);
    if (_loadedBundles == nil) {
        _loadedBundles = [[NSMutableDictionary alloc] init];
        [self setLoadedBundles:_loadedBundles];
    }
    return _loadedBundles;
}

- (void)setLoadedBundles:(NSMutableDictionary *)loadedBundles
{
    objc_setAssociatedObject(self, kCTDynamicLibManangerProperty_LoadedBundles, loadedBundles, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
