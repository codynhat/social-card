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
#import "KeenClient.h"

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

    UIImageView *background = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TableBackground"]];
    background.contentMode = UIViewContentModeBottom;
    self.tableView.backgroundView = background;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)showText:(NSData*)contact{
    NSDictionary *contactInfo = [NSKeyedUnarchiver unarchiveObjectWithData:contact];
    
    NSMutableDictionary *event = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], @"can_send", nil];

    if ([MFMessageComposeViewController canSendText] && [MFMessageComposeViewController canSendAttachments] && [MFMessageComposeViewController isSupportedAttachmentUTI:@"public.vcard"]) {
        MFMessageComposeViewController *vc = [[MFMessageComposeViewController alloc] init];
        vc.messageComposeDelegate = self;
        vc.recipients = [NSArray arrayWithObject:[contactInfo objectForKey:@"phone_number"]];
        
        NSDictionary *myContact = [NSKeyedUnarchiver unarchiveObjectWithData:[[SCTransfer sharedInstance] contactInfo]];

        vc.body = [NSString stringWithFormat:@"Hey %@, this is %@. This was sent using SocialCard, check it out! http://bit.ly/1gEH52F", [contactInfo objectForKey:@"first_name"], [myContact objectForKey:@"first_name"]];
        
        
        [vc addAttachmentData:[[[SCTransfer sharedInstance] vCardRepresentation] dataUsingEncoding:NSUTF8StringEncoding] typeIdentifier:@"public.vcard" filename:[NSString stringWithFormat:@"%@%@.vcf", [myContact objectForKey:@"first_name"], [myContact objectForKey:@"last_name"]]];
        
        [self presentViewController:vc animated:YES completion:nil];
        
        [event setObject:[NSNumber numberWithBool:NO] forKey:@"can_send"];
    }
    
    [[KeenClient sharedClient] addEvent:event toEventCollection:@"show_text" error:nil];

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
        cell.profPic.image = [UIImage imageNamed:@"ProfilePic"];
        cell.name.font = [UIFont systemFontOfSize:18.0];
        
        // Border and radius
        cell.profPic.layer.borderWidth = 0.4;
        cell.profPic.layer.borderColor = [[UIColor scBackgroundColor] CGColor];
        cell.profPic.layer.cornerRadius = (cell.profPic.frame.size.width/2);
        
        [cell.check setImage:nil];
        
        NSArray *p;
        if (indexPath.section == 0) {
            // Connected Peers
            p = connectedPeers;
            
            [cell.check setImage:[UIImage imageNamed:@"Checkmark"]];
            
            
        }
        else{
            // Discovered Peers
            p = peers;
        }
        
        MCPeerID *peer_id = [p objectAtIndex:indexPath.row];
        
        cell.name.text = peer_id.displayName;
        
        if (p == peers && [[[SCTransfer sharedInstance] sentInvites] containsObject:peer_id]) {
            [cell.activityIndicator startAnimating];
        }
    }
    else{
        // Other person cell
        
        cell.profPic.layer.borderWidth = 0.0;
        cell.profPic.image = nil;
        cell.name.text = @"Add Someone Else...";
        cell.name.font = [UIFont boldSystemFontOfSize:18.0];
        [cell.check setImage:nil];
        
    }
    
    
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section == 1) {
        // Peer selected
        
        MCPeerID *peer_id = [peers objectAtIndex:indexPath.row];
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        NSArray *people = [[SCTransfer sharedInstance] cacheName:peer_id.displayName];
        
        if (people.count > 0) {
            current_peer = peer_id;
            NSString *message = [NSString stringWithFormat:@"There is already someone with the name %@ in your contacts. Would you still like to add this contact?", peer_id.displayName];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Duplicate Contact" message:message delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
            [alert show];
        }
        else{
            [[SCTransfer sharedInstance] invitePeer:peer_id];
            
            /*float r = ((arc4random() % 40) + 30)/10;
             [[SCTransfer sharedInstance] performSelector:@selector(invitePeer:) withObject:peer_id afterDelay:r];*/
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
        
        

    }
    else if (indexPath.section == 2) {
        // Add other person...
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"First Name" message:@"What is the first name of the person you would like to add?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Next", nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alert show];
        
        [[KeenClient sharedClient] addEvent:@{@"step": [NSNumber numberWithInt:1]} toEventCollection:@"add_other" error:nil];

        
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
        

    }
    else if (state == 0){
        // Disconnected
        
        if ([connectedPeers containsObject:peerID]) {

            [connectedPeers removeObject:peerID];
            [peers addObject:peerID];
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
    
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Yes"]) {
        // Invite person
        
        [[SCTransfer sharedInstance] invitePeer:current_peer];
        
        /*float r = ((arc4random() % 40) + 30)/10;
         [[SCTransfer sharedInstance] performSelector:@selector(invitePeer:) withObject:peer_id afterDelay:r];*/
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }
    else if (buttonIndex == 1) {
        
        
        if (count == 0) {
            first_name = [alertView textFieldAtIndex:0].text;
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Last Name" message:@"What is their last name?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Next", nil];
            alert.alertViewStyle = UIAlertViewStylePlainTextInput;
            [alert show];
            
            [[KeenClient sharedClient] addEvent:@{@"step": [NSNumber numberWithInt:2]} toEventCollection:@"add_other" error:nil];

        }
        else if (count == 1) {
            last_name = [alertView textFieldAtIndex:0].text;
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Phone Number" message:@"What is their phone number?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Next", nil];
            alert.alertViewStyle = UIAlertViewStylePlainTextInput;
            [alert show];
            
            [[KeenClient sharedClient] addEvent:@{@"step": [NSNumber numberWithInt:3]} toEventCollection:@"add_other" error:nil];

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
    
    NSMutableDictionary *event = [NSMutableDictionary new];
    
    [event setObject:[NSNumber numberWithInt:result] forKey:@"result"];


    [[KeenClient sharedClient] addEvent:event toEventCollection:@"text_sent" error:nil];

}


@end
