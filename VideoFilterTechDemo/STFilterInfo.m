//
//  STFilterInfo.m
//  VideoFilterTechDemo
//
//  Created by samingzhong on 2017/9/4.
//  Copyright © 2017年 samingzhong. All rights reserved.
//

#import "STFilterInfo.h"

@implementation STFilterInfo

+ (instancetype)filterInfoWithName:(NSString *)filterName description:(NSString *)filterDescription CLUTBase64String:(NSString *)CLUTBase64String {
    return [[STFilterInfo alloc] initWithFilterName:filterName description:filterDescription CLUTBase64String:CLUTBase64String];
}

- (instancetype)initWithFilterName:(NSString *)filterName description:(NSString *)filterDescription CLUTBase64String:(NSString *)CLUTBase64String {
    self = [super init];
    if (self) {
        _name = [filterName copy];
        _filterDescription = [filterDescription copy];
        _CLUTBase64String = [CLUTBase64String copy];
//        _name = filterName, _filterDescription = filterDescription, _CLUTBase64String = CLUTBase64String;
    }
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"FilterName:%@, Description:%@", _name, _filterDescription];
}

@end
