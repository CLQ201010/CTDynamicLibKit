//
//  CTDynamicLibManager+Handlers.h
//  CTDynamicLibKit
//
//  Created by casa on 6/29/15.
//  Copyright (c) 2015 casa. All rights reserved.
//

#import "CTDynamicLibManager.h"
#import "CTDynamicLibPrincipalClassProtocol.h"

@protocol CTDynamicLibManagerHandlerDelegate;

@interface CTDynamicLibManager (Handlers)

@property (nonatomic, assign) id<CTDynamicLibManagerHandlerDelegate> handlerDelegate;

// you should regist handler before you call a handler
- (BOOL)registHandlerFromDynamicLibPath:(NSString *)dynamicLibPath error:(NSError **)error;

- (BOOL)registHandlerFromDynamicLibBundle:(NSBundle *)dynamicLibBundle error:(NSError **)error;

- (NSDictionary *)allHandlers;

- (void)removeHandler:(NSString *)handlerName;

- (void)removeHandlersOfTarget:(id<CTDynamicLibPrincipalClassProtocol>)target;

// methods to perform handler.
- (void)performHandler:(NSString *)handler;

- (void)performHandler:(NSString *)handler
            withParams:(NSDictionary *)params;

- (void)performHandler:(NSString *)handler
    processingCallback:(NSDictionary *(^)(NSDictionary *processingInfo))processingCallback;

- (void)performHandler:(NSString *)handler
            completion:(void(^)(NSDictionary *resultInfo, NSError *error))completion;

- (void)performHandler:(NSString *)handler
            withParams:(NSDictionary *)params
    processingCallback:(NSDictionary *(^)(NSDictionary *processingInfo))processingCallback;

- (void)performHandler:(NSString *)handler
            withParams:(NSDictionary *)params
            completion:(void(^)(NSDictionary *resultInfo, NSError *error))completion;

- (void)performHandler:(NSString *)handler
            withParams:(NSDictionary *)params
    processingCallback:(NSDictionary *(^)(NSDictionary *processingInfo))processingCallback
            completion:(void(^)(NSDictionary *resultInfo, NSError *error))completion;

@end

@protocol CTDynamicLibManagerHandlerDelegate <NSObject>

@optional
- (void)dynamicLibMananger:(CTDynamicLibManager *)mananger didSuccessedRegistHandlerForBundle:(NSBundle *)bundle;

- (void)dynamicLibMananger:(CTDynamicLibManager *)mananger didFailedRegistHandlerForBundle:(NSBundle *)bundle error:(NSError *)error;

- (void)dynamicLibMananger:(CTDynamicLibManager *)mananger
didSuccessedPerformHandler:(NSString *)handlerName
                 forBundle:(NSBundle *)bundle
                withParams:(NSDictionary *)params
         resultInformation:(NSDictionary *)resultInfo;

- (void)dynamicLibMananger:(CTDynamicLibManager *)mananger
   didFailedPerformHandler:(NSString *)handlerName
                 forBundle:(NSBundle *)bundle
                withParams:(NSDictionary *)params
                     error:(NSError *)error;

@end
