//
//  LifeCycleDataSource.m
//  DynamicDemo
//
//  Created by casa on 6/30/15.
//  Copyright (c) 2015 casa. All rights reserved.
//

#import "LifeCycleDataSource.h"

@implementation LifeCycleDataSource

#pragma mark - CTDynamicLibManagerLifeCycleDataSource
- (NSArray *)coreDynamicLibsForDynamicLibMananger:(CTDynamicLibManager *)dynamicLibMananger
{
    return @[@"CTDynamicLibKit"];
}

@end
