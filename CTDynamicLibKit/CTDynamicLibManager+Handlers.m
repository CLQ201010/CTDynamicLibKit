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

// keys for handler when reading info.plist
NSString * const kCTDynamicLibManangerInfoPlistKeyRegistedHandlers = @"Registed Handlers";

// keys in registedHandlers
NSString * const kCTDynamicLibManangerRegistedHandlersKeyBundle = @"kCTDynamicLibManangerRegistedHandlersKeyBundle";
NSString * const kCTDynamicLibManangerRegistedHandlersKeyPerformTarget = @"kCTDynamicLibManangerRegistedHandlersKeyPerformTarget";

@interface CTDynamicLibManager ()

@property (nonatomic, strong) NSMutableDictionary *registedHandlers;

@end

@implementation CTDynamicLibManager (Handlers)

#pragma mark - public methods
- (BOOL)registHandlerFromDynamicLibPath:(NSString *)dynamicLibPath error:(NSError *__autoreleasing *)error
{
    BOOL result = YES;
    __autoreleasing NSError *generatedError = nil;
    
    if (dynamicLibPath && dynamicLibPath.length > 0) {
        NSBundle *bundle = [NSBundle bundleWithPath:dynamicLibPath];
        if (bundle) {
            NSArray *registedHandlers = bundle.infoDictionary[kCTDynamicLibManangerInfoPlistKeyRegistedHandlers];
            [registedHandlers enumerateObjectsUsingBlock:^(NSString *handler, NSUInteger idx, BOOL *stop) {
                if (self.registedHandlers[handler]) {
                    NSBundle *registedBundle = self.registedHandlers[handler][kCTDynamicLibManangerRegistedHandlersKeyBundle];
                    if (registedBundle.loaded) {
                        [registedBundle unload];
                    }
                }
                self.registedHandlers[handler] = [@{kCTDynamicLibManangerRegistedHandlersKeyBundle:bundle} mutableCopy];
            }];
        } else {
            // bundle path error
            result = NO;
            generatedError = [NSError errorWithDomain:kCTDynamicLibManangerErrorDomainHandler
                                                 code:CTDynamicLibManangerErrorCode_RegistHandlerFail
                                             userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"bundle path [%@] not available", dynamicLibPath]}];
        }
    } else {
        // params error
        generatedError = [NSError errorWithDomain:kCTDynamicLibManangerErrorDomainHandler
                                             code:CTDynamicLibManangerErrorCode_RegistHandlerFail
                                         userInfo:@{NSLocalizedDescriptionKey:@"bundle path is empty"}];
        result = NO;
    }
    
    error = &generatedError;
    return result;
}

- (void)removeHandler:(NSString *)handlerName
{
    if (handlerName && handlerName.length > 0 && self.registedHandlers[handlerName]) {
        [self.registedHandlers removeObjectForKey:handlerName];
    }
}

- (void)removeHandlersOfTarget:(id<CTDynamicLibPrincipalClassProtocol>)target
{
    if (target == nil) {
        return;
    }

    NSMutableArray *handlerListToRemove = [[NSMutableArray alloc] init];
    [self.registedHandlers enumerateKeysAndObjectsUsingBlock:^(NSString *handler, NSDictionary *obj, BOOL *stop) {
        if (obj[kCTDynamicLibManangerRegistedHandlersKeyPerformTarget] == target) {
            [handlerListToRemove addObject:handler];
        }
    }];
    [self.registedHandlers removeObjectsForKeys:handlerListToRemove];
}

- (NSDictionary *)allHandlers
{
    return self.registedHandlers;
}

#pragma marm - methods for perform handlers
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
    
    // lazy load target
    id<CTDynamicLibPrincipalClassProtocol> target = self.registedHandlers[handler][kCTDynamicLibManangerRegistedHandlersKeyPerformTarget];
    if (target == nil) {
        NSBundle *bundle = self.registedHandlers[handler][kCTDynamicLibManangerRegistedHandlersKeyBundle];
        target = [[bundle.principalClass alloc] init];
        if (target) {
            self.registedHandlers[handler][kCTDynamicLibManangerRegistedHandlersKeyPerformTarget] = target;
        } else {
            NSError *error = [NSError errorWithDomain:kCTDynamicLibManangerErrorDomainHandler
                                                 code:CTDynamicLibManangerErrorCode_PerformHandlerFail
                                             userInfo:@{
                                                        NSLocalizedDescriptionKey:[NSString stringWithFormat:@"target for bundle[%@] can not be initialized", bundle.infoDictionary],
                                                        NSLocalizedRecoverySuggestionErrorKey:[NSString stringWithFormat:@"check Info.plist in bundle[%@], does the [Principal Class] is well setted?", bundle.infoDictionary]
                                                        }];
            if ([self.handlerDelegate respondsToSelector:@selector(dynamicLibMananger:didFailedPerformHandler:forTarget:withParams:error:)]) {
                [self.handlerDelegate dynamicLibMananger:self didFailedPerformHandler:handler forTarget:nil withParams:params error:error];
            }
            if (completion) {
                completion(nil, error);
            }
        }
    }
    
    // if target is available, then perform handler
    if ([target respondsToSelector:@selector(performHandler:withParams:processingCallback:completion:)]) {
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
