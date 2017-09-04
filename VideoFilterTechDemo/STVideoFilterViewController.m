//
//  STVideoFilterViewController.m
//  VideoFilterTechDemo
//
//  Created by samingzhong on 2017/9/1.
//  Copyright © 2017年 samingzhong. All rights reserved.
//

#import "STVideoFilterViewController.h"
#import <GLKit/GLKit.h>
#import "STVideoFilter.h"
#import "CIFilter+CLUT.h"
#import "STXXCLUTBase64String.h"
#import "STFilterInfo.h"


@interface STVideoFilterViewController ()
@property (weak, nonatomic) IBOutlet GLKView *videoPreviewerView;
@property (nonatomic, strong) STVideoFilter *videoFilter;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *previewerViewWithConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *previewerViewHeightConstraint;

@property (nonatomic, copy) NSArray *presetFiltersInfo;
@end

@implementation STVideoFilterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // load preset filter.
    _presetFiltersInfo = @[[STFilterInfo filterInfoWithName:@"红润" description:@"红润滤镜" CLUTBase64String:filter_hongrun_base64String],
      [STFilterInfo filterInfoWithName:@"农民工" description:@"农民工滤镜" CLUTBase64String:filter_nongmingong_base64String],
      [STFilterInfo filterInfoWithName:@"灰白" description:@"灰白滤镜" CLUTBase64String:filter_grey_base64String],
      [STFilterInfo filterInfoWithName:@"黄种人" description:@"黄种人滤镜" CLUTBase64String:filter_huangzhongren_base64String]
      ];
    
//    CIFilter *filter = [CIFilter colorCubeFilterWithCLUTImageNamed:@"42737475_xl" dimension:64];
    STFilterInfo *filterInfo = [_presetFiltersInfo firstObject];
    CIFilter *filter = [CIFilter colorCubeFilterWithCLUTBase64String:filterInfo.CLUTBase64String  dimension:64];
    filter = [CIFilter new];
    filter = [CIFilter filterWithName:@"CISepiaTone"];
//    CIFilter *filter = nil;
    
    _videoFilter = [[STVideoFilter alloc] initWithPreviewerView:self.videoPreviewerView];
    _videoFilter.filter = filter;
    [_videoFilter startPreview];
    
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:1 animations:^{
//            self.previewerViewHeightConstraint.constant = 700;
//            self.videoFilter.captureSessionPreset = AVCaptureSessionPreset352x288;
        }];
    });
    
    [NSTimer scheduledTimerWithTimeInterval:8 target:self selector:@selector(switchFilter) userInfo:nil repeats:YES];
}

- (void)switchFilter {
    static int index = 0;
    if (index == _presetFiltersInfo.count) {
        index = 0;
    }
    STFilterInfo *filterInfo = _presetFiltersInfo[index];
    NSLog(@"showing filter:%@", filterInfo);
    CIFilter *filter = [CIFilter colorCubeFilterWithCLUTBase64String:filterInfo.CLUTBase64String dimension:64];
    _videoFilter.filter = filter;
    index++;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate {
    return NO;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
