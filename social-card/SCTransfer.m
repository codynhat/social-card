//
//  SCTransfer.m
//  social-card
//
//  Created by Cody Hatfield on 2/11/14.
//  Copyright (c) 2014 Cody Hatfield. All rights reserved.
//

#import "SCTransfer.h"

@implementation SCTransfer

static NSString *const SCServiceUUID = @"1C039F15-F35E-4EF4-9BEB-F6CA4FF2886C";


+(SCTransfer*)sharedInstance{
    
    static SCTransfer *_sharedInstance = nil;
    
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[SCTransfer alloc] init];
    });
    return _sharedInstance;
}

-(id)init{
    if (self = [super init]) {
        // Create Peer ID
        MCPeerID *peer_id = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
        
        // Create an initial session
        sessions = [NSMutableArray new];
        
        MCSession *session = [[MCSession alloc] initWithPeer:peer_id];
        session.delegate = self;
        [sessions addObject:session];
        
        // Setup browser and advertiser
        _advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:peer_id discoveryInfo:nil serviceType:@"hfw-socialcard"];
        _browser = [[MCNearbyServiceBrowser alloc] initWithPeer:peer_id serviceType:@"hfw-socialcard"];
        
        _advertiser.delegate = self;
        _browser.delegate = self;
        
        // Initialize
        invites = [NSMutableArray new];
        inviteBlocks = [NSMutableArray new];
        sentInvites = [NSMutableArray new];
   
    }
    return self;
}

-(void)start{
    [self startAdvertising];
    [self startBrowsing];
}

-(void)startAdvertising{
    NSLog(@"Started advertising...");
    [_advertiser startAdvertisingPeer];
}

-(void)startBrowsing{
    NSLog(@"Started browsing...");
    [_browser startBrowsingForPeers];
}

-(NSArray*)sentInvites{
    return [NSArray arrayWithArray:sentInvites];
}

-(void)invitePeer:(MCPeerID*)peer{
    // Check to see if an invite already exists, if so accept it, if not send one
    
    
    MCSession *session = nil;
    
    // Get the first session with no peer
    for (MCSession *s in sessions){
        if (s.connectedPeers.count < 2) {
            session = s;
            break;
        }
    }
    
    if (session == nil) {
        MCPeerID *peer_id = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
        MCSession *s = [[MCSession alloc] initWithPeer:peer_id];
        s.delegate = self;
        [sessions addObject:s];
        session = s;
    }
    
    if ([invites containsObject:peer]) {
        // Invite was already received, accept it
        NSUInteger index = [invites indexOfObject:peer];
        void (^invitationHandler)(BOOL, MCSession *) = [inviteBlocks objectAtIndex:index];
        invitationHandler(YES, session);
        [sentInvites addObject:peer];
        
        [inviteBlocks removeObjectAtIndex:index];
        [invites removeObjectAtIndex:index];
    }
    else{
        // No invite yet, send one
        [_browser invitePeer:peer toSession:session withContext:nil timeout:30];
        [sentInvites addObject:peer];
    }
}

-(NSArray*)allConnectedDevices{
    NSMutableArray *array = [NSMutableArray new];
    
    for (MCSession *s in sessions){
        [array addObjectsFromArray:s.connectedPeers];
    }
    
    NSLog(@"Connected Peers: %@", array);
    
    return [NSArray arrayWithArray:array];
}


-(void)sendContact:(NSData*)contact toPeer:(MCPeerID*)peer{
    MCSession *session = nil;
    
    // Get the  session with the peer
    for (MCSession *s in sessions){
        if ([s.connectedPeers containsObject:peer]){
            session = s;
            break;
        }
    }
    
    [session sendData:contact toPeers:[NSArray arrayWithObject:peer] withMode:MCSessionSendDataReliable error:nil];
    
}

#pragma mark MCSessionDelete methods

-(void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
    NSLog(@"Session peer: %@ \n changed state:%d", peerID, state);
    [sentInvites removeObject:peerID];
    [_delegate peer:peerID didChangeState:state];
    
}

-(void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID{
    NSLog(@"Session received data: %@", [NSKeyedUnarchiver unarchiveObjectWithData:data]);
}

#pragma mark MCNearbyServiceBrowser Delegate methods

-(void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info{
    NSLog(@"Found Peer:%@", peerID);
    [_delegate foundPeer:peerID];
}

-(void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID{
    NSLog(@"Lost Peer:%@", peerID);
    [_delegate lostPeer:peerID];
}

-(void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error{
    NSLog(@"Browser did not start browsing: %@", error);
}

#pragma mark MCNearbyServiceAdvertiser Delegate methods

-(void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession *))invitationHandler{
    NSLog(@"Received Invite from: %@", peerID);
    [invites addObject:peerID];
    [inviteBlocks addObject:invitationHandler];

}

-(void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error{
     NSLog(@"Advertiser did not start advertising: %@", error);
}


@end
