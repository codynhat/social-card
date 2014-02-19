//
//  SCFindPeopleViewController.m
//  social-card
//
//  Created by Cody Hatfield on 2/18/14.
//  Copyright (c) 2014 Cody Hatfield. All rights reserved.
//

#import "SCFindPeopleViewController.h"

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

- (void)viewDidLoad
{
    [super viewDidLoad];

    peers = [NSMutableArray new];
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
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    MCPeerID *peer_id = [peers objectAtIndex:indexPath.row];
    
    cell.textLabel.text = peer_id.displayName;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    MCPeerID *peer_id = [peers objectAtIndex:indexPath.row];

    [[SCTransfer sharedInstance] invitePeer:peer_id];
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

@end
