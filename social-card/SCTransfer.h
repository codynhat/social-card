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
#import <CoreBluetooth/CoreBluetooth.h>

@protocol SCTransferDelegate

- (void)foundPeer:(MCPeerID*)peer;
- (void)lostPeer:(MCPeerID*)peer;
- (void)peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state;
- (void)didFinishAddingContact:(NSData*)contact;
- (void)clearPeers;

@end

@interface SCTransfer : NSObject <MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate, MCSessionDelegate, UIAlertViewDelegate>{
    NSMutableArray *sessions;
    NSMutableArray *invites;
    NSMutableArray *connectedPeers;
    NSMutableArray *disconnectingPeers;
    NSMutableArray *sentInvites;
    NSMutableArray *discovered_peers; // Array of SCInvites that pairs peerID with UUID
        
    ABAddressBookRef addressBook;
    BOOL contactPermissions;
    MCPeerID *peer_id;
    
}

@property (strong, nonatomic) id<SCTransferDelegate> delegate;

@property (strong, nonatomic) MCNearbyServiceBrowser *browser;
@property (strong, nonatomic) MCNearbyServiceAdvertiser *advertiser;
@property (strong, nonatomic) NSData *contactInfo;
@property (strong, nonatomic) CBCentralManager *CM;


+(SCTransfer*)sharedInstance;

-(void)start;
-(void)stop;
-(void)startAdvertising;
-(void)startBrowsing;
-(NSArray*)cacheName:(NSString*)name;

-(void)invitePeer:(MCPeerID*)peer;
-(NSArray*)sentInvites;

-(NSArray*)allConnectedDevices;

-(void)sendContact:(NSData*)contact toPeer:(MCPeerID*)peer;
-(void)addContact:(NSData*)contact;
-(void)showContactPermissions;

- (NSString *)vCardRepresentation;
@end
