//
//  ZADefines.h
//  ZADataAPI
//
//  Created by ZYM on 2020/5/15.
//

#ifndef ZADefines_h
#define ZADefines_h

#pragma mark - debug模式
typedef NS_ENUM(NSUInteger, ZADebugMode) {
    ZADebugModeClosed = 1,               // 正常模式
    ZADebugModeDebugAndImport,           // debug入库
    ZADebugModeDebugAndNotImport         // debug不入库
};

#define ZADebugModeClosedString                 @"关闭debug"
#define ZADebugModeDebugAndImportString         @"数据入库(debug模式)"
#define ZADebugModeDebugAndNotImportString      @"数据不入库(debug模式)"

#pragma mark - 公共参数类型
typedef NS_ENUM(NSUInteger, ZACommonParamsType) {
    ZACommonParamsTypeDefault = 0,      // 私有化
    ZACommonParamsTypePlatform,         // feed中台
};

#pragma mark - path
static NSString * const identificationPath = @"/api/v1/identification/";    // 验证身份
static NSString * const eventPushPath = @"/api/v1/track/";                 // 上传
static NSString * const profilePath = @"/api/v1/user_profile/";                  // 用户画像

#endif /* ZADefines_h */
