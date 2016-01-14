//
//  PortraitCutVC.m
//  NetTest
//
//  Created by zhangxu on 15/3/4.
//  Copyright (c) 2015年 zhangxu. All rights reserved.
//

#import "PortraitCutVC.h"
#define SCALE_FRAME_Y 100.0f
#define BOUNDCE_DURATION 0.3f


typedef void(^SuccessBlock)(UIImage *finalImage);

@interface PortraitCutVC ()
{
   
    SuccessBlock successBlock;
    
}

@property(nonatomic,strong)UIImage *originalImage;
@property(nonatomic,strong)UIImageView *showImgView;
@property(nonatomic,strong)UIView *maskView;
@property(nonatomic,strong)UIView *stencilView;
@property(nonatomic)CGSize cutSize;
@property(nonatomic)CGFloat scaleRatio;  //双指缩放 放大的比例
@property(nonatomic)CGSize screenSize;
@property(nonatomic)CGSize largeSize;
@property(nonatomic)CGRect latestFrame;
@property(nonatomic)CGRect oldFrame;
@property(nonatomic)CGRect cutFrame;


-(void)initView;

- (void) pinchView:(UIPinchGestureRecognizer *)pinchGestureRecognizer;
- (void) panView:(UIPanGestureRecognizer *)panGestureRecognizer;
- (CGRect)handleScaleOverflow:(CGRect)newFrame;
- (CGRect)handleBorderOverflow:(CGRect)newFrame;


- (void)cancel:(id)sender;
- (void)confirm:(id)sender;

-(UIImage *)getSubImage;
@end



@implementation PortraitCutVC

@synthesize originalImage;
@synthesize cutSize;
@synthesize maskView;
@synthesize stencilView;
@synthesize scaleRatio;
@synthesize showImgView;
@synthesize screenSize;
@synthesize largeSize;
@synthesize latestFrame;
@synthesize oldFrame;
@synthesize cutFrame;
-(id)initWithImage:(UIImage *)image cutSize:(CGSize)size scaleRatio:(float)scale
    success:(void (^)(UIImage *finalImage))success
{
    
    self = [super init];
    if (self) {
        self.screenSize=[UIScreen mainScreen].bounds.size;
        self.cutSize=size;
        self.originalImage=[self  imageByScalingToMaxSize:image];
        self.scaleRatio=scale;
        
        successBlock=success;
        cutFrame=CGRectMake((screenSize.width-cutSize.width)/2, (screenSize.height-cutSize.height)/2, cutSize.width, cutSize.height);
    }
    return self;
    
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self initView];
}
-(void)initView
{
    [self.view setBackgroundColor:[UIColor blackColor]];
    [self.navigationController setNavigationBarHidden:YES];
    
    //根据传入的image 动态计算imageView 的位置以及大小
    CGFloat oriWidth = self.cutSize.width;
    CGFloat oriHeight = self.originalImage.size.height * (oriWidth / self.originalImage.size.width);
    
    self.oldFrame = CGRectMake(0, 0, oriWidth, oriHeight);
    
    
    //显示图片imageView
    self.showImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, oriWidth, oriHeight)];
    [self.showImgView setImage:self.originalImage];
    [self.showImgView setUserInteractionEnabled:YES];
    [self.showImgView setMultipleTouchEnabled:YES];
    self.showImgView.center=CGPointMake(screenSize.width/2, screenSize.height/2);
    self.latestFrame = self.showImgView.frame;
    [self.view addSubview:self.showImgView];
    NSLog(@"cal rect %@",NSStringFromCGRect(self.latestFrame));
    
    //允许放大的最大size
    self.largeSize = CGSizeMake(self.scaleRatio * self.oldFrame.size.width, self.scaleRatio * self.oldFrame.size.height);
    
    //添加拖动  双指缩放手势
    UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchView:)];
    [self.view addGestureRecognizer:pinchGestureRecognizer];
    
    // add pan gesture
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panView:)];
    [self.view addGestureRecognizer:panGestureRecognizer];
    
    
    
    
