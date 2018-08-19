//
//  XVIEWWeiboManager.h
//  XVIEW2.0
//
//  Created by njxh on 16/11/28.
//  Copyright © 2016年 南京 夏恒. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XVIEWSDKObject.h"

@interface XVIEWWeiboManager : NSObject
/*
 http://open.weibo.com/wiki/Oauth2/authorize
 http://open.weibo.com/wiki/2/users/show 获取个人信息的接口
 需要添加的Frameworks:
 QuartzCore.framework
 ImageIO.framework
 SystemConfiguration.framework
 Security.framework
 CoreTelephony.framework
 CoreText.framework
 UIKit.framework
 Foundation.framework
 CoreGraphics.framework
 libz.dylib
 libsqlite3.dylib
 
 在工程中引入静态库之后，需要在编译时添加–objC编译选项，避免静态库中类加载不全造成程序崩溃。
 方法:程序Target->Buid Settings->Linking下Other Linker Flags项添加-ObjC
 */


/**
 *  WeiboApiManager的单例类
 *
 *  @return 您可以通过此方法，获取WeiboApiManager的单例，访问对象中的属性和方法
 */
+ (instancetype)shareXVIEWWeiboManager;

+ (BOOL)isWeiboAppInstalled;

@end
