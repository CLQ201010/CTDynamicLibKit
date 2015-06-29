//
//  CTDynamicLibManager+Handlers.m
//  CTDynamicLibKit
//
//  Created by casa on 6/29/15.
//  Copyright (c) 2015 casa. All rights reserved.
//

#import "CTDynamicLibManager+Handlers.h"
#import "CTDynamicLibKit.h"
#import <objc/runtime.h>

// error domain
NSString * const kCTDynamicLibManangerErrorDomainHandler = @"CTDynamicLibMananger.handler";

// property in category
static const void *kCTDynamicLibManangerProperty_RegistedHandlers;
static const void *kCTDynamicLibManangerProperty_HandlerDelegate;

@interface CTDynamicLibManager ()

@property (nonatomic, strong) NSMutableDictionary *registedHandlers;

@end

@implementation CTDynamicLibManager (Handlers)

#pragma mark - public methods
- (BOOL)registHandler:(NSString *)handler
            forTarget:(id<CTDynamicLibPrincipalClassProtocol>)target
            withError:(NSError *__autoreleasing *)error
{
    BOOL result = YES;
    if (handler && target
        && [handler isKindOfClass:[NSString class]] && [target respondsToSelector:@selector(performHandler:withParams:processingCallback:completion:)]
        && handler.length > 0){
            self.registedHandlers[handler] = target;
    } else {
        result = NO;
        __autoreleasing NSError *generatedError = [NSError errorWithDomain:kCTDynamicLibManangerErrorDomainHandler
                                                                      code:CTDynamicLibManangerErrorCode_RegistHandlerFail
                                                                  userInfo:@{
                                                                             NSLocalizedDescriptionKey:[NSString stringWithFormat:@"failed to regist handler[%@] in target[%@]", handler, [target class]],
                                                                             NSLocalizedRecoverySuggestionErrorKey:[NSString stringWithFormat:@"check handler name is NSString and is not nil, check the target[%@] is responds to selector[%@].", [target class], NSStringFromSelector(@selector(performHandler:withParams:processingCallback:completion:))]
                                                                             }];
        error = &generatedError;
        if ([self.handlerDelegate respondsToSelector:@selector(dynamicLibMananger:didFailedRegistHandler:forTarget:error:)]) {
            [self.handlerDelegate dynamicLibMananger:self didFailedRegistHandler:handler forTarget:nil error:generatedError];
        }
    }
    
    return result;
}

- (void)performHandler:(NSString *)handler
{
    [self performHandler:handler withParams:nil processingCallback:nil completion:nil];
}

- (void)performHandler:(NSString *)handler processingCallback:(NSDictionary *(^)(NSDictionary *))processingCallback
{
    [self performHandler:handler withParams:nil processingCallback:processingCallback completion:nil];
}

- (void)performHandler:(NSString *)handler completion:(void (^)(NSDictionary *, NSError *))completion
{
    [self performHandler:handler withParams:nil processingCallback:nil completion:completion];
}

- (void)performHandler:(NSString *)handler withParams:(NSDictionary *)params
{
    [self performHandler:handler withParams:params processingCallback:nil completion:nil];
}

- (void)performHandler:(NSString *)handler withParams:(NSDictionary *)params processingCallback:(NSDictionary *(^)(NSDictionary *))processingCallback
{
    [self performHandler:handler withParams:params processingCallback:processingCallback completion:nil];
}

- (void)performHandler:(NSString *)handler withParams:(NSDictionary *)params completion:(void (^)(NSDictionary *, NSError *))completion
{
    [self performHandler:handler withParams:params processingCallback:nil completion:nil];
}

