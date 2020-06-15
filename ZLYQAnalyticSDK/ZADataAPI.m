//
//  ZADataAPI.m
//  Sparks
//
//  Created by ZYM on 2020/5/13.
//  Copyright © 2020 ZYM. All rights reserved.
//

#import "ZADataAPI.h"

#import "ZAEventSaver.h"
#import "ZAEventPusher.h"
#import "ZAEventDefaults.h"
#import "ZAEventTool.h"
#import "ZADefines.h"
#import "ZAEventCommonParams.h"

#import <AFNetworking/AFNetworking.h>

@interface ZADataAPI ()

@property (nonatomic, strong) ZAEventSaver *saver;
@property (nonatomic, strong) ZAEventPusher *pusher;

@property (nonatomic, assign) ZADebugMode debugMode;

@property (nonatomic, assign) BOOL isWithoutTimer;  // 不用定时器，即实时上传
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSInteger duration;
@property (nonatomic, assign) NSInteger maxCount;

@property (nonatomic, strong) NSDate *firstDayDate; // 首天的日期

@property (nonatomic, copy, readwrite) NSString *projectID;
@property (nonatomic, copy, readwrite) NSString *distinctID;
@property (nonatomic, copy, readwrite) NSString *userID;
@property (nonatomic, copy, readwrite) NSString *server;
@property (nonatomic, copy, readwrite) NSString *apiKey;
@property (nonatomic, copy, readwrite) NSString *appKey;    // scheme
@property (nonatomic, copy, readwrite) NSString *debugId;

@end

static NSInteger const defaultDuration = 15;
static NSInteger const defaultMaxCount = 100;

static NSString * const appInstallKey       = @"sk_event_install_key";          // 安装事件
static NSString * const firstDayKey         = @"sk_event_not_first_day_key";    // 安装后首天
static NSString * const allEventsKey        = @"sk_events_key";                 // 首次触发某事件
static NSString * const userIDKey           = @"sk_event_user_id_key";          // userID
static NSString * const distinctIDKey       = @"sk_event_distinct_id_key";      // distinctID

@implementation ZADataAPI

#pragma mark - 初始化
+ (instancetype)shareManager {
    static ZADataAPI *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ZADataAPI alloc] init];
        [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        
        self.saver = [[ZAEventSaver alloc] init];
        self.pusher = [[ZAEventPusher alloc] init];
        
        self.duration = defaultDuration;
        self.maxCount = defaultMaxCount;
        
        self.debugMode = ZADebugModeClosed;
        
        [self addNotifications];
        [self setupTimer];
        
        // 安装事件
        BOOL isInstalled = [[NSUserDefaults standardUserDefaults] boolForKey:appInstallKey];
        if (isInstalled == NO) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:appInstallKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [ZAEventDefaults appInstallEvent];
        }
        
        // 首天
        NSString *firstDay = [[NSUserDefaults standardUserDefaults] stringForKey:firstDayKey];
        if (firstDay.length == 0) {
            NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
            firstDay = [NSString stringWithFormat:@"%f", time];
            [[NSUserDefaults standardUserDefaults] setValue:firstDay forKey:firstDayKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        self.firstDayDate = [NSDate dateWithTimeIntervalSince1970:firstDay.doubleValue];
    }
    return self;
}

#pragma mark - 配置

