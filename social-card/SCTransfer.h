//
//  SCTransfer.h
//  social-card
//
//  Created by Cody Hatfield on 2/11/14.
//  Copyright (c) 2014 Cody Hatfield. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import <AddressBook/AddressBook.h>

@protocol SCTransferDelegate

- (void)foundPeer:(MCPeerID*)peer;
- (void)lostPeer:(MCPeerID*)peer;
- (void)peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state;
- (void)didFinishAddingContact:(NSData*)contact;

@end

@interface SCTransfer : NSObject <MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate, MCSessionDelegate>{
    NSMutableArray *sessions;
    NSMutableArray *invites;
    NSMutableArray *inviteBlocks;
    NSMutableArray *sentInvites;
}

@property (strong, nonatomic) id<SCTransferDelegate> delegate;

@property (strong, nonatomic) MCNearbyServiceBrowser *browser;
@property (strong, nonatomic) MCNearbyServiceAdvertiser *advertiser;
@property (strong, nonatomic) NSData *contactInfo;


+(SCTransfer*)sharedInstance;

-(void)start;
-(void)startAdvertising;
-(void)startBrowsing;

-(void)invitePeer:(MCPeerID*)peer;
-(NSArray*)sentInvites;

-(NSArray*)allConnectedDevices;

-(void)sendContact:(NSData*)contact toPeer:(MCPeerID*)peer;
-(void)addContact:(NSData*)contact;

@end
