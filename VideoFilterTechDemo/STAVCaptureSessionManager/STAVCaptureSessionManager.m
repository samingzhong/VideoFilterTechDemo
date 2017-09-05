//
//  STAVCaptureSessionManager.m
//  VideoFilterTechDemo
//
//  Created by samingzhong on 2017/9/1.
//  Copyright © 2017年 samingzhong. All rights reserved.
//

#import "STAVCaptureSessionManager.h"
#import <CoreGraphics/CoreGraphics.h>
#import <GLKit/GLKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>

NSString *const kSTCameraPositionKey = @"CameraPosition";
NSString *const kSTCaptureSessionPresetKey = @"CaptureSessionPreset";

static CGColorSpaceRef sDeviceRgbColorSpace = NULL;


@interface STAVCaptureSessionManager () <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>
@property (nonatomic, strong) dispatch_queue_t captureSessionQueue;
@property (nonatomic, strong) EAGLContext *eaglContext;
@property (nonatomic, strong) CIContext *ciContext;
@property (nonatomic, assign) CGRect videoPreviewViewBounds;


@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDevice *audioDevice;
@property (nonatomic, strong) AVCaptureDevice *videoDevice;

@property (nonatomic, assign) CMFormatDescriptionRef currentAudioSampleBufferFormatDescription;
@property (nonatomic, assign) CMVideoDimensions currentVideoDimensions;
@property (nonatomic, strong) AVAssetWriter *assetWriter;


@end


@implementation STAVCaptureSessionManager

// an inline function to filter a CIImage through a filter chain; note that each image input attribute may have different source
static inline CIImage *RunFilter(CIImage *cameraImage, CIFilter *filter)
{
    if (!filter) {
        return cameraImage;
    }
    
    CIImage *currentImage = nil;
    
    [filter setValue:cameraImage forKey:kCIInputImageKey];
    
    currentImage = filter.outputImage;
    if (currentImage == nil)
        return nil;
    
    if (CGRectIsEmpty(currentImage.extent))
        return nil;
    return currentImage;
}


#pragma mark - Public methods
- (instancetype)initWithPreviewerView:(GLKView *)videoPreviewView {
    self = [super init];
    if (self)
    {
        // create the shared color space object once
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sDeviceRgbColorSpace = CGColorSpaceCreateDeviceRGB();
        });
        
        // create the dispatch queue for handling capture session delegate method calls
        _captureSessionQueue = dispatch_queue_create("com.sunteng.capture_session_queue", NULL);
        
        // setting previewer
        {
            _videoPreviewView = videoPreviewView;
            _eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
            _videoPreviewView.context = _eaglContext;
            _videoPreviewView.enableSetNeedsDisplay = NO;
        }
        
        // create the CIContext instance, note that this must be done after _videoPreviewView is properly set up
        _ciContext = [CIContext contextWithEAGLContext:_eaglContext options:@{kCIContextWorkingColorSpace : [NSNull null]} ];
        
        // bind the frame buffer to get the frame buffer width and height;
        [_videoPreviewView bindDrawable];
        
        _videoPreviewViewBounds = CGRectZero;
        _videoPreviewViewBounds.size.width = _videoPreviewView.drawableWidth;
        _videoPreviewViewBounds.size.height = _videoPreviewView.drawableHeight;
    }
    return self;
}