/// 配置入口
/// @param projectID 项目ID
/// @param appKey appKey
/// @param apiKey apiKey
/// @param server 服务器地址
/// @param duration 触发数据上报时间间隔 单位秒， 默认15秒   <0实时上传, =0 用默认值, >0 自定义
/// @param count 触发数据上报条数 默认100条，实时上传该字段不起作用
- (void)configWithProjectID:(NSString *)projectID
                     appKey:(NSString *)appKey
                     apiKey:(NSString *)apiKey
                     server:(NSString *)server
             uploadDuration:(NSTimeInterval)duration
                uploadCount:(NSInteger)count {
    // projectID
    NSAssert(projectID.length != 0, @"projectID不能为空");
    self.projectID = projectID;
    
    // appKey
    NSAssert(appKey.length != 0, @"appKey不能为空");
    self.appKey = appKey;
    
    // apiKey
    NSAssert(apiKey.length != 0, @"apiKey不能为空");
    self.apiKey = apiKey;
    
    // 域名
    NSAssert(server.length != 0, @"server不能为空");
    self.server = server;
    
    // 间隔时间
    if (duration < 0) {
        self.isWithoutTimer = YES;
    } else if (duration == 0) {
        duration = defaultDuration;
    }
    self.duration = duration;
    if (self.isWithoutTimer) {
        [self invalidTimer];
    } else if (self.timer && self.duration != defaultDuration) {
        [self resetTimer];
    }
    
    // 触发上传的条数
    if (count == 0) {
        count = defaultMaxCount;
    }
    self.maxCount = count;
    
    self.pusher.commonParamsType = ZACommonParamsTypeDefault;
    
    [self requestIdentification];
}

/// feed中台配置
- (void)configWithAppKey:(NSString *)appKey appSecret:(nonnull NSString *)appSecret {
    
    self.pusher.commonParamsType = ZACommonParamsTypePlatform;
}

#pragma mark - 通知
- (void)addNotifications {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willTermination)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
}

/// 进前台 上传数据
- (void)didBecomeActive {

    if (self.timer == nil) {
        [self setupTimer];
    }
    
    NSDictionary *event = [ZAEventDefaults appDidStartEvent];
    [ZADataAPI addEvent:@"appStart" info:event];

    [self uploadLocalEvents];
}

/// 进入后台 保存数据
- (void)didEnterBackground {
    
    NSDictionary *event = [ZAEventDefaults appDidEndEvent];
    [ZADataAPI addEvent:@"appEnd" info:event];
    
    [self invalidTimer];
    
    [self.saver saveEventsToLocal];
}

/// APP挂掉前 保存数据
- (void)willTermination {
    NSLog(@" ---------  willTerminate ---------");
    [self.saver saveEventsToLocal];
}

#pragma mark - 事件
/**
 添加事件
 */
+ (void)addEvent:(NSString *)eventName
            info:(nullable NSDictionary *)info {
    [ZADataAPI addEvent:eventName info:info shouldDelay:YES];
}

/**
 添加事件
 shouldDelay: YES 普通添加事件, NO 立即上传该事件
 */
