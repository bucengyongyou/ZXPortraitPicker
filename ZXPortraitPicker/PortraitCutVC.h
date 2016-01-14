//
//  PortraitCutVC.h
//  NetTest
//
//  Created by zhangxu on 15/3/4.
//  Copyright (c) 2015年 zhangxu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PortraitCutVC : UIViewController



-(id )initWithImage:(UIImage *)image cutSize:(CGSize)size scaleRatio:(float)scale
            success:(void (^)(UIImage *finalImage))success;
@end
