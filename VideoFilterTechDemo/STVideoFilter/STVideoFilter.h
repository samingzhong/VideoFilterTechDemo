//
//  STVideoFilter.h
//  VideoFilterTechDemo
//
//  Created by samingzhong on 2017/9/1.
//  Copyright © 2017年 samingzhong. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CIFilter;
@class GLKView;
#import <AVFoundation/AVFoundation.h>

@interface STVideoFilter : NSObject
@property (nonatomic, strong) GLKView *videoPreviewView;

@property (nonatomic, strong) CIFilter *filter;
@property (nonatomic, assign, readonly) BOOL isRecording;

@property (nonatomic, copy) NSString *captureSessionPreset;

- (instancetype)initWithPreviewerView:(GLKView *)previewerView;

- (void)startPreview;
- (void)stopPreview;

- (void)startRecord;
- (void)stopRecord;

- (void)switchCamera;

@end
