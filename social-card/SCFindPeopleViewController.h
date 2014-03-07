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

@interface SCFindPeopleViewController : UITableViewController <SCTransferDelegate>{
    NSMutableArray *peers;
    NSMutableArray *connectedPeers;
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *settingsButton;

@end
