//
//  VFViewController.m
//  VideoFilterTechDemo
//
//  Created by samingzhong on 2017/8/30.
//  Copyright © 2017年 samingzhong. All rights reserved.
//

#import "VFViewController.h"
#import <GLKit/GLKit.h>
#import "VFAppDelegate.h"
#import <MotionOrientation.h>
#import "CameraControlView.h"
static CGColorSpaceRef sDeviceRgbColorSpace = NULL;

@interface VFViewController ()

@property (nonatomic, strong) dispatch_queue_t captureSessionQueue;
@property (weak, nonatomic) IBOutlet GLKView *videoPreviewView;
@property (nonatomic, strong) CIContext *ciContext;
@property (nonatomic, strong) EAGLContext *eaglContext;
@property (nonatomic, assign) CGRect videoPreviewViewBounds;

@property (weak, nonatomic) IBOutlet CameraControlView *cameraControlView;

@end

@implementation VFViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    
//    self.cameraControlView = [[NSBundle mainBundle] loadNibNamed:@"VFCustomView" owner:nil options:nil][1];
//    [self.view addSubview:_cameraControlView];
    CameraControlView *view = [[[NSBundle mainBundle]loadNibNamed:@"VFCustomView" owner:nil options:nil] objectAtIndex:1];
    self.cameraControlView = view;
}


- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // create the shared color space object once
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sDeviceRgbColorSpace = CGColorSpaceCreateDeviceRGB();
        });
        
        
        // create the dispatch queue for handling capture session delegate method calls
        _captureSessionQueue = dispatch_queue_create("com.sunteng.capture_session_queue", NULL);
        
        [UIApplication sharedApplication].statusBarHidden = YES;

    }
    
//    CameraControlView *controlView = [CameraControlView new];
//    
//    [[UINib nibWithNibName:@"VFCustomView" bundle:nil] instantiateWithOwner:controlView options:nil];
//    
    NSLog(@"%s", __FUNCTION__);
    
    return self;
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _videoPreviewView.transform = CGAffineTransformMakeRotation(M_PI_2);
    
    _eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    UIWindow *window = ((VFAppDelegate *)[UIApplication sharedApplication].delegate).window;
//    _videoPreviewView = [[GLKView alloc] initWithFrame:window.bounds context:_eaglContext];
    _videoPreviewView.frame = window.bounds;
    _videoPreviewView.context = _eaglContext;
    _ciContext = [CIContext contextWithEAGLContext:_eaglContext options:@{kCIContextWorkingColorSpace : [NSNull null]} ];
    [_videoPreviewView bindDrawable];
    
    _videoPreviewViewBounds.size.width = _videoPreviewView.drawableWidth;
    _videoPreviewViewBounds.size.height = _videoPreviewView.drawableHeight;
    
    
    glClearColor(0.5, 0.5, 0.5, 1.0);
//            glClearColor(1, 1, 1, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // set the blend mode to "source over" so that CI will use that
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    
//    if (filteredImage)
//        [_ciContext drawImage:filteredImage inRect:_videoPreviewViewBounds fromRect:drawRect];
    
    [_videoPreviewView display];
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

- (void)deviceOrientationChanged:(NSNotification *)notification {
    NSLog(@"%s motionDeviceOrientation:%d", __FUNCTION__, [MotionOrientation sharedInstance].deviceOrientation);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
