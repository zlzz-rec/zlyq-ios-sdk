//
//  ZAEventTool.m
//  ZADataAPI
//
//  Created by ZYM on 2020/5/14.
//

#import "ZAEventTool.h"

#import "ZADataAPI.h"
#import "ZADefines.h"

#import <AFNetworking/AFNetworking.h>
#import <AdSupport/AdSupport.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <sys/utsname.h>
#import "ZAKeychainItemWrapper.h"
#import <CommonCrypto/CommonCrypto.h>

static NSDateFormatter *dateFormatter = nil;
static NSCalendar *calendar = nil;
static CGSize deviceScreenSize;

static NSString *sdkVersionStr = @"";
static NSString *appVersionStr = @"";

@interface TipView : UIView
@property (nonatomic, strong) UILabel *label;
- (void)showTip:(NSString *)title;
@end

@implementation TipView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2];
        self.layer.cornerRadius = 10;
        self.layer.masksToBounds = YES;
    }
    return self;
}

- (void)showTip:(NSString *)title {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hide) object:nil];
    if (self.hidden) {
        self.hidden = NO;
    }
    
    if (!_label) {
        _label = [[UILabel alloc] init];
        _label.font = [UIFont systemFontOfSize:14];
        _label.textColor = [UIColor darkGrayColor];
        _label.numberOfLines = 0;
        [self addSubview:_label];
    }
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    self.label.text = title;
    CGSize size = [title boundingRectWithSize:CGSizeMake(screenSize.width - 2 * 100, CGFLOAT_MAX)
                                      options:NSStringDrawingUsesLineFragmentOrigin
                                   attributes:@{
                                       NSFontAttributeName : self.label.font
                                   }
                                      context:nil].size;
    self.label.frame = CGRectMake(0, 0, size.width, size.height);
    self.frame = CGRectMake(0, 0, size.width + 30, size.height + 30);
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    self.center = CGPointMake(screenSize.width * 0.5, screenSize.height * 0.5);
    self.label.center = CGPointMake(self.bounds.size.width * 0.5, self.bounds.size.height * 0.5);
    
    [self performSelector:@selector(hide)];
}

- (void)hide {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.hidden = YES;
    });
}

@end


static TipView *tipView = nil;
@implementation ZAEventTool

#pragma mark - 接口URL
/// 验证身份
+ (NSString *)identificationURL {
    return [NSString stringWithFormat:@"%@%@%@", [ZADataAPI shareManager].server, identificationPath, [ZADataAPI shareManager].projectID];
}

/// 上传
+ (NSString *)pushURL {
    return [NSString stringWithFormat:@"%@%@%@", [ZADataAPI shareManager].server, eventPushPath, [ZADataAPI shareManager].projectID];
}

/// 修改profile
+ (NSString *)profileURL {
    return [NSString stringWithFormat:@"%@%@%@", [ZADataAPI shareManager].server, profilePath, [ZADataAPI shareManager].projectID];
}

#pragma mark - tool
/// 毫秒级时间戳
+ (NSString *)timeStr {
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
    return [NSString stringWithFormat:@"%ld", (long)(time * 1000)];
}

/// udid
+ (NSString *)udid {
    static NSString *udid = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *sk_udid_key = @"udid_key_for_keyChanin";
        ZAKeychainItemWrapper *keychain = [[ZAKeychainItemWrapper alloc] initWithIdentifier:@"com.sk.udid" accessGroup:nil];
        udid = [keychain objectForKey:(__bridge id)kSecValueData];
        if (![udid isKindOfClass:[NSString class]] || udid.length == 0) {
            udid = [[NSUserDefaults standardUserDefaults] objectForKey:sk_udid_key];
            if (![udid isKindOfClass:[NSString class]] || udid.length == 0) {
                NSString *uuid = nil;
                if ([[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled]) {
                    uuid = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
                } else {
                    uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
                    if (uuid.length <= 0) {
                        uuid = [[NSUUID UUID] UUIDString];
                    }
                }
                udid = [uuid uppercaseString];
            }
            [keychain setObject:udid forKey:(__bridge id)kSecValueData];
        }
        [[NSUserDefaults standardUserDefaults] setObject:udid forKey:sk_udid_key];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        if (udid.length == 0) {
            udid = @"";
        }
    });
    return udid;
}

/// platform
+ (NSString *)platform {
    return @"iOS";
}

/// 格式化的时间 yyyy/MM/dd HH:mm:ss
+ (NSString *)formatTime {
    return [[self dateFormatter] stringFromDate:[NSDate date]];
}

