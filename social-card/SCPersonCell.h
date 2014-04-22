//
//  SCPersonCell.h
//  social-card
//
//  Created by Cody Hatfield on 2/20/14.
//  Copyright (c) 2014 Cody Hatfield. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCPersonCell : UITableViewCell


@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UIImageView *profPic;
@property (weak, nonatomic) IBOutlet UIImageView *check;

@end
