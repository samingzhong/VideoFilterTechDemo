//
//  UIImage+SMAAdditions.h
//  SuntengMobileAds
//
//  Created by Joe.
//  Copyright © 2017年 Sunteng Information Technology Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (STAdditions)

+ (instancetype)sma_imageWithBase64Encoding:(NSString *)base64String;
+ (instancetype)sma_2xImageWithBase64Encoding:(NSString *)base64String;

@end