/// sdk_type
+ (NSString *)SDKType {
    return @"iOS";
}

/// SDK version
+ (NSString *)SDKVersion {
    if (sdkVersionStr.length == 0) {
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSString *fileName = @"Info.plist";
        NSString *plistPath = [bundle pathForResource:fileName ofType:nil];
        NSDictionary *plist = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
        sdkVersionStr = [plist valueForKey:@"CFBundleShortVersionString"];
    }
    return sdkVersionStr;
}

/// 屏幕高度
+ (NSInteger)screenHeight {
    return (NSInteger)([self screenSize].height);
}

/// 屏幕宽度
+ (NSInteger)screenWidth {
    return (NSInteger)([self screenSize].width);
}

/// 设备制造商
+ (NSString *)deviceManufacture {
    return @"Apple";
}

/// 设备型号
+ (NSString *)deviceModel {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
    return platform;
}

/// 网络
+ (NSString *)network {
    if ([AFNetworkReachabilityManager sharedManager].networkReachabilityStatus == AFNetworkReachabilityStatusReachableViaWiFi) {
        return @"wifi";    // WIFI
    }
    
    NSDictionary *netSattusDict = @{
                                    CTRadioAccessTechnologyGPRS             : @"GPRS",         // GPRS 2G
                                    CTRadioAccessTechnologyEdge             : @"EDGE",         // EDGE 2.75G
                                    CTRadioAccessTechnologyCDMA1x           : @"CDMA",
                                    CTRadioAccessTechnologyCDMAEVDORev0     : @"CDMA",
                                    CTRadioAccessTechnologyCDMAEVDORevA     : @"CDMA",
                                    CTRadioAccessTechnologyCDMAEVDORevB     : @"CDMA",
                                    CTRadioAccessTechnologyWCDMA            : @"WCDMA",
                                    CTRadioAccessTechnologyHSDPA            : @"HSDPA",
                                    CTRadioAccessTechnologyHSUPA            : @"HSUPA",
                                    CTRadioAccessTechnologyeHRPD            : @"HRPD",
                                    CTRadioAccessTechnologyLTE              : @"4G",            // LTE
                                    };
    
    CTTelephonyNetworkInfo *teleInfo = [CTTelephonyNetworkInfo new];
    NSString *access = teleInfo.currentRadioAccessTechnology;
    NSString *status = netSattusDict[access];
    if ([status isEqualToString:@"4G"] == NO) {
        return @"3G";
    }
//    if ([status isEqualToString:@"5G"]) {
//        return @"5G";
//    }
    return status;
}

/// 操作系统
+ (NSString *)deviceOS {
    return @"iOS";
}

/// 操作系统版本
+ (NSString *)deviceOSVersion {
    return [UIDevice currentDevice].systemVersion;
}

/// 运营商
+ (NSString *)carrier {
    CTCarrier *carrier = [[CTTelephonyNetworkInfo new] subscriberCellularProvider];
    NSString *carrierName = carrier.carrierName;
    if ([carrierName isEqualToString:@"中国移动"]) {
        carrierName = @"中国移动";
    } else if ([carrierName isEqualToString:@"中国联通"]) {
        carrierName = @"中国联通";
    } else if ([carrierName isEqualToString:@"中国电信"]) {
        carrierName = @"中国电信";
    }else {
        carrierName = @"未知";
    }
    return carrierName;
}

/// app版本
+ (NSString *)appVersion {
    if (appVersionStr.length == 0) {
        NSBundle *mainBundle = [NSBundle mainBundle];
        appVersionStr = [mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    }
    return appVersionStr;
}

+ (BOOL)isSameDay:(NSDate *)date1 second:(NSDate *)date2 {
    NSCalendar *calendar = [self calendar];
    unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay;
    NSDateComponents* comp1 = [calendar components:unitFlags fromDate:date1];
    NSDateComponents* comp2 = [calendar components:unitFlags fromDate:date2];
    
    return [comp1 day]   == [comp2 day] &&
        [comp1 month] == [comp2 month] &&
        [comp1 year]  == [comp2 year];
}

+ (NSString *)md5FromString:(NSString *)string {
    if (!string || string.length == 0) {
        return nil;
    }
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    const char *str = data.bytes;
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)data.length, result);
    
    return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15]];
}

#pragma mark - lazy
+ (NSDateFormatter *)dateFormatter {
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    }
    return dateFormatter;
}

