//
//  SCNavigationController.m
//  social-card
//
//  Created by Cody Hatfield on 2/27/14.
//  Copyright (c) 2014 Cody Hatfield. All rights reserved.
//

#import "SCNavigationController.h"
#import "SCFindPeopleViewController.h"
#import "SCContactInfoViewController.h"
#import "UIColor+SCColor.h"

@interface SCNavigationController ()

@end

@implementation SCNavigationController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
       
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"Play-Bold" size:20.0], NSFontAttributeName, [UIColor scTextColor], NSForegroundColorAttributeName, nil]];
    [self.navigationBar setBarTintColor:[UIColor scBackgroundColor]];
    [self.navigationBar setTintColor:[UIColor scTextColor]];
    
    [self checkForContactInfo];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)checkForContactInfo{
    SCFindPeopleViewController *findPeople = [self.storyboard instantiateViewControllerWithIdentifier:@"findPeople"];
    SCContactInfoViewController *contact = [self.storyboard instantiateViewControllerWithIdentifier:@"contactInfo"];
    
    SCTransfer *scTransfer = [SCTransfer sharedInstance];
    
    if ([scTransfer contactInfo]) {
        [self setViewControllers:[NSArray arrayWithObject:findPeople]];
    }
    else{
        [self setViewControllers:[NSArray arrayWithObject:contact]];
    }
}

@end