+ (void)addEvent:(NSString *)eventName
            info:(nullable NSDictionary *)info
     shouldDelay:(BOOL)shouldDelay {
    
    ZADataAPI *manager = [ZADataAPI shareManager];
    NSMutableDictionary *event = [NSMutableDictionary dictionary];
    if (info.count > 0) {
        [event addEntriesFromDictionary:info];
    }
    // 事件的公共字段
    [event setValue:eventName forKey:@"event"];
    [event setValue:[ZAEventTool formatTime] forKey:@"event_time"];
    // 非首天
    BOOL isFirstDay = [ZAEventTool isSameDay:manager.firstDayDate second:[NSDate date]];
    [event setValue:[NSNumber numberWithBool:isFirstDay] forKey:@"is_first_day"];
    // 事件首次触发
    NSMutableArray *events = [[NSUserDefaults standardUserDefaults] mutableArrayValueForKey:allEventsKey];
    BOOL isEventFirstCall = ![events containsObject:eventName];
    if (isEventFirstCall) {
        [events addObject:eventName];
        [[NSUserDefaults standardUserDefaults] setObject:events forKey:allEventsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    [event setValue:[NSNumber numberWithBool:isEventFirstCall] forKey:@"is_first_time"];
    // 是否登录
    BOOL isLogined = [ZADataAPI shareManager].userID.length > 0;
    [event setValue:[NSNumber numberWithBool:isLogined] forKey:@"is_login"];
    
    // debug
    if (manager.debugMode != ZADebugModeClosed) {
        [manager.pusher pushEvent:event
                        debugMode:manager.debugMode
                completionHandler:^(BOOL isSuccess) {
            NSLog(@"%@debug上报：%@", eventName, isSuccess ? @"成功" : @"失败");
        }];
        return;
    }
    
    // 实时上传
    if (shouldDelay == NO) {
        [manager.pusher pushEvent:event
                        debugMode:ZADebugModeClosed
                completionHandler:^(BOOL isSuccess) {
            NSLog(@"%@实时上报：%@", eventName, isSuccess ? @"成功" : @"失败");
        }];
        return;
    }
    
    // 保存event
    [manager.saver addEvent:event];
    
    // 判断是否需要上传
    if (manager.isWithoutTimer) {   // 实时上传
        [manager pushEventsToServer];
    } else if (manager.saver.events.count >= manager.maxCount) {
        [manager pushEventsToServer];
    }
}

#pragma mark - 上传相关
/// 上传事件到服务器
- (void)pushEventsToServer {
    NSLock *lock = [[NSLock alloc] init];
    [lock lock];
    NSArray *uploadEvents = [self.saver.events copy];
    [self.pusher pushEvents:uploadEvents
                  debugMode:ZADebugModeClosed
          completionHandler:^(BOOL isSuccess) {
        NSLog(@"事件条数或定时器触发上传：%zd条  %@", uploadEvents.count, isSuccess ? @"成功" : @"失败");
    }];
    [self.saver.events removeAllObjects];
    [lock unlock];
}

/// 上传本地保存的事件
- (void)uploadLocalEvents {
    NSArray *events = [[self.saver readAllLocalEvents] copy];
    [self.saver clearLocalEvents];
    
    if (events.count > 0) {
        [self.pusher pushEvents:events
                      debugMode:ZADebugModeClosed
              completionHandler:^(BOOL isSuccess) {
            NSLog(@"上传本地事件：%@", isSuccess ? @"成功" : @"失败");
        }];
    }
}

#pragma mark - timer
- (void)setupTimer {
    if (self.isWithoutTimer) {
        return;
    }
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.duration target:self selector:@selector(timerSelector) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)resetTimer {
    [self invalidTimer];
    [self setupTimer];
}

- (void)invalidTimer {
    if (self.timer != nil) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

/// 定时器
- (void)timerSelector {
    if (self.saver.events.count == 0) {
        return;
    }
    [self pushEventsToServer];
}

#pragma mark - 请求相关
/// 登录
- (void)loginWithUserID:(NSString *)userID {
    self.userID = userID;
    [[NSUserDefaults standardUserDefaults] setValue:userID forKey:userIDKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self requestIdentification];
}

/// 退出登录
- (void)logout {
    self.userID = @"";
    [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:userIDKey];
    
    [self requestIdentification];
}

// identification
- (void)requestIdentification {
    
    NSDictionary *params = @{
        @"project_id"   : @(self.projectID.integerValue),
        @"udid"         : [ZAEventTool udid],
        @"user_id"      : self.userID
    };
    
    [ZAEventTool request:[ZAEventTool identificationURL]
                  method:@"POST"
              parameters:params
                 success:^(id  _Nonnull responseObject) {
        if ([responseObject[@"code"] integerValue] == 0) {
            NSDictionary *data = responseObject[@"data"];
            NSString *distinctID = [NSString stringWithFormat:@"%@", data[@"distinct_id"]];
            self.distinctID = distinctID;
            [[NSUserDefaults standardUserDefaults] setValue:distinctID forKey:distinctIDKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"%@", error);
    }];
}

#pragma mark - 用户画像
- (void)setProfile:(NSDictionary *)profileInfo {
    [self updateProfile:profileInfo type:@"set"];
}

- (void)setOnceProfile:(NSDictionary *)profileInfo {
    [self updateProfile:profileInfo type:@"set_once"];
}

- (void)appendProfile:(NSDictionary *)profileInfo {
    [self updateProfile:profileInfo type:@"append"];
}

- (void)increaseProfile:(NSDictionary *)profileInfo {
    // 判断profileInfo是否都是数值类型
    NSString *pattern = @"^(-?\\d+)(\\.\\d+)?$";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
    BOOL isSuccess = YES;
    for (id value in profileInfo.allValues) {
        NSString *valueStr = [NSString stringWithFormat:@"%@", value];
        if ([predicate evaluateWithObject:valueStr] == NO) {
            isSuccess = NO;
            break;
        }
    }
    if (isSuccess == NO) {
        [ZAEventTool showAlert:@"该方法只支持对数值类型属性修改"];
        return;
    }
    [self updateProfile:profileInfo type:@"increase"];
}

- (void)deleteProfile:(NSDictionary *)profileInfo {
    [self updateProfile:profileInfo type:@"delete"];
}

- (void)unsetProfile:(NSDictionary *)profileInfo {
    [self updateProfile:profileInfo type:@"unset"];
}

- (void)updateProfile:(NSDictionary *)profileInfo type:(NSString *)type {
    if (profileInfo.count == 0) {
        return;
    }
    [self.pusher requestSetProfile:profileInfo
                         debugMode:self.debugMode
                              type:type];
}

#pragma mark - debug相关
- (BOOL)couldHanleSchemeURL:(NSURL *)url {
    if (url == nil) {
        return NO;
    }
    
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
    if (urlComponents == nil) {
        return NO;
    }
    
    if ([urlComponents.scheme isEqualToString:self.appKey]) {
        for (NSURLQueryItem *item in urlComponents.queryItems) {
            if ([item.name isEqualToString:@"debug_id"]) {
                self.debugId = item.value;
                break;
            }
        }
        [self callDebugModeView];
        return YES;
    }
    return NO;
}

- (void)callDebugModeView {
    NSString *title = @"选择模式";
    NSArray *debugModes = @[
        ZADebugModeClosedString,
        ZADebugModeDebugAndImportString,
        ZADebugModeDebugAndNotImportString
    ];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    for (NSString *mode in debugModes) {
        __weak typeof(self) wself = self;
        UIAlertAction *action = [UIAlertAction actionWithTitle:mode style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            __strong typeof(wself) self = wself;
            [self handleDebugModeWithModes:debugModes chooseModel:mode];
        }];
        [alertController addAction:action];
    }
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
}

- (void)handleDebugModeWithModes:(NSArray *)modes chooseModel:(NSString *)chooseMode {
    if ([chooseMode isEqualToString:ZADebugModeClosedString]) {
        self.debugMode = ZADebugModeClosed;
    } else if ([chooseMode isEqualToString:ZADebugModeDebugAndImportString]) {
        self.debugMode = ZADebugModeDebugAndImport;
    } else if ([chooseMode isEqualToString:ZADebugModeDebugAndNotImportString]) {
        self.debugMode = ZADebugModeDebugAndNotImport;
    }
    
    // 请求
    NSDictionary *params = @{
        @"udid" : [ZAEventTool udid]
    };
    [ZAEventTool request:[NSString stringWithFormat:@"%@%@%@/%@", self.server, debugPath, self.projectID, self.debugId]
                  method:@"PUT"
              parameters:params
                 success:^(id  _Nonnull responseObject) {
        if ([responseObject[@"code"] integerValue] == 0) {
            NSLog(@"set_debug success");
        } else {
            NSLog(@"set_debug failed: \n %@ \n", responseObject[@"data"]);
        }
        self.debugId = @"";
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"set_debug error: \n %@ \n", error);
        self.debugId = @"";
    }];
}

#pragma mark - 公共参数
- (NSDictionary *)commonParams {
    return [ZAEventCommonParams commomPramsWithType:ZACommonParamsTypeDefault];
}

#pragma mark -
/// 版本号
+ (NSString *)sdkVersion {
    return [ZAEventTool SDKVersion];
}

/// userID
- (NSString *)userID {
    if (_userID.length > 0) {
        return _userID;
    }
    
    NSString *userID = [[NSUserDefaults standardUserDefaults] valueForKey:userIDKey];
    if (userID.length > 0) {
        return userID;
    }
    return @"";
}

/// distinctID
- (NSString *)distinctID {
    if (_distinctID.length > 0) {
        return _distinctID;
    }
    
    NSString *distinctID = [[NSUserDefaults standardUserDefaults] valueForKey:distinctIDKey];
    if (distinctID.length > 0) {
        return distinctID;
    }
    return @"";
}

@end
