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
#import "UIColor+SCColor.h"
#import "UIImage+Resize.h"

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
    
    
    self.navigationItem.hidesBackButton = YES;
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"Play" size:18.0], NSFontAttributeName, [UIColor scTextColor], NSForegroundColorAttributeName, nil] forState:UIControlStateNormal];
    

    
    
    SCTransfer *scTransfer = [SCTransfer sharedInstance];
    
    statusLabel.font = [UIFont fontWithName:@"Play" size:18.0];
    
    if ([scTransfer contactInfo]) {
        NSDictionary *contact = [NSKeyedUnarchiver unarchiveObjectWithData:[scTransfer contactInfo]];
        
        [firstNameField setText:[contact objectForKey:@"first_name"]];
        [lastNameField setText:[contact objectForKey:@"last_name"]];
        [numberField setText:[contact objectForKey:@"phone_number"]];
        [statusLabel setText:@"Update your contact info."];
        
        UIImage *prof_pic = [UIImage imageWithData:[contact objectForKey:@"prof_pic"]];
        if (prof_pic) {
            [_profButton setImage:prof_pic forState:UIControlStateNormal];
        }
    }
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (IBAction)changePic:(id)sender {

    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Clear Photo" otherButtonTitles:@"Take Picture", @"Choose Picture", nil];
        
        [actionSheet showInView:self.navigationController.view];
    }
    else if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        [self showCameraSource:1];
    }
    else if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]){
        [self showCameraSource:2];
    }
    
}

-(void)showCameraSource:(NSInteger)index{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.allowsEditing = YES;
    imagePicker.delegate = self;

    if (index == 0) {
        // Clear Photo
        
        [_profButton setImage:nil forState:UIControlStateNormal];
    }
    if (index == 1) {
        // Camera
        [imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
    else if(index == 2){
        // Library
        [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        [self presentViewController:imagePicker animated:YES completion:nil];

    }
    
    
    

}

- (IBAction)done:(id)sender {
    
    [statusLabel setText:@""];
    

    // Check if all fields are valid
    if (firstNameField.text.length == 0 || lastNameField.text.length == 0 || numberField.text.length == 0) {
        UIScrollView *scrollView = (UIScrollView*)self.view;
        [scrollView scrollRectToVisible:CGRectMake(0, statusLabel.frame.origin.y+216+64, statusLabel.frame.size.width, statusLabel.frame.size.height) animated:YES];

        [statusLabel setText:@"Please enter a value in every field."];
        return;
    }
    
    
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:@{@"first_name": firstNameField.text,
                                                                                @"last_name": lastNameField.text,
                                                                                @"phone_number": numberField.text}];
    //NSData *image = UIImageJPEGRepresentation([[_profButton imageForState:UIControlStateNormal] resizedImageToSize:CGSizeMake(60, 60)], 0.5);
    
    /*if (image) {
        [dict setObject:image forKey:@"prof_pic"];
    }*/
    
    NSData *contact = [NSKeyedArchiver archivedDataWithRootObject:dict];
    [[SCTransfer sharedInstance] setContactInfo:contact];
    
    
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    else{
        SCFindPeopleViewController *findPeople = [self.storyboard instantiateViewControllerWithIdentifier:@"findPeople"];
        [self.navigationController pushViewController:findPeople animated:YES];
        [self.navigationController setViewControllers:[NSArray arrayWithObject:findPeople]];
    }
    
    
}

#pragma mark UITextField Delegate methods

-(BOOL)textFieldShouldReturn:(UITextField*)textField;
{
    NSInteger nextTag = textField.tag + 1;
    // Try to find next responder
    UIResponder* nextResponder = [textField.superview viewWithTag:nextTag];
    if (nextResponder) {
        // Found next responder, so set it.
        [nextResponder becomeFirstResponder];
    } else {
        // Not found, so remove keyboard.
        [textField resignFirstResponder];
    }
    return NO; // We do not want UITextField to insert line-breaks.
}


-(void)textFieldDidBeginEditing:(UITextField *)textField{
    UIScrollView *scrollView = (UIScrollView*)self.view;
    
    
    [scrollView setContentSize:CGSizeMake(scrollView.frame.size.width, scrollView.frame.size.height+150)];
    [scrollView scrollRectToVisible:CGRectMake(0, textField.frame.origin.y+216+64, textField.frame.size.width, textField.frame.size.height) animated:YES];

   
}

#pragma mark UIActionSheetDelegate methods

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    [self showCameraSource:buttonIndex];
}

#pragma mark UIImagePickerControllerDelegate methods

-(void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    
    if (image) {
        [_profButton setImage:image forState:UIControlStateNormal];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
