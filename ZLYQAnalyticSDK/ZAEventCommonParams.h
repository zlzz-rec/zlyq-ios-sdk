//
//  ZAEventCommonParams.h
//  ZADataAPI
//
//  Created by ZYM on 2020/5/15.
//

#import <Foundation/Foundation.h>

#import "ZADefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZAEventCommonParams : NSObject

+ (NSDictionary *)commomPramsWithType:(ZACommonParamsType)type;

+ (NSString *)debugStringWithDebugModel:(ZADebugMode)debugMode;

@end

NS_ASSUME_NONNULL_END
