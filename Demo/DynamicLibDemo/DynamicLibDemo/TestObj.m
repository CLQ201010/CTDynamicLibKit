//
//  TestObj.m
//  DynamicLibDemo
//
//  Created by casa on 6/24/15.
//  Copyright (c) 2015 casa. All rights reserved.
//

#import "TestObj.h"

@implementation TestObj

#pragma mark - CTDynamicLibPrincipalClassProtocol
+ (instancetype)sharedInstance
{
    static TestObj *_testObj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _testObj = [[TestObj alloc] init];
    });
    return _testObj;
}

- (void)performHandler:(NSString *)handler
            withParams:(NSDictionary *)params
    processingCallback:(NSDictionary *(^)(NSDictionary *))processingCallback
            completion:(void (^)(NSDictionary *, NSError *))completion
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"casa" message:@"casa" delegate:nil cancelButtonTitle:@"cancel" otherButtonTitles:nil];
    [alert show];
    
    if (completion) {
        completion(@{@"key1":@"value1"}, nil);
    }
}

@end

__attribute__((destructor))
static void destructor()
{
    [[CTDynamicLibManager sharedInstance] removeHandlersOfTarget:[TestObj sharedInstance]];
}
