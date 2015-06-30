//
//  CTDynamicLibKit.h
//  CTDynamicLibKit
//
//  Created by casa on 6/29/15.
//  Copyright (c) 2015 casa. All rights reserved.
//

#import <UIKit/UIKit.h>

// error code enum
typedef NS_ENUM(NSUInteger, CTDynamicLibManangerErrorCode) {
    CTDynamicLibManangerErrorCode_RegistHandlerFail,
    CTDynamicLibManangerErrorCode_PerformHandlerFail,
    CTDynamicLibManangerErrorCode_LoadLibBundleFail,
    CTDynamicLibManangerErrorCode_UpdateLibBundleFail
};

// error domain
extern NSString * const kCTDynamicLibManangerErrorDomainHandler;
extern NSString * const kCTDynamicLibManangerErrorDomainLifeCycle;


#import <CTDynamicLibKit/CTDynamicLibManager.h>
#import <CTDynamicLibKit/CTDynamicLibManager+Handlers.h>
#import <CTDynamicLibKit/CTDynamicLibManager+Lifecycle.h>
#import <CTDynamicLibKit/CTDynamicLibPrincipalClassProtocol.h>
