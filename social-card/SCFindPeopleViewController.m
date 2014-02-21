//
//  SCFindPeopleViewController.m
//  social-card
//
//  Created by Cody Hatfield on 2/18/14.
//  Copyright (c) 2014 Cody Hatfield. All rights reserved.
//

#import "SCFindPeopleViewController.h"
#import "SCPersonCell.h"

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return peers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"personCell";
    SCPersonCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    MCPeerID *peer_id = [peers objectAtIndex:indexPath.row];
    
    [cell.activityIndicator stopAnimating];
    
    cell.name.text = peer_id.displayName;
    
    if ([[[SCTransfer sharedInstance] sentInvites] containsObject:peer_id]) {
        [cell.activityIndicator startAnimating];
    }
    
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    MCPeerID *peer_id = [peers objectAtIndex:indexPath.row];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [[SCTransfer sharedInstance] invitePeer:peer_id];
    
    [self.tableView reloadData];
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
        //[connectedPeers addObject:peerID];
        [self.tableView reloadData];
    }
    
}

@end
