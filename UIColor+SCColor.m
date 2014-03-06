//
//  UIColor+SCColor.m
//  social-card
//
//  Created by Cody Hatfield on 3/6/14.
//  Copyright (c) 2014 Cody Hatfield. All rights reserved.
//

#import "UIColor+SCColor.h"

@implementation UIColor (SCColor)

+(UIColor*)scTextColor{
    return [UIColor whiteColor];
}

+(UIColor*)scContentColor{
    return [UIColor whiteColor];
}

+(UIColor*)scBackgroundColor{
    return [UIColor colorWithRed:0.0/255.0 green:204.0/255.0 blue:199.0/255.0 alpha:1.0];
}

+(UIColor*)scGreenColor{
    return [UIColor colorWithRed:11.0/255.0 green:217.0/255.0 blue:95.0/255.0 alpha:1.0];
}

@end
