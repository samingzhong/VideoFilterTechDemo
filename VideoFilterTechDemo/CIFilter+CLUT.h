//
//  CIFilter+ColorLUT.h
//  ColorLUT
//
//  Created by d71941 on 7/16/13.
//  Copyright (c) 2013 huangtw. All rights reserved.
//

#import <CoreImage/CoreImage.h>

@interface CIFilter (CLUT)

+ (CIFilter *)colorCubeFilterWithCLUTImageNamed:(NSString *)LUTImageNamed dimension:(NSInteger)n;

+ (CIFilter *)colorCubeFilterWithCLUTBase64String:(NSString *)CLUTBase64String dimension:(NSInteger)n;

@end
