//
//  CIFilter+ColorLUT.h
//  ColorLUT
//

#import <CoreImage/CoreImage.h>

@interface CIFilter (CLUT)

+ (CIFilter *)colorCubeFilterWithCLUTImageNamed:(NSString *)LUTImageNamed dimension:(NSInteger)n;

+ (CIFilter *)colorCubeFilterWithCLUTBase64String:(NSString *)CLUTBase64String dimension:(NSInteger)n;

@end