- (void)startPreview {
    if (_captureSession) return;
    
    dispatch_async(_captureSessionQueue, ^(void) {
        NSError *error = nil;
        
        // get the input device and also validate the settings
        NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        
        AVCaptureDevicePosition position = [[NSUserDefaults standardUserDefaults] integerForKey:kSTCameraPositionKey];
        
        _videoDevice = nil;
        for (AVCaptureDevice *device in videoDevices)
        {
            if (device.position == position) {
                _videoDevice = device;
                break;
            }
        }
        
        if (!_videoDevice)
        {
            _videoDevice = [videoDevices objectAtIndex:0];
            [[NSUserDefaults standardUserDefaults] setObject:@(_videoDevice.position) forKey:kSTCameraPositionKey];
        }
        
        
        // obtain device input
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:_videoDevice error:&error];
        if (!videoDeviceInput)
        {
            [self _showAlertViewWithMessage:[NSString stringWithFormat:@"Unable to obtain video device input, error: %@", error]];
            return;
        }
        
        AVCaptureDeviceInput *audioDeviceInput = nil;
        if (_audioDevice)
        {
            audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:_audioDevice error:&error];
            if (!audioDeviceInput)
            {
                [self _showAlertViewWithMessage:[NSString stringWithFormat:@"Unable to obtain audio device input, error: %@", error]];
                return;
            }
        }
        
        // obtain the preset and validate the preset
        
        NSString *preset = [[NSUserDefaults standardUserDefaults] objectForKey:kSTCaptureSessionPresetKey];
        preset = AVCaptureSessionPreset1920x1080;

        if (![_videoDevice supportsAVCaptureSessionPreset:preset])
        {
            preset = AVCaptureSessionPresetHigh;
            [[NSUserDefaults standardUserDefaults] setObject:preset forKey:kSTCaptureSessionPresetKey];
        }
        if (![_videoDevice supportsAVCaptureSessionPreset:preset])
        {
            [self _showAlertViewWithMessage:[NSString stringWithFormat:@"Capture session preset not supported by video device: %@", preset]];
            return;
        }
        
        // CoreImage wants BGRA pixel format
        NSDictionary *outputSettings = @{ (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInteger:kCVPixelFormatType_32BGRA]};
        
        // create the capture session
        _captureSession = [[AVCaptureSession alloc] init];
        _captureSession.sessionPreset = preset;
        
        // create and configure video data output
        AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        videoDataOutput.videoSettings = outputSettings;
        videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
        [videoDataOutput setSampleBufferDelegate:self queue:_captureSessionQueue];
        
        // configure audio data output
        AVCaptureAudioDataOutput *audioDataOutput = nil;
        if (_audioDevice) {
            audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
            [audioDataOutput setSampleBufferDelegate:self queue:_captureSessionQueue];
        }
        
        // begin configure capture session
        [_captureSession beginConfiguration];
        
        if (![_captureSession canAddOutput:videoDataOutput])
        {
            [self _showAlertViewWithMessage:@"Cannot add video data output"];
            _captureSession = nil;
            return;
        }
        
        if (audioDataOutput)
        {
            if (![_captureSession canAddOutput:audioDataOutput])
            {
                [self _showAlertViewWithMessage:@"Cannot add still audio data output"];
                _captureSession = nil;
                return;
            }
        }
        
        // connect the video device input and video data and still image outputs
        [_captureSession addInput:videoDeviceInput];
        [_captureSession addOutput:videoDataOutput];
        
        if (_audioDevice)
        {
            [_captureSession addInput:audioDeviceInput];
            [_captureSession addOutput:audioDataOutput];
        }
        
        [_captureSession commitConfiguration];
        
        // then start everything
        [_captureSession startRunning];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            
//            UIView *window = ((FHAppDelegate *)[UIApplication sharedApplication].delegate).window;
            
            CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI_2);
            // apply the horizontal flip
            BOOL shouldMirror = (AVCaptureDevicePositionFront == _videoDevice.position);
            if (shouldMirror)
                transform = CGAffineTransformConcat(transform, CGAffineTransformMakeScale(-1.0, 1.0));
            
            CGRect tmpRect = _videoPreviewView.frame;
            _videoPreviewView.transform = transform;
//            _videoPreviewView.frame = window.bounds;
            _videoPreviewView.frame = tmpRect;
        
            // post notification
        });
        
    });

}


#warning TODOs
- (void)stopPreview {
    
}

- (void)startRecord {
    
}

- (void)stopRecord {
    
}

- (void)switchCamera {
    
}

