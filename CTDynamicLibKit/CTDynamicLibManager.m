//
//  CTDynamicLibManager.m
//  CTDynamicLibKit
//
//  Created by casa on 6/29/15.
//  Copyright (c) 2015 casa. All rights reserved.
//

#import "CTDynamicLibManager.h"

@implementation CTDynamicLibManager

+ (instancetype)sharedInstance
{
    static CTDynamicLibManager *_dynamicLibMananger;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dynamicLibMananger = [[CTDynamicLibManager alloc] init];
    });
    return _dynamicLibMananger;
}

@end
