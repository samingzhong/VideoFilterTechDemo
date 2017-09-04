//
//  UIImage+SMAAdditions.m
//  SuntengMobileAds
//
//  Created by Joe.
//  Copyright © 2017年 Sunteng Information Technology Co., Ltd. All rights reserved.
//

#import "UIImage+SMAAdditions.h"

@implementation UIImage (SMAAdditions)

+ (instancetype)sma_imageWithBase64Encoding:(NSString *)base64String {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
    return [[UIImage alloc] initWithData:data];
}

+ (instancetype)sma_2xImageWithBase64Encoding:(NSString *)base64String {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
    return [[UIImage alloc] initWithData:data scale:2.0];
}

@end

SMA_FIX_CATEGORY_BUG(UIImage_SMAAdditions)
