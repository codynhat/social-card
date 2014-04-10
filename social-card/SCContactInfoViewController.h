//
//  SCContactInfoViewController.h
//  social-card
//
//  Created by Cody Hatfield on 2/27/14.
//  Copyright (c) 2014 Cody Hatfield. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCContactInfoViewController : UIViewController <UITextFieldDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate>

- (void)keyboardOnScreen:(NSNotification *)notification;

@property (weak, nonatomic) IBOutlet UIButton *profButton;
-(void)showCameraSource:(NSInteger)index;
- (IBAction)changePic:(id)sender;

- (IBAction)done:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UITextField *firstNameField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameField;
@property (weak, nonatomic) IBOutlet UITextField *numberField;
@end
