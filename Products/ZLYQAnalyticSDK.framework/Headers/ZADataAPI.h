//
//  ZADataAPI.h
//  Sparks
//
//  Created by ZYM on 2020/5/13.
//  Copyright © 2020 ZYM. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZADataAPI : NSObject

@property (nonatomic, copy, readonly) NSString *userID;
@property (nonatomic, copy, readonly) NSString *distinctID;
@property (nonatomic, copy, readonly) NSString *server;
@property (nonatomic, copy, readonly) NSString *projectID;
@property (nonatomic, copy, readonly) NSString *apiKey;

#pragma mark - 初始化
+ (instancetype)shareManager;

#pragma mark - 配置相关
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
                uploadCount:(NSInteger)count;
/// 内部调用
- (void)configWithAppKey:(NSString *)appKey appSecret:(NSString *)appSecret;

#pragma mark - 请求相关
/// 登录
- (void)loginWithUserID:(NSString *)userID;
/// 退出登录
- (void)logout;
#pragma mark - 用户画像
- (void)setProfile:(NSDictionary *)profileInfo;
- (void)setOnceProfile:(NSDictionary *)profileInfo;
- (void)appendProfile:(NSDictionary *)profileInfo;
/// 该方法只支持对数值类型属性修改
- (void)increaseProfile:(NSDictionary *)profileInfo;
- (void)deleteProfile:(NSDictionary *)profileInfo;
- (void)unsetProfile:(NSDictionary *)profileInfo;


#pragma mark - 事件
/**
 添加事件
 */
+ (void)addEvent:(NSString *)eventName
            info:(nullable NSDictionary *)info;

/**
 添加事件
 shouldDelay: YES 普通添加事件, NO 立即上传该事件
 */
+ (void)addEvent:(NSString *)eventName
            info:(nullable NSDictionary *)info
     shouldDelay:(BOOL)shouldDelay;

#pragma mark - scheme唤起
- (BOOL)couldHanleSchemeURL:(NSURL *)url;

#pragma mark - 公共参数
- (NSDictionary *)commonParams;

#pragma mark -
/// 版本号
+ (NSString *)sdkVersion;

@end

NS_ASSUME_NONNULL_END
