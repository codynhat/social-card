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
        
        // Create an initial session
        sessions = [NSMutableArray new];
        

        
        // Initialize
        invites = [NSMutableArray new];
        inviteBlocks = [NSMutableArray new];
        sentInvites = [NSMutableArray new];
        
        
        
        _contactInfo = [[NSUserDefaults standardUserDefaults] objectForKey:@"contactInfo"];

   
    }
    return self;
}

-(void)start{
        MCPeerID *peer_id;
    
    // Create Peer ID
    if (_contactInfo) {
        NSDictionary *c = [NSKeyedUnarchiver unarchiveObjectWithData:_contactInfo];
        NSString *name = [NSString stringWithFormat:@"%@ %@", [c objectForKey:@"first_name"], [c objectForKey:@"last_name"] ];
        peer_id = [[MCPeerID alloc] initWithDisplayName:name];
        
    }
    else{
        peer_id = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
    }
    
    MCSession *session = [[MCSession alloc] initWithPeer:peer_id];
    session.delegate = self;
    [sessions addObject:session];
    
    
    
    // Setup browser and advertiser
    _advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:peer_id discoveryInfo:nil serviceType:@"hfw-socialcard"];
    _browser = [[MCNearbyServiceBrowser alloc] initWithPeer:peer_id serviceType:@"hfw-socialcard"];
    
    _advertiser.delegate = self;
    _browser.delegate = self;
    
    
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
        MCSession *s = [[MCSession alloc] initWithPeer:peer_id securityIdentity:nil encryptionPreference:MCEncryptionRequired];
        s.delegate = self;
        [sessions addObject:s];
        session = s;
    }
    
    if ([invites containsObject:peer]) {
        NSLog(@"Accepting Invite...");

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
        NSLog(@"Sending Invite...");
        [_browser invitePeer:peer toSession:session withContext:nil timeout:30];
        [sentInvites addObject:peer];
        
        
    }
    
}

-(NSArray*)allConnectedDevices{
    NSMutableArray *array = [NSMutableArray new];
    
    for (MCSession *s in sessions){
        [array addObjectsFromArray:s.connectedPeers];
    }
    
    //NSLog(@"Connected Peers: %@", array);
    
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
    
    NSError *error;
    [session sendData:contact toPeers:[NSArray arrayWithObject:peer] withMode:MCSessionSendDataReliable error:&error];
    if (error) {
        NSLog(@"ERROR sending data: %@", error);
    }
    
}

-(void)addContact:(NSData*)contact{
    NSDictionary *c = [NSKeyedUnarchiver unarchiveObjectWithData:contact];
    
    
    ABAddressBookRef addressBook;
    bool wantToSaveChanges = YES;
    bool didSave;
    CFErrorRef error = NULL;
    
    addressBook = ABAddressBookCreateWithOptions(nil, nil);
    
    
    
    ABRecordRef record;
    record = ABPersonCreate();
    ABRecordSetValue(record, kABPersonFirstNameProperty, (__bridge CFTypeRef)([c objectForKey:@"first_name"]), nil);
    ABRecordSetValue(record, kABPersonLastNameProperty, (__bridge CFTypeRef)([c objectForKey:@"last_name"]), nil);
    
    ABMutableMultiValueRef phoneNumberMultiValue =
    ABMultiValueCreateMutable(kABPersonPhoneProperty);
    ABMultiValueAddValueAndLabel(phoneNumberMultiValue ,(__bridge CFTypeRef)([c objectForKey:@"phone_number"]) ,kABPersonPhoneMobileLabel, NULL);
    
    ABRecordSetValue(record, kABPersonPhoneProperty, phoneNumberMultiValue, nil);

    
    ABAddressBookAddRecord(addressBook, record, nil);
    
    
    
    
    if (ABAddressBookHasUnsavedChanges(addressBook)) {
        if (wantToSaveChanges) {
            didSave = ABAddressBookSave(addressBook, &error);
            if (!didSave) {
                
            }
        } else {
            ABAddressBookRevert(addressBook);
        }
    }
    
    CFRelease(addressBook);
    
    [_delegate didFinishAddingContact:contact];
}


-(void)setContactInfo:(NSData *)contactInfo{
    [[NSUserDefaults standardUserDefaults] setObject:contactInfo forKey:@"contactInfo"];
    _contactInfo = contactInfo;
}

- (NSString *)vCardRepresentation
{
    NSDictionary *c = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"contactInfo"]];
    
    NSMutableArray *mutableArray = [[NSMutableArray alloc] init];
    
    [mutableArray addObject:@"BEGIN:VCARD"];
    [mutableArray addObject:@"VERSION:3.0"];
    
    [mutableArray addObject:[NSString stringWithFormat:@"N:%@;%@;;;",[c objectForKey:@"last_name"], [c objectForKey:@"first_name"]]];
    
    
    [mutableArray addObject:[NSString stringWithFormat:@"TEL:%@", [c objectForKey:@"phone_number"]]];
    
    
    [mutableArray addObject:@"END:VCARD"];
    
    NSString *string = [mutableArray componentsJoinedByString:@"\n"];
    
    return string;
}

#pragma mark MCSessionDelete methods

-(void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
    NSLog(@"Session peer: %@ \n changed state:%d", peerID, state);
    [sentInvites removeObject:peerID];
    [_delegate peer:peerID didChangeState:state];
    
}

-(void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID{
    //NSLog(@"Session received data: %@", [NSKeyedUnarchiver unarchiveObjectWithData:data]);
    ABAddressBookRef addressBook;
    
    addressBook = ABAddressBookCreateWithOptions(nil, nil);
    
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            if (granted) {
                [self addContact:data];

                
            } else {
                
            }
        });
    }
    else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        [self addContact:data];

        
    }
    else {
        
    }
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
    
    if ([sentInvites containsObject:peerID]) {
        float r = ((arc4random() % 60))/10;
        [self performSelector:@selector(invitePeer:) withObject:peerID afterDelay:r];
    }

}

-(void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error{
     NSLog(@"Advertiser did not start advertising: %@", error);
}


@end
