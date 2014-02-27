//
//  SCContactInfoViewController.m
//  social-card
//
//  Created by Cody Hatfield on 2/27/14.
//  Copyright (c) 2014 Cody Hatfield. All rights reserved.
//

#import "SCContactInfoViewController.h"
#import "SCTransfer.h"
#import "SCFindPeopleViewController.h"

@interface SCContactInfoViewController ()

@end

@implementation SCContactInfoViewController
@synthesize numberField, firstNameField, lastNameField, statusLabel;

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
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)done:(id)sender {
    [statusLabel setText:@""];
    
    // Check if all fields are valid
    if (firstNameField.text.length == 0 || lastNameField.text.length == 0 || numberField.text.length == 0) {
        [statusLabel setText:@"Please enter a value in every field"];
        return;
    }
    
    NSDictionary *dict = @{@"first_name": firstNameField.text,
                           @"last_name": lastNameField.text,
                           @"phone_number": numberField.text};
    
    NSData *contact = [NSKeyedArchiver archivedDataWithRootObject:dict];
    [[SCTransfer sharedInstance] setContactInfo:contact];
    
    
    SCFindPeopleViewController *findPeople = [self.storyboard instantiateViewControllerWithIdentifier:@"findPeople"];
    [self.navigationController pushViewController:findPeople animated:YES];
    [self.navigationController setViewControllers:[NSArray arrayWithObject:findPeople]];
    
}
@end
