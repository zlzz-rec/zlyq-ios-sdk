//
//  ZAEventPusher.m
//  ZADataAPI
//
//  Created by ZYM on 2020/5/13.
//

#import "ZAEventPusher.h"

#import "ZAEventTool.h"
#import "ZAEventCommonParams.h"
#import "ZADataAPI.h"
#import <AFNetworking/AFNetworking.h>

@interface ZAEventPusher ()

/// 正在上传的事件组，每组的key是时间戳
@property (nonatomic, strong) NSMutableDictionary *uploadingEvents;
/// 是否正在上传 控制一个一个上传
@property (nonatomic, assign) BOOL isUploading;

@property (nonatomic, strong) NSLock *lock;

@end

static NSString *upload_error_key = @"sk_events_upload_error_key";

@implementation ZAEventPusher

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.lock = [[NSLock alloc] init];
        self.isUploading = NO;
        self.uploadingEvents = [NSMutableDictionary dictionary];
        NSDictionary *uploadErrorEvents = [[NSUserDefaults standardUserDefaults] valueForKey:upload_error_key];
        if (uploadErrorEvents.count > 0) {
            [self.uploadingEvents addEntriesFromDictionary:uploadErrorEvents];
        }
        
        [self addNotifications];
    }
    return self;
}

#pragma mark - 通知
- (void)addNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willTermination)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
}

- (void)willTermination {
    [[NSUserDefaults standardUserDefaults] setValue:self.uploadingEvents forKey:upload_error_key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - 上传
- (void)pushEvent:(NSDictionary *)event
        debugMode:(ZADebugMode)debugMode
completionHandler:(void (^)(BOOL))completion {
    [self pushEvents:@[event]
           debugMode:(ZADebugMode)debugMode
   completionHandler:completion];
}

- (void)pushEvents:(NSArray *)events
         debugMode:(ZADebugMode)debugMode
 completionHandler:(void (^)(BOOL))completion {
    if (events.count == 0) {
        return;
    }
    
    // 正在上传 返回
    if (self.isUploading) {
        return;
    }
    
    BOOL isDebug = (debugMode != ZADebugModeClosed);
    NSString *timeKey = [ZAEventTool timeStr];
    if (isDebug == NO) {
        [self.lock lock];
        NSMutableArray *allEvents = [NSMutableArray arrayWithArray:events];
        // 把上传异常的事件都归类到一个数组中 打包上传
        for (NSString *key in self.uploadingEvents.allKeys) {
            [allEvents addObjectsFromArray:self.uploadingEvents[key]];
        }
        [self.uploadingEvents removeAllObjects];    // 清除之前的
        [self.uploadingEvents setValue:allEvents forKey:timeKey];   // 最后打成一个包
        [self.lock unlock];
        
        self.isUploading = YES;
    }
    
    // 无网络 返回
    if ([self networkStatus] == AFNetworkReachabilityStatusNotReachable) {
        return;
    }
    
    NSDictionary *params = @{
        @"project_id"   : @([ZADataAPI shareManager].projectID.integerValue),
        @"type"         : @"track",
        @"debug_mode"   : [ZAEventCommonParams debugStringWithDebugModel:debugMode],
        @"common"       : [ZAEventCommonParams commomPramsWithType:self.commonParamsType],
        @"properties"   : events
    };
    
    [ZAEventTool request:[ZAEventTool pushURL]
                  method:@"POST"
              parameters:params
                 success:^(id  _Nonnull responseObject) {
        
        BOOL isSuccess = NO;
        if ([responseObject[@"code"] integerValue] == 0) {
            isSuccess = YES;
        }
        
        if (completion) {
            completion(isSuccess);
        }
        if (isDebug == NO) {
            if (isSuccess) {
                [self.uploadingEvents removeObjectForKey:timeKey];
            }
            self.isUploading = NO;
        } else {
            NSLog(@"\n debug upload %@ \n---", isSuccess ? @"success" : @"failed");
        }
    } failure:^(NSError * _Nonnull error) {
        if (completion) {
            completion(NO);
        }
        if (isDebug == NO) {
            self.isUploading = NO;
        }
    }];
}

#pragma mark - set profile
- (void)requestSetProfile:(NSDictionary *)userInfo
                debugMode:(ZADebugMode)debugMode
                     type:(nonnull NSString *)type {
    
    NSDictionary *commomDict = @{
        @"distinct_id"  : [ZADataAPI shareManager].distinctID,
        @"user_id"      : [ZADataAPI shareManager].userID,
        @"time"         : [ZAEventTool formatTime],
        @"type"         : type,
        @"udid"         : [ZAEventTool udid],
    };
    NSDictionary *params = @{
        @"project_id"   : @([ZADataAPI shareManager].projectID.integerValue),
        @"type"         : @"user_profile",
        @"debug_mode"   : [ZAEventCommonParams debugStringWithDebugModel:debugMode],
        @"common"       : commomDict,
        @"property"     : userInfo,
    };
    
    [ZAEventTool request:[ZAEventTool profileURL]
                  method:@"POST"
              parameters:params
                 success:^(id  _Nonnull responseObject) {
        if ([responseObject[@"code"] integerValue] == 0) {
            NSLog(@"setProfile success");
        } else {
            NSLog(@"set_profile failed: \n %@ \n", responseObject[@"data"]);
        }
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"set_profile error: \n %@ \n", error);
    }];
}

#pragma mark - 网络监听
/// 网络状态
- (AFNetworkReachabilityStatus)networkStatus {
    return [[AFNetworkReachabilityManager manager] networkReachabilityStatus];
}

@end