#pragma mark - Delegate methods

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CMFormatDescriptionRef formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer);
    CMMediaType mediaType = CMFormatDescriptionGetMediaType(formatDesc);
    
    // write the audio data if it's from the audio connection
    if (mediaType == kCMMediaType_Audio)
    {
        CMFormatDescriptionRef tmpDesc = _currentAudioSampleBufferFormatDescription;
        _currentAudioSampleBufferFormatDescription = formatDesc;
        CFRetain(_currentAudioSampleBufferFormatDescription);
        
        if (tmpDesc)
            CFRelease(tmpDesc);
        
        // we need to retain the sample buffer to keep it alive across the different queues (threads)
//        if (_assetWriter &&
//            _assetWriterAudioInput.readyForMoreMediaData &&
//            ![_assetWriterAudioInput appendSampleBuffer:sampleBuffer])
//        {
//            [self _showAlertViewWithMessage:@"Cannot write audio data, recording aborted"];
//            [self _abortWriting];
//        }
        
        return;
    }
    
    // if not from the audio capture connection, handle video writing
    CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    
    // update the video dimensions information
    _currentVideoDimensions = CMVideoFormatDescriptionGetDimensions(formatDesc);
    
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *sourceImage = [CIImage imageWithCVPixelBuffer:(CVPixelBufferRef)imageBuffer options:nil];
    
    // run the filter through the filter chain
    CIImage *filteredImage = RunFilter(sourceImage, _filter);
    
    CGRect sourceExtent = sourceImage.extent;
    
    // for future
    //CGFloat sourceAspect = sourceExtent.size.width / sourceExtent.size.height;
    //CGFloat previewAspect = _videoPreviewViewBounds.size.width  / _videoPreviewViewBounds.size.height;
    
    // we want to maintain the aspect radio of the screen size, so we clip the video image
    CGRect drawRect = sourceExtent;

    
    // just show preview
    if (_assetWriter == nil)
    {
        [_videoPreviewView bindDrawable];
        
        if (_eaglContext != [EAGLContext currentContext])
            [EAGLContext setCurrentContext:_eaglContext];
        
        // clear eagl view to grey
        glClearColor(0.5, 0.5, 0.5, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);
        
        // set the blend mode to "source over" so that CI will use that
        glEnable(GL_BLEND);
        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
        
        if (filteredImage)
            [_ciContext drawImage:filteredImage inRect:CGRectMake(0, 0, self.videoPreviewView.drawableWidth, self.videoPreviewView.drawableHeight) fromRect:drawRect];
        
        [_videoPreviewView display];
    }
/*    else
    {
        // if we need to write video and haven't started yet, start writing
        if (!_videoWritingStarted)
        {
            _videoWritingStarted = YES;
            BOOL success = [_assetWriter startWriting];
            if (!success)
            {
                [self _showAlertViewWithMessage:@"Cannot write video data, recording aborted"];
                [self _abortWriting];
                return;
            }
            
            [_assetWriter startSessionAtSourceTime:timestamp];
            _videoWrtingStartTime = timestamp;
            self.currentVideoTime = _videoWrtingStartTime;
        }
        
        CVPixelBufferRef renderedOutputPixelBuffer = NULL;
        
        OSStatus err = CVPixelBufferPoolCreatePixelBuffer(nil, _assetWriterInputPixelBufferAdaptor.pixelBufferPool, &renderedOutputPixelBuffer);
        if (err)
        {
            NSLog(@"Cannot obtain a pixel buffer from the buffer pool");
            return;
        }
        
        // render the filtered image back to the pixel buffer (no locking needed as CIContext's render method will do that
        if (filteredImage)
            [_ciContext render:filteredImage toCVPixelBuffer:renderedOutputPixelBuffer bounds:[filteredImage extent] colorSpace:sDeviceRgbColorSpace];
        
        // pass option nil to enable color matching at the output, otherwise the color will be off
        CIImage *drawImage = [CIImage imageWithCVPixelBuffer:renderedOutputPixelBuffer options:nil];
        
        [_videoPreviewView bindDrawable];
        [_ciContext drawImage:drawImage inRect:_videoPreviewViewBounds fromRect:drawRect];
        [_videoPreviewView display];
        
        
        self.currentVideoTime = timestamp;
        
        // write the video data
        if (_assetWriterVideoInput.readyForMoreMediaData)
            [_assetWriterInputPixelBufferAdaptor appendPixelBuffer:renderedOutputPixelBuffer withPresentationTime:timestamp];
        
        CVPixelBufferRelease(renderedOutputPixelBuffer);
    }
 */
}



#pragma mark - alert view
- (void)_showAlertViewWithMessage:(NSString *)message title:(NSString *)title
{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"Dismiss"
                                              otherButtonTitles:nil];
        [alert show];
    });
}

- (void)_showAlertViewWithMessage:(NSString *)message
{
    [self _showAlertViewWithMessage:message title:@"Error"];
}

#pragma mark - setter & getter

- (void)setCaptureSessionPreset:(NSString *)captureSessionPreset {
    if (_captureSession) {
        dispatch_async(_captureSessionQueue, ^{
            _captureSession.sessionPreset = captureSessionPreset;
        });
    }
}

- (void)setFilter:(CIFilter *)filter {
    if (self) {
        if (filter.class == [CIFilter class]) {
            NSLog(@"%s Object can not just be %@", __FUNCTION__, NSStringFromClass([CIFilter class]));
            return;
        }
        dispatch_async(_captureSessionQueue, ^{
            _filter = filter;
        });        
    }
}

@end
