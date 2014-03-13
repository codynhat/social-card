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

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        
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

    peers = [NSMutableArray new];
    connectedPeers = [NSMutableArray new];
    
    [[SCTransfer sharedInstance] start];
    [SCTransfer sharedInstance].delegate = self;
    
    
    [self.tableView setBackgroundColor:[UIColor scContentColor]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return connectedPeers.count;
    }
    else{
        return peers.count;
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"personCell";
    SCPersonCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    [cell.activityIndicator stopAnimating];
    
    cell.profPic.layer.borderWidth = 0.4;
    cell.profPic.layer.borderColor = [[UIColor scBackgroundColor] CGColor];
    cell.profPic.layer.cornerRadius = (cell.profPic.frame.size.width/2);
    
    NSArray *p;
    if (indexPath.section == 0) {
        p = connectedPeers;
        
        cell.name.textColor = [UIColor scGreenColor];

    }
    else{
        p = peers;
    }
    
    MCPeerID *peer_id = [p objectAtIndex:indexPath.row];
    
    cell.name.text = peer_id.displayName;
    
    if (p == peers && [[[SCTransfer sharedInstance] sentInvites] containsObject:peer_id]) {
        [cell.activityIndicator startAnimating];
    }
    
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section == 1) {
        MCPeerID *peer_id = [peers objectAtIndex:indexPath.row];
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        [[SCTransfer sharedInstance] invitePeer:peer_id];
        
        /*float r = ((arc4random() % 40) + 30)/10;
        [[SCTransfer sharedInstance] performSelector:@selector(invitePeer:) withObject:peer_id afterDelay:r];*/
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });

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
    [peers addObject:peer];
    [self.tableView reloadData];
}

-(void)lostPeer:(MCPeerID *)peer{
    [peers removeObject:peer];
    [self.tableView reloadData];
}

-(void)peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
    if (state == 2) {
        // If connected
        for(NSDictionary *d in peers){
            [connectedPeers addObject:d];
            [peers removeObject:d];
        }
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
        
        
        // Send the contact
        [[SCTransfer sharedInstance] sendContact:[[SCTransfer sharedInstance] contactInfo] toPeer:peerID];
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

@end
