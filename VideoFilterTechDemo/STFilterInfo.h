//
//  STFilterInfo.h
//  VideoFilterTechDemo
//
//  Created by samingzhong on 2017/9/4.
//  Copyright © 2017年 samingzhong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STFilterInfo : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *filterDescription;
@property (nonatomic, copy) NSString *CLUTBase64String;

+ (instancetype)filterInfoWithName:(NSString *)filterName description:(NSString *)filterDescription CLUTBase64String:(NSString *)CLUTBase64String;
@end