//    UIScrollView *scroll=[[UIScrollView alloc]initWithFrame:CGRectMake(0, 0, oriWidth, oriHeight)];
//    scroll.center=CGPointMake(screenSize.width/2, screenSize.height/2);
//    scroll setContentsi
    
    
    self.maskView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.maskView.alpha = .5f;
    self.maskView.backgroundColor = [UIColor blackColor];
    self.maskView.userInteractionEnabled = NO;
    [self.view addSubview:self.maskView];
    
    self.stencilView = [[UIView alloc] initWithFrame:self.cutFrame];
    self.stencilView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.stencilView.layer.borderWidth = 1.0f;
    [self.view addSubview:self.stencilView];
    
    
    //添加 遮罩
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    CGMutablePathRef path = CGPathCreateMutable();
    // 左边矩形
    CGPathAddRect(path, nil, CGRectMake(0, 0,
                                        self.stencilView.frame.origin.x,
                                        self.maskView.frame.size.height));
    // 右边矩形
    CGPathAddRect(path, nil, CGRectMake(
                                        self.stencilView.frame.origin.x + self.stencilView.frame.size.width,
                                        0,
                                        self.maskView.frame.size.width - self.stencilView.frame.origin.x - self.stencilView.frame.size.width,
                                        self.maskView.frame.size.height));
    // 上边矩形
    CGPathAddRect(path, nil, CGRectMake(0, 0,
                                        self.maskView.frame.size.width,
                                        self.stencilView.frame.origin.y));
    // 下边举行
    CGPathAddRect(path, nil, CGRectMake(0,
                                        self.stencilView.frame.origin.y + self.stencilView.frame.size.height,
                                        self.maskView.frame.size.width,
                                        self.maskView.frame.size.height - self.stencilView.frame.origin.y + self.stencilView.frame.size.height));
    maskLayer.path = path;
    self.maskView.layer.mask = maskLayer;
    CGPathRelease(path);

    
    
    
    
    //创建按钮
    float btnBackViewH=55;
    UIView *btnBack=[[UIView alloc]initWithFrame:CGRectMake(0, screenSize.height-btnBackViewH, screenSize.width, btnBackViewH)];
    [btnBack setBackgroundColor:[UIColor colorWithRed:10 green:10 blue:10 alpha:0.5]];
    [self.view addSubview:btnBack];
    
    
    UIButton *cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, btnBack.frame.size.height - 50.0f, 100, 50)];
    cancelBtn.backgroundColor = [UIColor clearColor];
    cancelBtn.titleLabel.textColor = [UIColor whiteColor];
    [cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
    [cancelBtn.titleLabel setFont:[UIFont boldSystemFontOfSize:18.0f]];
    [cancelBtn.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [cancelBtn.titleLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [cancelBtn.titleLabel setNumberOfLines:0];
    [cancelBtn setTitleEdgeInsets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
    [cancelBtn addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
    [btnBack addSubview:cancelBtn];
    
    UIButton *confirmBtn = [[UIButton alloc] initWithFrame:CGRectMake(btnBack.frame.size.width - 100.0f, btnBack.frame.size.height - 50.0f, 100, 50)];
    confirmBtn.backgroundColor = [UIColor clearColor];
    confirmBtn.titleLabel.textColor = [UIColor whiteColor];
    [confirmBtn setTitle:@"确定" forState:UIControlStateNormal];
    [confirmBtn.titleLabel setFont:[UIFont boldSystemFontOfSize:18.0f]];
    [confirmBtn.titleLabel setTextAlignment:NSTextAlignmentCenter];
    confirmBtn.titleLabel.textColor = [UIColor whiteColor];
    [confirmBtn.titleLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [confirmBtn.titleLabel setNumberOfLines:0];
    [confirmBtn setTitleEdgeInsets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
    [confirmBtn addTarget:self action:@selector(confirm:) forControlEvents:UIControlEventTouchUpInside];
    [btnBack addSubview:confirmBtn];
    
    
    
}
- (void)cancel:(id)sender {
   
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)confirm:(id)sender {
    successBlock([self getSubImage]);
   UIViewController *vc= [self.navigationController.viewControllers objectAtIndex:0];
    [vc dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark --
#pragma mark -- Cut Image

-(UIImage *)getSubImage{
    NSLog(@"original imageSize  %@",NSStringFromCGSize(self.originalImage.size));
    NSLog(@"latest image viewframe %@",NSStringFromCGRect(self.latestFrame));
    CGRect squareFrame = self.cutFrame;
    NSLog(@"current cut frame  %@",NSStringFromCGRect(self.cutFrame));
    CGFloat curscaleRatio = self.latestFrame.size.width / self.originalImage.size.width;
    NSLog(@"cur tation  %f",curscaleRatio);
    CGFloat x = (squareFrame.origin.x - self.latestFrame.origin.x) / curscaleRatio;
    CGFloat y = (squareFrame.origin.y - self.latestFrame.origin.y) / curscaleRatio;
    CGFloat w = squareFrame.size.width / curscaleRatio;
    CGFloat h = squareFrame.size.width / curscaleRatio;
    if (self.latestFrame.size.width < self.cutFrame.size.width) {
        CGFloat newW = self.originalImage.size.width;
        CGFloat newH = newW * (self.cutFrame.size.height / self.cutFrame.size.width);
        x = 0; y = y + (h - newH) / 2;
        w = newH; h = newH;
    }
    if (self.latestFrame.size.height < self.cutFrame.size.height) {
        CGFloat newH = self.originalImage.size.height;
        CGFloat newW = newH * (self.cutFrame.size.width / self.cutFrame.size.height);
        x = x + (w - newW) / 2; y = 0;
        w = newH; h = newH;
    }
    
    CGRect myImageRect = CGRectMake(x, y, w, h);
    //操作完毕的图片
    CGImageRef imageRef = self.originalImage.CGImage;
    //操作完毕的图片的 一部分 范围是 （x,y,w,h）
    CGImageRef subImageRef = CGImageCreateWithImageInRect(imageRef, myImageRect);
    CGSize size;
    size.width = myImageRect.size.width;
    size.height = myImageRect.size.height;
    //创建一个context
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //将 subImageRef 绘制到 新的context 里面
    CGContextDrawImage(context, myImageRect, subImageRef);
    //取得 uiimage
    UIImage* smallImage = [UIImage imageWithCGImage:subImageRef];
    UIGraphicsEndImageContext();
    CGImageRelease(subImageRef);
    NSLog(@"finish size %@",NSStringFromCGSize(smallImage.size));
    return smallImage;
    
    return nil;
}


#pragma mark --
#pragma mark -- Gesture method

- (CGRect)handleScaleOverflow:(CGRect)newFrame {
    // bounce to original frame
    CGPoint oriCenter = CGPointMake(newFrame.origin.x + newFrame.size.width/2, newFrame.origin.y + newFrame.size.height/2);
    if (newFrame.size.width < self.oldFrame.size.width) {
        newFrame = self.oldFrame;
    }
    if (newFrame.size.width > self.largeSize.width) {
        newFrame .size= self.largeSize;
    }
    newFrame.origin.x = oriCenter.x - newFrame.size.width/2;
    newFrame.origin.y = oriCenter.y - newFrame.size.height/2;
    return newFrame;
}
- (CGRect)handleBorderOverflow:(CGRect)newFrame {
    // horizontally
    if (newFrame.origin.x > self.cutFrame.origin.x) newFrame.origin.x = self.cutFrame.origin.x;
    if (CGRectGetMaxX(newFrame) < CGRectGetMaxX(self.cutFrame)) newFrame.origin.x =CGRectGetMaxX(self.cutFrame) - newFrame.size.width;
    // vertically
    if (newFrame.origin.y > self.cutFrame.origin.y) newFrame.origin.y = self.cutFrame.origin.y;
    
    if (CGRectGetMaxY(newFrame) < CGRectGetMaxY(self.cutFrame)) {
        newFrame.origin.y = CGRectGetMaxY(self.cutFrame) - newFrame.size.height;
    }
    
    // adapt horizontally rectangle
    if (self.showImgView.frame.size.width > self.showImgView.frame.size.height && newFrame.size.height <= self.cutFrame.size.height) {
        newFrame.origin.y = self.cutFrame.origin.y + (self.cutFrame.size.height - newFrame.size.height) / 2;
    }
    return newFrame;
}

- (void) pinchView:(UIPinchGestureRecognizer *)pinchGestureRecognizer
{
    UIView *view = self.showImgView;
    if (pinchGestureRecognizer.state == UIGestureRecognizerStateBegan || pinchGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        
        //x y 方向 应用 scale 变换
        view.transform = CGAffineTransformScale(view.transform, pinchGestureRecognizer.scale, pinchGestureRecognizer.scale);
        
        //每次缩放完毕后 缩放值归位为1 不需要累加到下一次
        pinchGestureRecognizer.scale = 1;
    }
    else if (pinchGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        CGRect newFrame = self.showImgView.frame;
        newFrame = [self handleScaleOverflow:newFrame];
        newFrame = [self handleBorderOverflow:newFrame];
        [UIView animateWithDuration:BOUNDCE_DURATION animations:^{
            self.showImgView.frame = newFrame;
            self.latestFrame = newFrame;
        }];
    }
}

// pan gesture handler
- (void) panView:(UIPanGestureRecognizer *)panGestureRecognizer
{
    UIView *view = self.showImgView;
    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan || panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        // calculate accelerator
        CGFloat absCenterX = self.cutFrame.origin.x + self.cutFrame.size.width / 2;
        CGFloat absCenterY = self.cutFrame.origin.y + self.cutFrame.size.height / 2;
        CGFloat curscaleRatio = self.showImgView.frame.size.width / self.cutFrame.size.width;
        CGFloat acceleratorX = 1 - ABS(absCenterX - view.center.x) / (curscaleRatio * absCenterX);
        CGFloat acceleratorY = 1 - ABS(absCenterY - view.center.y) / (curscaleRatio * absCenterY);
        CGPoint translation = [panGestureRecognizer translationInView:view.superview];
        [view setCenter:(CGPoint){view.center.x + translation.x * acceleratorX, view.center.y + translation.y * acceleratorY}];
        [panGestureRecognizer setTranslation:CGPointZero inView:view.superview];
    }
    else if (panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        // bounce to original frame
        CGRect newFrame = self.showImgView.frame;
        newFrame = [self handleBorderOverflow:newFrame];
        [UIView animateWithDuration:BOUNDCE_DURATION animations:^{
            self.showImgView.frame = newFrame;
            self.latestFrame = newFrame;
        }];
    }
}



- (UIImage *)imageByScalingToMaxSize:(UIImage *)sourceImage {
    float screenScale=[UIScreen mainScreen].scale;
    CGFloat screenW=screenSize.width*screenScale;
    if (sourceImage.size.width < screenW) return sourceImage;
    CGFloat btWidth = 0.0f;
    CGFloat btHeight = 0.0f;
    
        
    btWidth = screenW;
    btHeight = sourceImage.size.height * (screenW / sourceImage.size.width);
    
    CGSize targetSize = CGSizeMake(btWidth, btHeight);
    return [self imageByScalingAndCroppingForSourceImage:sourceImage targetSize:targetSize];
}

- (UIImage *)imageByScalingAndCroppingForSourceImage:(UIImage *)sourceImage targetSize:(CGSize)targetSize {
    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    if (CGSizeEqualToSize(imageSize, targetSize) == NO)
    {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor > heightFactor)
            scaleFactor = widthFactor; // scale to fit height
        else
            scaleFactor = heightFactor; // scale to fit width
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        if (widthFactor > heightFactor)
        {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        }
        else
            if (widthFactor < heightFactor)
            {
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
            }
    }
    UIGraphicsBeginImageContext(targetSize); // this will crop
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if(newImage == nil) NSLog(@"could not scale image");
    
    //pop the context to get back to the default
    UIGraphicsEndImageContext();
    return newImage;
}



- (void)dealloc {
    self.originalImage = nil;
    self.showImgView = nil;
    
}
@end
