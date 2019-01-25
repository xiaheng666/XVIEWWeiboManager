//
//  XVIEWWeiboManager.h
//  XVIEWWeiboManager
//
//  Created by yyj on 2019/1/4.
//  Copyright © 2019 zd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XVIEWWeiboManager : NSObject

/**
 *  单例
 */
+ (instancetype)sharedWeiboManager;

/**
 *  注册微博
 @param param    data    {appId  微博的appid}
 */
- (void)registerApp:(NSDictionary *)param;

/**
 *  微信登陆
 @param param    callback:回调方法
 */
- (void)weiboLogin:(NSDictionary *)param;

/**
 *  微博分享
 @param param     data:{shareData:分享类型,shareDataKey:分享类型的参数}
                  callback:回调方法
 }
 */
- (void)weiboShare:(NSDictionary *)param;

/**
 *  微博返回回调
 @param param     data:{url:回调url}
                  callback:回调方法
 }
 */
- (BOOL)handleUrl:(NSDictionary *)param;

@end
