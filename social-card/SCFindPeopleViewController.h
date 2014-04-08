//
//  SCFindPeopleViewController.h
//  social-card
//
//  Created by Cody Hatfield on 2/18/14.
//  Copyright (c) 2014 Cody Hatfield. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCTransfer.h"
#import "MBProgressHUD.h"
#import <MessageUI/MessageUI.h>

@interface SCFindPeopleViewController : UITableViewController <SCTransferDelegate, MFMessageComposeViewControllerDelegate, UIAlertViewDelegate>{
    NSMutableArray *peers;
    NSMutableArray *connectedPeers;
    
    MCPeerID *current_peer;

}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *settingsButton;

-(void)showText:(NSData*)contact;
@end