- (void)performHandler:(NSString *)handler withParams:(NSDictionary *)params processingCallback:(NSDictionary *(^)(NSDictionary *))processingCallback completion:(void (^)(NSDictionary *, NSError *))completion
{
    // param checking
    if (!handler) {
        NSError *error = [NSError errorWithDomain:kCTDynamicLibManangerErrorDomainHandler
                                             code:CTDynamicLibManangerErrorCode_PerformHandlerFail
                                         userInfo:@{
                                                    NSLocalizedDescriptionKey:[NSString stringWithFormat:@"handler can not be nil"]
                                                    }];
        if ([self.handlerDelegate respondsToSelector:@selector(dynamicLibMananger:didFailedPerformHandler:forTarget:withParams:error:)]) {
            [self.handlerDelegate dynamicLibMananger:self didFailedPerformHandler:handler forTarget:nil withParams:params error:error];
        }
        if (completion) {
            completion(nil, error);
        }
    }
    
    id<CTDynamicLibPrincipalClassProtocol> target = self.registedHandlers[handler];
    if (target && [target respondsToSelector:@selector(performHandler:withParams:processingCallback:completion:)]) {
        __weak typeof(self) weakSelf = self;
        void(^completionCallback)(NSDictionary *resultInfo, NSError *error) = ^(NSDictionary *resultInfo, NSError *error){
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (error) {
                if (strongSelf && [strongSelf.handlerDelegate respondsToSelector:@selector(dynamicLibMananger:didFailedPerformHandler:forTarget:withParams:error:)]) {
                    [strongSelf.handlerDelegate dynamicLibMananger:strongSelf didFailedPerformHandler:handler forTarget:target withParams:params error:error];
                }
            } else {
                if (strongSelf && [strongSelf.handlerDelegate respondsToSelector:@selector(dynamicLibMananger:didSuccessedPerformHandler:forTarget:withParams:resultInformation:)]) {
                    [strongSelf.handlerDelegate dynamicLibMananger:strongSelf didSuccessedPerformHandler:handler forTarget:target withParams:params resultInformation:resultInfo];
                }
            }
            
            if (completion) {
                completion(resultInfo, error);
            }
        };
        
        [target performHandler:handler withParams:params processingCallback:processingCallback completion:completionCallback];
        
    } else {
        NSError *error = [NSError errorWithDomain:kCTDynamicLibManangerErrorDomainHandler
                                             code:CTDynamicLibManangerErrorCode_PerformHandlerFail
                                         userInfo:@{
                                                    NSLocalizedDescriptionKey:[NSString stringWithFormat:@"target[%@] is not available for calling handler [%@]", [target class], handler],
                                                    NSLocalizedRecoverySuggestionErrorKey:[NSString stringWithFormat:@"check target[%@] is responds to selector[%@]", [target class], NSStringFromSelector(@selector(performHandler:withParams:processingCallback:completion:))]
                                                    }];
        if ([self.handlerDelegate respondsToSelector:@selector(dynamicLibMananger:didFailedPerformHandler:forTarget:withParams:error:)]) {
            [self.handlerDelegate dynamicLibMananger:self didFailedPerformHandler:handler forTarget:nil withParams:params error:error];
        }
        if (completion) {
            completion(nil, error);
        }
    }
}

#pragma mark - getters and setters
- (NSMutableDictionary *)registedHandlers
{
    NSMutableDictionary *_registedHandlers = objc_getAssociatedObject(self, kCTDynamicLibManangerProperty_RegistedHandlers);
    if (_registedHandlers == nil) {
        _registedHandlers = [[NSMutableDictionary alloc] init];
        [self setRegistedHandlers:_registedHandlers];
    }
    return _registedHandlers;
}

- (void)setRegistedHandlers:(NSMutableDictionary *)registedHandlers
{
    objc_setAssociatedObject(self, kCTDynamicLibManangerProperty_RegistedHandlers, registedHandlers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id<CTDynamicLibManagerHandlerDelegate>)handlerDelegate
{
    return objc_getAssociatedObject(self, kCTDynamicLibManangerProperty_HandlerDelegate);
}

- (void)setHandlerDelegate:(id<CTDynamicLibManagerHandlerDelegate>)handlerDelegate
{
    objc_setAssociatedObject(self, kCTDynamicLibManangerProperty_HandlerDelegate, handlerDelegate, OBJC_ASSOCIATION_ASSIGN);
}

@end