+ (CGSize)screenSize {
    if (deviceScreenSize.width == 0 || deviceScreenSize.height == 0) {
        deviceScreenSize = [UIScreen mainScreen].bounds.size;
    }
    return deviceScreenSize;
}

+ (NSCalendar *)calendar {
    if (calendar == nil) {
        calendar = [NSCalendar currentCalendar];
    }
    return calendar;
}

#pragma mark - 请求
+ (NSURLSessionTask *)request:(NSString *)urlString
                       method:(NSString *)method
                   parameters:(NSDictionary *)parameters
                      success:(void(^)(id responseObject))success
                      failure:(void(^)(NSError *error))failure {
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:[self requestUrlString:urlString method:method body:parameters] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *jsonSerializationError = nil;
            NSDictionary *jsonDict = nil;
            if (data) {
                jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonSerializationError];
            }
            
            if (error || jsonSerializationError) {
                if (failure) {
                    NSError *failureError = error ? : jsonSerializationError;
                    failure(failureError);
                }
            }else {
                if (success) {
                    success(jsonDict);
                }
            }
        });
    }];
    
    [dataTask resume];
    
    return dataTask;
}

+ (NSMutableURLRequest *)requestUrlString:(NSString *)urlString
                                   method:(NSString *)method
                                     body:(NSDictionary *)body {
    
    urlString = [self addCommonParamsToUrl:urlString];
    NSString *zSign = [self getZsignWithUrl:urlString params:body];
    
    
    urlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:method];
    [request setTimeoutInterval:15.0];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"UTF-8" forHTTPHeaderField:@"Charset"];
    [request addValue:zSign forHTTPHeaderField:@"Z-Sign"];
    if (body.allValues.count) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:NSJSONWritingPrettyPrinted error:nil];
//        [request setHTTPBody:jsonData];
        
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

        NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];
        NSRange range = {0,jsonString.length};
        //去掉字符串中的空格
        [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range];
        [request setHTTPBody:[mutStr dataUsingEncoding:NSUTF8StringEncoding]];
    }
    return request;
}

// 添加url公共参数
+ (NSString *)addCommonParamsToUrl:(NSString *)url {
    NSString *timeStr = [self timeStr];
    if ([url containsString:@"?"]) {
        return [NSString stringWithFormat:@"%@&time=%@", url, timeStr];
    } else {
        return [NSString stringWithFormat:@"%@?time=%@", url, timeStr];
    }
}

// 获取签名
+ (NSString *)getZsignWithUrl:(NSString *)url params:(NSDictionary *)params {
    
    NSDictionary *urlParams = [self paramsFromUrlString:url];
    NSString *sortedStringFromUrlParams = [self sortedStringFromParams:urlParams];
//    NSString *sortedStringFromBodyParams = [self sortedStringFromParams:params];
    NSString *sortedStringFromBodyParams = @""; // post参数不加密
    
    NSString *salt = [ZADataAPI shareManager].apiKey;
    NSString *totalString = [NSString stringWithFormat:@"%@&%@", sortedStringFromUrlParams, salt];
    if (sortedStringFromBodyParams.length > 0) {
        totalString = [NSString stringWithFormat:@"%@&%@", totalString, sortedStringFromBodyParams];
    }
    NSString *md5Str = [self md5FromString:totalString];
    return md5Str;
}

// 解析url中的参数
+ (NSDictionary *)paramsFromUrlString:(NSString *)url {
    NSURLComponents *comp = [NSURLComponents componentsWithString:url];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    for (NSURLQueryItem *item in comp.queryItems) {
        [params setValue:(item.value.length > 0 ? item.value : @"") forKey:item.name];
    }
    return params;
}

// 对参数进行排序后的字符串
+ (NSString *)sortedStringFromParams:(NSDictionary *)params {
    if (params.count == 0) {
        return @"";
    }
    NSMutableString *str = [NSMutableString stringWithFormat:@""];
    NSDictionary *commonPara = [params copy];
    [commonPara enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [str appendFormat:@"&%@=%@", key, [[NSString stringWithFormat:@"%@",obj] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]]];
    }];
    
    // 删掉第一个&
    if (str.length > 0) {
        [str deleteCharactersInRange:NSMakeRange(0, 1)];
    }
    return str;
}

#pragma mark -
+ (void)showAlert:(NSString *)title {
    if (tipView == nil) {
        tipView = [[TipView alloc] init];
    }
    [tipView showTip:title];
}

@end
