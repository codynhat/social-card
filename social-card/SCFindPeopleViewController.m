//
//  SCFindPeopleViewController.m
//  social-card
//
//  Created by Cody Hatfield on 2/18/14.
//  Copyright (c) 2014 Cody Hatfield. All rights reserved.
//

#import "SCFindPeopleViewController.h"
#import "SCPersonCell.h"
#import "SCContactInfoViewController.h"
#import "UIColor+SCColor.h"

@interface SCFindPeopleViewController ()

@end

@implementation SCFindPeopleViewController

- (id)initWithCoder:(NSCoder*)aDecoder
{
    if(self = [super initWithCoder:aDecoder])
    {
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    // Remove extra lines
    self.tableView.tableFooterView = [[UIView alloc] init];

    [self.tableView setBackgroundColor:[UIColor scContentColor]];
    
    peers = [NSMutableArray new];
    connectedPeers = [NSMutableArray new];
    
    [[SCTransfer sharedInstance] start];
    [SCTransfer sharedInstance].delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)showText:(NSData*)contact{
    NSDictionary *contactInfo = [NSKeyedUnarchiver unarchiveObjectWithData:contact];

    if ([MFMessageComposeViewController canSendText] && [MFMessageComposeViewController canSendAttachments] && [MFMessageComposeViewController isSupportedAttachmentUTI:@"public.vcard"]) {
        MFMessageComposeViewController *vc = [[MFMessageComposeViewController alloc] init];
        vc.messageComposeDelegate = self;
        vc.recipients = [NSArray arrayWithObject:[contactInfo objectForKey:@"phone_number"]];
        
        NSDictionary *myContact = [NSKeyedUnarchiver unarchiveObjectWithData:[[SCTransfer sharedInstance] contactInfo]];

        vc.body = [NSString stringWithFormat:@"Hey %@, this is %@. This was sent using SocialCard, check it out! http://bit.ly/1gEH52F", [contactInfo objectForKey:@"first_name"], [myContact objectForKey:@"first_name"]];
        
        
        [vc addAttachmentData:[[[SCTransfer sharedInstance] vCardRepresentation] dataUsingEncoding:NSUTF8StringEncoding] typeIdentifier:@"public.vcard" filename:[NSString stringWithFormat:@"%@%@.vcf", [myContact objectForKey:@"first_name"], [myContact objectForKey:@"last_name"]]];
        
        [self presentViewController:vc animated:YES completion:nil];
    }
    
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return connectedPeers.count;
    }
    else if (section == 1){
        return peers.count;
    }
    else{
        return 1;
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"personCell";
    SCPersonCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    
    [cell.activityIndicator stopAnimating];
    
    if (indexPath.section < 2) {
        // Peer cell
        
        // Border and radius
        cell.profPic.layer.borderWidth = 0.4;
        cell.profPic.layer.borderColor = [[UIColor scBackgroundColor] CGColor];
        cell.profPic.layer.cornerRadius = (cell.profPic.frame.size.width/2);
        
        NSArray *p;
        if (indexPath.section == 0) {
            // Connected Peers
            p = connectedPeers;
            
            cell.name.textColor = [UIColor scGreenColor];
            
        }
        else{
            // Discovered Peers
            p = peers;
            cell.name.textColor = [UIColor blackColor];
        }
        
        MCPeerID *peer_id = [p objectAtIndex:indexPath.row];
        
        cell.name.text = peer_id.displayName;
        
        if (p == peers && [[[SCTransfer sharedInstance] sentInvites] containsObject:peer_id]) {
            [cell.activityIndicator startAnimating];
        }
    }
    else{
        // Other person cell
        
        cell.profPic.image = nil;
        cell.name.text = @"Add Other Person...";
        cell.name.font = [UIFont boldSystemFontOfSize:18.0];
        
    }
    
    
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section == 1) {
        // Peer selected
        
        MCPeerID *peer_id = [peers objectAtIndex:indexPath.row];
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        [[SCTransfer sharedInstance] invitePeer:peer_id];
        
        /*float r = ((arc4random() % 40) + 30)/10;
        [[SCTransfer sharedInstance] performSelector:@selector(invitePeer:) withObject:peer_id afterDelay:r];*/
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });

    }
    else if (indexPath.section == 2) {
        // Add other person...
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"First Name" message:@"What is the first name of the person you would like to add?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Next", nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alert show];
        
    }

}

-(BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0) {
        return NO;
    }
    return YES;
}




#pragma mark SCTransfer Delegate methods

-(void)foundPeer:(MCPeerID *)peer{

    if ([[[SCTransfer sharedInstance] allConnectedDevices] containsObject:peer]) {
        [connectedPeers addObject:peer];
    }
    else{
        [peers addObject:peer];
    }
    
    [self.tableView reloadData];
}

-(void)lostPeer:(MCPeerID *)peer{
    [peers removeObject:peer];
    [connectedPeers removeObject:peer];
    
    [self.tableView reloadData];
}

-(void)peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
    if (state == 2) {
        // If connected
        [connectedPeers addObject:peerID];
        [peers removeObject:peerID];
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
        
        
        // Send the contact
        [[SCTransfer sharedInstance] sendContact:[[SCTransfer sharedInstance] contactInfo] toPeer:peerID];
    }
    else if (state == 0){
        // Disconnected
        
        if ([peers containsObject:peerID]) {
            [peers removeObject:peerID];
        }
        if ([connectedPeers containsObject:peerID]) {
            [peers removeObject:peerID];
        }
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }
    
}

- (void)didFinishAddingContact:(NSData*)contact{
    NSDictionary *c = [NSKeyedUnarchiver unarchiveObjectWithData:contact];

    //NSLog(@"CONTACT ADDED: %@", c);
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        [hud setMode:MBProgressHUDModeText];
        
        [hud setLabelText:[NSString stringWithFormat:@"\"%@ %@\" was added.", [c objectForKey:@"first_name"], [c objectForKey:@"last_name"] ]];
        [hud hide:YES afterDelay:2.0];
    });
    
}

-(void)clearPeers{
    peers = [NSMutableArray new];
    connectedPeers = [NSMutableArray new];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark UIAlertViewDelegate Methods

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    static int count = 0;
    static NSString *first_name = @"";
    static NSString *last_name = @"";
    static NSString *phone_number = @"";
    
    if (buttonIndex == 1) {
        
        
        if (count == 0) {
            first_name = [alertView textFieldAtIndex:0].text;
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Last Name" message:@"What is their last name?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Next", nil];
            alert.alertViewStyle = UIAlertViewStylePlainTextInput;
            [alert show];
        }
        else if (count == 1) {
            last_name = [alertView textFieldAtIndex:0].text;
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Phone Number" message:@"What is their phone number?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Next", nil];
            alert.alertViewStyle = UIAlertViewStylePlainTextInput;
            [alert show];
        }
        else{
            //NSLog(@"NAME: %@ %@", first_name, last_name);
            phone_number = [alertView textFieldAtIndex:0].text;
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:@{@"first_name": first_name,
                                                                                        @"last_name": last_name,
                                                                                        @"phone_number": phone_number}];
            NSData *contact = [NSKeyedArchiver archivedDataWithRootObject:dict];
            
            [[SCTransfer sharedInstance] addContact:contact];
            
            [self showText:contact];
            
        }
        count++;
    }
}

#pragma mark MFMessageComposeViewControllerDelegate



-(void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result{
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
