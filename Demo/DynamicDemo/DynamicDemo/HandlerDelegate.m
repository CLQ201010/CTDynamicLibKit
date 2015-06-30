//
//  HandlerDelegate.m
//  DynamicDemo
//
//  Created by casa on 6/30/15.
//  Copyright (c) 2015 casa. All rights reserved.
//

#import "HandlerDelegate.h"

@implementation HandlerDelegate

#pragma mark - CTDynamicLibManagerHandlerDelegate
- (void)dynamicLibMananger:(CTDynamicLibManager *)mananger didSuccessedRegistHandlerForBundle:(NSBundle *)bundle
{
    NSLog(@"success");
}

- (void)dynamicLibMananger:(CTDynamicLibManager *)mananger didFailedRegistHandlerForBundle:(NSBundle *)bundle error:(NSError *)error
{
    NSLog(@"failed");
}

- (void)dynamicLibMananger:(CTDynamicLibManager *)mananger
didSuccessedPerformHandler:(NSString *)handlerName
                 forBundle:(NSBundle *)bundle
                withParams:(NSDictionary *)params
         resultInformation:(NSDictionary *)resultInfo
{
    NSLog(@"success");
}

- (void)dynamicLibMananger:(CTDynamicLibManager *)mananger
   didFailedPerformHandler:(NSString *)handlerName
                 forBundle:(NSBundle *)bundle
                withParams:(NSDictionary *)params
                     error:(NSError *)error
{
    NSLog(@"failed");
}

@end
