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
static char kCTDynamicLibManangerProperty_RegistedHandlers[] = "kCTDynamicLibManangerProperty_RegistedHandlers";
static char kCTDynamicLibManangerProperty_HandlerDelegate[] = "kCTDynamicLibManangerProperty_HandlerDelegate";

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
    BOOL successed = YES;
    NSBundle *bundle = nil;
    
    if (dynamicLibPath == nil || dynamicLibPath.length == 0) {
        successed = NO;
        *error = [NSError errorWithDomain:kCTDynamicLibManangerErrorDomainHandler
                                             code:CTDynamicLibManangerErrorCode_RegistHandlerFail
                                         userInfo:@{NSLocalizedDescriptionKey:@"bundle path is empty"}];
    }
    
    if (successed) {
        bundle = [NSBundle bundleWithPath:dynamicLibPath];
        if (!bundle.bundleIdentifier) {
            successed = NO;
            *error = [NSError errorWithDomain:kCTDynamicLibManangerErrorDomainHandler
                                                 code:CTDynamicLibManangerErrorCode_RegistHandlerFail
                                             userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"bundle path [%@] not available", dynamicLibPath]}];
        }
    }
    
    if (successed) {
        successed = [self registHandlerFromDynamicLibBundle:bundle error:error];
    } else {
        if ([self.handlerDelegate respondsToSelector:@selector(dynamicLibMananger:didFailedRegistHandlerForBundle:error:)]) {
            [self.handlerDelegate dynamicLibMananger:self didSuccessedRegistHandlerForBundle:bundle];
        }
    }
    
    return successed;
}

- (BOOL)registHandlerFromDynamicLibBundle:(NSBundle *)dynamicLibBundle error:(NSError *__autoreleasing *)error
{
    BOOL successed = YES;
    NSArray *registedHandlers = nil;
    
    if (dynamicLibBundle == nil || dynamicLibBundle.bundleIdentifier == nil) {
        successed = NO;
        *error = [NSError errorWithDomain:kCTDynamicLibManangerErrorDomainHandler
                                     code:CTDynamicLibManangerErrorCode_RegistHandlerFail
                                 userInfo:@{
                                            NSLocalizedDescriptionKey:[NSString stringWithFormat:@"bundle[%@] is not available", dynamicLibBundle.infoDictionary]
                                            }];
    }
    
    
    if (successed) {
        registedHandlers = dynamicLibBundle.infoDictionary[kCTDynamicLibManangerInfoPlistKeyRegistedHandlers];
        if (registedHandlers == nil || [registedHandlers count] == 0) {
            successed = NO;
            *error = [NSError errorWithDomain:kCTDynamicLibManangerErrorDomainHandler
                                         code:CTDynamicLibManangerErrorCode_RegistHandlerFail
                                     userInfo:@{
                                                NSLocalizedDescriptionKey:[NSString stringWithFormat:@"can not find any handler in bundle[%@]", dynamicLibBundle.infoDictionary]
                                                }];
        }
    }
    
    if (successed) {
        successed = YES;
        [registedHandlers enumerateObjectsUsingBlock:^(NSString *handler, NSUInteger idx, BOOL *stop) {
            if (self.registedHandlers[handler]) {
                NSBundle *registedBundle = self.registedHandlers[handler][kCTDynamicLibManangerRegistedHandlersKeyBundle];
                if (registedBundle.loaded) {
                    [registedBundle unload];
                }
            }
            self.registedHandlers[handler] = [@{kCTDynamicLibManangerRegistedHandlersKeyBundle:dynamicLibBundle} mutableCopy];
        }];
    }
    
    if (successed) {
        if ([self.handlerDelegate respondsToSelector:@selector(dynamicLibMananger:didSuccessedRegistHandlerForBundle:)]) {
            [self.handlerDelegate dynamicLibMananger:self didSuccessedRegistHandlerForBundle:dynamicLibBundle];
        }
    } else {
        if ([self.handlerDelegate respondsToSelector:@selector(dynamicLibMananger:didFailedRegistHandlerForBundle:error:)]) {
            [self.handlerDelegate dynamicLibMananger:self didFailedRegistHandlerForBundle:dynamicLibBundle error:*error];
        }
    }
    
    return successed;
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
    BOOL successed = YES;
    NSError *error = nil;
    NSBundle *bundle = nil;
    id<CTDynamicLibPrincipalClassProtocol> target = nil;
    void(^completionCallBack)(NSDictionary *resultInfo, NSError *error) = nil;
    
    if (!handler) {
        successed = NO;
        error = [NSError errorWithDomain:kCTDynamicLibManangerErrorDomainHandler
                                    code:CTDynamicLibManangerErrorCode_PerformHandlerFail
                                    userInfo:@{
                                               NSLocalizedDescriptionKey:[NSString stringWithFormat:@"handler can not be nil"]
                                               }];
    }
    
    if (successed) {
        target = self.registedHandlers[handler][kCTDynamicLibManangerRegistedHandlersKeyPerformTarget];
        if (target == nil) {
            bundle = self.registedHandlers[handler][kCTDynamicLibManangerRegistedHandlersKeyBundle];
            if (![bundle loadAndReturnError:&error]) {
                successed = NO;
            }
        }
    }
    
    if (successed) {
        target = [bundle.principalClass sharedInstance];
        if (target == nil || ![target respondsToSelector:@selector(performHandler:withParams:processingCallback:completion:)]) {
            successed = NO;
            error = [NSError errorWithDomain:kCTDynamicLibManangerErrorDomainHandler
                                        code:CTDynamicLibManangerErrorCode_PerformHandlerFail
                                    userInfo:@{
                                               NSLocalizedDescriptionKey:[NSString stringWithFormat:@"can not load Principal Class[%@], check your Principal Class is well setted in Info.plist and conform to Protocol[%@]", bundle.principalClass, NSStringFromProtocol(@protocol(CTDynamicLibPrincipalClassProtocol))]
                                               }];
        }
    }
    
    if (successed) {
        __weak typeof(self) weakSelf = self;
        completionCallBack = ^(NSDictionary *resultInfo, NSError *error){
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (error) {
                if (strongSelf && [strongSelf.handlerDelegate respondsToSelector:@selector(dynamicLibMananger:didFailedPerformHandler:forBundle:withParams:error:)]) {
                    [strongSelf.handlerDelegate dynamicLibMananger:self didFailedPerformHandler:handler forBundle:bundle withParams:params error:error];
                }
            } else {
                if (strongSelf && [strongSelf.handlerDelegate respondsToSelector:@selector(dynamicLibMananger:didSuccessedPerformHandler:forBundle:withParams:resultInformation:)]) {
                    [strongSelf.handlerDelegate dynamicLibMananger:strongSelf didSuccessedPerformHandler:handler forBundle:bundle withParams:params resultInformation:resultInfo];
                }
            }
            
            if (completion) {
                completion(resultInfo, error);
            }
        };
        
        self.registedHandlers[handler][kCTDynamicLibManangerRegistedHandlersKeyPerformTarget] = target;
        [target performHandler:handler withParams:params processingCallback:processingCallback completion:completionCallBack];
    } else {
        if (self.handlerDelegate && [self.handlerDelegate respondsToSelector:@selector(dynamicLibMananger:didFailedPerformHandler:forBundle:withParams:error:)]) {
            [self.handlerDelegate dynamicLibMananger:self didFailedPerformHandler:handler forBundle:bundle withParams:params error:error];
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
