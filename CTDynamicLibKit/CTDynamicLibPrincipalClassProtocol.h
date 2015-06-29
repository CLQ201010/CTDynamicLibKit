//
//  CTDynamicLibPrincipalClassProtocol.h
//  CTDynamicLibKit
//
//  Created by casa on 6/29/15.
//  Copyright (c) 2015 casa. All rights reserved.
//

#ifndef CTDynamicLibKit_CTDynamicLibPrincipalClassProtocol_h
#define CTDynamicLibKit_CTDynamicLibPrincipalClassProtocol_h

@class NSString;
@class NSDictionary;
@class NSError;

@protocol CTDynamicLibPrincipalClassProtocol <NSObject>

@required

+ (instancetype)sharedInstance;

- (void)performHandler:(NSString *)handler
            withParams:(NSDictionary *)params
    processingCallback:(NSDictionary *(^)(NSDictionary *))processingCallback
            completion:(void (^)(NSDictionary *, NSError *))completion;

@end

#endif
