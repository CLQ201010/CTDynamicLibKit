//
//  LifeCycleDelegate.m
//  DynamicDemo
//
//  Created by casa on 6/30/15.
//  Copyright (c) 2015 casa. All rights reserved.
//

#import "LifeCycleDelegate.h"

@implementation LifeCycleDelegate

#pragma mark - CTDynamicLibManagerLifeCycleDelegate
- (void)dynamicLibMananger:(CTDynamicLibManager *)dynamicLibMananger didSuccessedLoadBundle:(NSBundle *)bundle
{
    NSLog(@"success");
}

- (void)dynamicLibMananger:(CTDynamicLibManager *)dynamicLibMananger didFailedLoadBundleWithError:(NSError *)error
{
    NSLog(@"failed");
}


- (void)dynamicLibMananger:(CTDynamicLibManager *)dynamicLibMananger didSuccessedUpdateBundleAtPath:(NSString *)bundlePath tmpPath:(NSString *)tmpPath
{
    NSLog(@"success");
}

- (void)dynamicLibMananger:(CTDynamicLibManager *)dynamicLibMananger didFailedUpdateBundleAtPath:(NSString *)bundlePath tmpPath:(NSString *)tmpPath error:(NSError *)error
{
    NSLog(@"failed");
}

@end
