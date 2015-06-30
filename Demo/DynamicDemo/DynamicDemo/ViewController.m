//
//  ViewController.m
//  DynamicDemo
//
//  Created by casa on 6/24/15.
//  Copyright (c) 2015 casa. All rights reserved.
//

#import "ViewController.h"
#import "NVHTarGzip.h"
#import <CTDynamicLibKit/CTDynamicLibKit.h>

#import "LifeCycleDataSource.h"
#import "LifeCycleDelegate.h"
#import "HandlerDelegate.h"

@interface ViewController () <NSURLSessionDownloadDelegate>

@property (nonatomic, strong) NSURLSession *urlSession;

@property (nonatomic, strong) LifeCycleDataSource *lifeCycleDataSource;
@property (nonatomic, strong) LifeCycleDelegate *lifeCycleDelegate;
@property (nonatomic, strong) HandlerDelegate *handlerDelegate;

@end

@implementation ViewController

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSError *error;
    
    NSString *dependencyPath = [[NSBundle mainBundle] pathForResource:@"CTDynamicLibKit" ofType:@"framework"];
    NSBundle *basicLibBundle = [NSBundle bundleWithPath:dependencyPath];
    if (![basicLibBundle loadAndReturnError:&error]) {
        NSLog(@"%@", error);
    }
    
    [CTDynamicLibManager sharedInstance].lifeCycleDelegate = self.lifeCycleDelegate;
    [CTDynamicLibManager sharedInstance].lifeCycleDataSource = self.lifeCycleDataSource;
    [CTDynamicLibManager sharedInstance].handlerDelegate = self.handlerDelegate;
    
    [[CTDynamicLibManager sharedInstance] loadDynamicLibs];

    [[self.urlSession downloadTaskWithURL:[NSURL URLWithString:@"http://192.168.5.106:8080/a.tar.gz"]] resume];
}

#pragma mark - NSURLSessionDownloadDelegate
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    NSString *tmpPath = [location.absoluteString stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    NSString *targetPath =[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.framework", [NSUUID UUID].UUIDString]];
    NSError *error = NULL;
    if ([[NVHTarGzip shared] unTarGzipFileAtPath:tmpPath toPath:targetPath error:&error]) {
        [[CTDynamicLibManager sharedInstance] updateDynamicLibWithTmpPath:targetPath];
        [[CTDynamicLibManager sharedInstance] performHandler:@"test" completion:^(NSDictionary *resultInfo, NSError *error) {
            if (error) {
                NSLog(@"%@", error);
            }
        }];
    } else {
        NSLog(@"%@", error);
    }

    if (![[NSFileManager defaultManager] removeItemAtURL:location error:&error]) {
        NSLog(@"%@", error);
    }
}

#pragma mark - getters and setters
- (NSURLSession *)urlSession
{
    if (_urlSession == nil) {
        _urlSession = [NSURLSession sessionWithConfiguration:nil delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _urlSession;
}

- (LifeCycleDataSource *)lifeCycleDataSource
{
    if (_lifeCycleDataSource == nil) {
        _lifeCycleDataSource = [[LifeCycleDataSource alloc] init];
    }
    return _lifeCycleDataSource;
}

- (HandlerDelegate *)handlerDelegate
{
    if (_handlerDelegate == nil) {
        _handlerDelegate = [[HandlerDelegate alloc] init];
    }
    return _handlerDelegate;
}

- (LifeCycleDelegate *)lifeCycleDelegate
{
    if (_lifeCycleDelegate == nil) {
        _lifeCycleDelegate = [[LifeCycleDelegate alloc] init];
    }
    return _lifeCycleDelegate;
}

@end
