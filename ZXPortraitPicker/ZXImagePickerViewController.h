//
//  ZXImagePickerViewController.h
//  UEnAi
//
//  Created by zhangxu on 15/3/18.
//  Copyright (c) 2015年 zhangxu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZXImagePickerViewController : UIViewController

@property(nonatomic,strong)UIViewController *presentVC;
-(void)showWithCutView:(BOOL)showCut  completion:(void (^)(UIImage *finalImage))block;
@end
