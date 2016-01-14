//
//  ZXImagePickerViewController.m
//  UEnAi
//
//  Created by zhangxu on 15/3/18.
//  Copyright (c) 2015年 zhangxu. All rights reserved.
//

#import "ZXImagePickerViewController.h"
#import "PortraitCutVC.h"
#import <MobileCoreServices/MobileCoreServices.h>
typedef void(^SuccessBlock)(UIImage *finalImage);
@interface ZXImagePickerViewController ()
{
    BOOL isCut;
    SuccessBlock successBlock;
    UIViewController *rootVC;
}

-(void)remove;
- (UIViewController *)getCurrentVC;
@end

@implementation ZXImagePickerViewController


- (UIViewController *)getCurrentVC
{
    UIViewController *result = nil;
    
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal)
    {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * tmpWin in windows)
        {
            if (tmpWin.windowLevel == UIWindowLevelNormal)
            {
                window = tmpWin;
                break;
            }
        }
    }
    
    UIView *frontView = [[window subviews] objectAtIndex:0];
    id nextResponder = [frontView nextResponder];
    
    if ([nextResponder isKindOfClass:[UIViewController class]])
        result = nextResponder;
    else
        result = window.rootViewController;
    
    return result;
}

+ (UIViewController*) getTopMostViewController
{
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(window in windows) {
            if (window.windowLevel == UIWindowLevelNormal) {
                break;
            }
        }
    }
    
    for (UIView *subView in [window subviews])
    {
        UIResponder *responder = [subView nextResponder];
        
        //added this block of code for iOS 8 which puts a UITransitionView in between the UIWindow and the UILayoutContainerView
        if ([responder isEqual:window])
        {
            //this is a UITransitionView
            if ([[subView subviews] count])
            {
                UIView *subSubView = [subView subviews][0]; //this should be the UILayoutContainerView
                responder = [subSubView nextResponder];
            }
        }
        
        if([responder isKindOfClass:[UIViewController class]]) {
            return [self topViewController: (UIViewController *) responder];
        }
    }
    
    return nil;
}

+ (UIViewController *) topViewController: (UIViewController *) controller
{
    BOOL isPresenting = NO;
    do {
        // this path is called only on iOS 6+, so -presentedViewController is fine here.
        UIViewController *presented = [controller presentedViewController];
        isPresenting = presented != nil;
        if(presented != nil) {
            controller = presented;
        }
        
    } while (isPresenting);
    
    return controller;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    rootVC=[ZXImagePickerViewController getTopMostViewController];
   // rootVC=[UIApplication sharedApplication].keyWindow.rootViewController;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)showWithCutView:(BOOL)showCut  completion:(void (^)(UIImage *finalImage))block;
{
    isCut=showCut;
    successBlock=block;
    [[UIApplication sharedApplication].keyWindow addSubview:self.view];
    UIActionSheet *choiceSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:(id)self
                                                    cancelButtonTitle:@"取消"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"拍照", @"从相册中选取", nil];
    [choiceSheet showInView:self.view];
    
    
    
    
    [rootVC addChildViewController:self];
}

-(void)remove
{
    [self removeFromParentViewController];
}


#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self.view removeFromSuperview];
    if (buttonIndex == 0) {
        // 拍照
        
        //  if ([self isCameraAvailable] && [self doesCameraSupportTakingPhotos]) {
        UIImagePickerController *controller = [[UIImagePickerController alloc] init];
        controller.sourceType = UIImagePickerControllerSourceTypeCamera;
        //            if ([self isFrontCameraAvailable]) {
        //                controller.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        //            }
        NSMutableArray *mediaTypes = [[NSMutableArray alloc] init];
        [mediaTypes addObject:(__bridge NSString *)kUTTypeImage];
        controller.mediaTypes = mediaTypes;
        controller.delegate = (id)self;
        [rootVC presentViewController:controller
                           animated:YES
                         completion:^(void){
                             NSLog(@"Picker View Controller is presented");
                         }];
        //  }
        
    } else if (buttonIndex == 1) {
        // 从相册中选取
        // if ([self isPhotoLibraryAvailable]) {
        @try{
           
            UIImagePickerController *controller = [[UIImagePickerController alloc] init];
            controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            NSMutableArray *mediaTypes = [[NSMutableArray alloc] init];
            
            //过滤 只显示图片
            [mediaTypes addObject:(__bridge NSString *)kUTTypeImage];
            controller.mediaTypes = mediaTypes;
            controller.delegate = (id)self;
            
            
            // __weak ZXImagePickerViewController *vc=self;
            [rootVC presentViewController:controller
                                 animated:YES
                               completion:^(void){
                                   
                               }];
        }
        @catch(NSException *exception) {
            NSLog(@"exception:%@", exception);
        }
        @finally {
            
        }
       
        //  }
    }
}



#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    //用户选择的图片
    UIImage *portraitImg = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    
    //屏幕的尺寸
    CGSize size=[UIScreen mainScreen].bounds.size;
    
    //自己实现的图片截取，缩小 viewController 稍后详细解释
    
    if (isCut) {
        PortraitCutVC *portraitVC=[[PortraitCutVC alloc]initWithImage:portraitImg cutSize:CGSizeMake(size.width, size.width) scaleRatio:3.0
                                                              success:^(UIImage *image){
                                                                  //截取成功 设置头像
                                                                  
                                                                  //上传头像到服务器
                                                                  successBlock(image);
                                                                  [picker dismissViewControllerAnimated:YES completion:nil];
                                                                  [self remove];
                                                              }];
        
        [picker pushViewController:portraitVC animated:YES];
    }else
    {
        successBlock(portraitImg);
        [picker dismissViewControllerAnimated:YES completion:nil];
        [self remove];
    }
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    successBlock(nil);
    [self remove];
    [picker dismissViewControllerAnimated:YES completion:^(){
       
    }];
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
