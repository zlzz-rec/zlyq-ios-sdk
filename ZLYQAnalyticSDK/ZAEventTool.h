//
//  ZAEventTool.h
//  ZADataAPI
//
//  Created by ZYM on 2020/5/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZAEventTool : NSObject

#pragma mark - 接口URL
/// 验证身份
+ (NSString *)identificationURL;
/// 上传
+ (NSString *)pushURL;
/// 修改profile
+ (NSString *)profileURL;

#pragma mark - tool
/// 毫秒级时间戳
+ (NSString *)timeStr;
/// udid
+ (NSString *)udid;
/// platform
+ (NSString *)platform;
/// 格式化的时间 yyyy/MM/dd HH:mm:ss
+ (NSString *)formatTime;
/// sdk_type
+ (NSString *)SDKType;
/// SDK version
+ (NSString *)SDKVersion;
/// 屏幕高度
+ (NSInteger)screenHeight;
/// 屏幕宽度
+ (NSInteger)screenWidth;
/// 设备制造商
+ (NSString *)deviceManufacture;
/// 设备型号
+ (NSString *)deviceModel;
/// 网络
+ (NSString *)network;
/// 操作系统
+ (NSString *)deviceOS;
/// 操作系统版本
+ (NSString *)deviceOSVersion;
/// 运营商
+ (NSString *)carrier;
/// app版本
+ (NSString *)appVersion;
/// 是否是同一天
+ (BOOL)isSameDay:(NSDate *)first second:(NSDate *)second;

#pragma mark - 网络请求
+ (NSURLSessionTask *)request:(NSString *)urlString
                       method:(NSString *)method
                   parameters:(NSDictionary *)parameters
                      success:(void(^)(id responseObject))success
                      failure:(void(^)(NSError *error))failure;

#pragma mark -
+ (void)showAlert:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
