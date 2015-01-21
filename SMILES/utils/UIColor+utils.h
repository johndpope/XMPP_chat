//
//  UIColor+utils.h
//  SMILES
//
//  Created by asepmoels on 7/11/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (utils)
- (UIColor *)colorByDarkeningColor;
- (UIColor *)colorByChangingAlphaTo:(CGFloat)newAlpha;
@end
