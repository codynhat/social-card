//
//  SCTransfer.m
//  social-card
//
//  Created by Cody Hatfield on 2/11/14.
//  Copyright (c) 2014 Cody Hatfield. All rights reserved.
//

#import "SCTransfer.h"
#import "KeenClient.h"
#import "SCInvite.h"

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
        sentInvites = [NSMutableArray new];
        discovered_peers = [NSMutableArray new];

        
        
        
        _contactInfo = [[NSUserDefaults standardUserDefaults] objectForKey:@"contactInfo"];

        addressBook = ABAddressBookCreateWithOptions(nil, nil);
        
        if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
            ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
                if (granted) {
                   
                    contactPermissions = YES;
                    [[KeenClient sharedClient] addEvent:@{@"granted": [NSNumber numberWithBool:YES]} toEventCollection:@"contact_authorization" error:nil];

                    
                } else {
                    contactPermissions = NO;
                    [[KeenClient sharedClient] addEvent:@{@"granted": [NSNumber numberWithBool:NO]} toEventCollection:@"contact_authorization" error:nil];

                    [self showContactPermissions];
                    
                }
            });
        }
        else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
            
            contactPermissions = YES;
            [[KeenClient sharedClient] addEvent:@{@"granted": [NSNumber numberWithBool:YES]} toEventCollection:@"contact_authorization" error:nil];

            
        }
        else {
            contactPermissions = NO;
            [self showContactPermissions];
        }
        
        


   
    }
    return self;
}

-(void)start{
    
    // Create Peer ID
    if (_contactInfo) {
        NSDictionary *c = [NSKeyedUnarchiver unarchiveObjectWithData:_contactInfo];
        NSString *name = [NSString stringWithFormat:@"%@ %@", [c objectForKey:@"first_name"], [c objectForKey:@"last_name"] ];
        peer_id = [[MCPeerID alloc] initWithDisplayName:name];
        
    }
    else{
        peer_id = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
    }
    
    
    
    
    // Setup browser and advertiser
    NSDictionary *disc = [NSDictionary dictionaryWithObject:[[[UIDevice currentDevice] identifierForVendor] UUIDString] forKey:@"UUID"];
    
    _advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:peer_id discoveryInfo:disc serviceType:@"hfw-socialcard"];
    _browser = [[MCNearbyServiceBrowser alloc] initWithPeer:peer_id serviceType:@"hfw-socialcard"];
    
    _advertiser.delegate = self;
    _browser.delegate = self;
    
    
    [self startAdvertising];
    [self startBrowsing];
}

-(void)stop{
    NSLog(@"Stop advertising...");
    NSLog(@"Stop browsing...");
    [_advertiser stopAdvertisingPeer];
    [_browser stopBrowsingForPeers];
}

-(void)startAdvertising{
    NSLog(@"Started advertising...");
    [_advertiser startAdvertisingPeer];
}

-(void)startBrowsing{
    NSLog(@"Started browsing...");
    [_browser startBrowsingForPeers];
}

-(void)showContactPermissions{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Contact Permissions" message:@"SocialCard needs to access your address book in order to add a contact!\n Go to Settings->Privacy->Contacts to enable permissions for SocialCard." delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alert show];
}

-(NSArray*)cacheName:(NSString*)name{
    
    NSArray *cachedNames = [NSArray new];
    
    if (contactPermissions) {
        cachedNames = (__bridge NSArray*)ABAddressBookCopyPeopleWithName(addressBook, (__bridge CFStringRef)name);
        
    }

    
    return cachedNames;
}

-(NSArray*)sentInvites{
    return [NSArray arrayWithArray:sentInvites];
}

-(void)invitePeer:(MCPeerID*)peer{
    // Check to see if an invite already exists, if so accept it, if not send one
    

    
    
    MCSession *session = [[MCSession alloc] initWithPeer:peer_id securityIdentity:nil encryptionPreference:MCEncryptionRequired];
    session.delegate = self;
    [sessions addObject:session];
    
    // Get UUID from peer_id, discovered_peers
    
    NSString *uuid;
    
    if ([[discovered_peers valueForKey:@"peer_id"] containsObject:peer]) {
        NSInteger index = [[discovered_peers valueForKey:@"peer_id"] indexOfObject:peer];
        uuid = [[discovered_peers valueForKey:@"uuid"] objectAtIndex:index];
    }
    else{
        NSLog(@"UUID not found in discovered_peers");
        return;
    }
    
    if ([[invites valueForKey:@"uuid"] containsObject:uuid]) {
        NSUInteger index = [[invites valueForKey:@"peer_id"] indexOfObject:peer];
        
        
        SCInvite *peerInvite = [invites objectAtIndex:index];
        
        NSLog(@"Accepting Invite From %@...", peer);
        
        
        [[KeenClient sharedClient] addEvent:@{@"type": @"accept"} toEventCollection:@"invite_peer" error:nil];


        // Invite was already received, accept it
        void (^invitationHandler)(BOOL, MCSession *) = peerInvite.invitationHandler;
        
        invitationHandler(YES, session);
        [invites removeObject:peerInvite];
        [sentInvites addObject:peer];
    }
    else if(![sentInvites containsObject:peer]){
        // No invite yet, send one
        NSLog(@"Sending Invite To %@...", peer);
        [[KeenClient sharedClient] addEvent:@{@"type": @"invite"} toEventCollection:@"invite_peer" error:nil];

        [sentInvites addObject:peer];

        
        [_browser invitePeer:peer toSession:session withContext:[[[[UIDevice currentDevice] identifierForVendor] UUIDString] dataUsingEncoding:NSUTF8StringEncoding] timeout:30];
        
        
    }
    
    /*[session nearbyConnectionDataForPeer:peer withCompletionHandler:^(NSData *connectionData, NSError *error){
        if (connectionData) {
            NSLog(@"CONNECTION: %@", connectionData);
            [session connectPeer:peer withNearbyConnectionData:connectionData];
        }
        else{
            NSLog(@"ERROR: %@", error);
        }
        
    }];*/
    
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
    
    if (!contactPermissions) {
        [self showContactPermissions];
        return;
    }
    
    NSDictionary *c = [NSKeyedUnarchiver unarchiveObjectWithData:contact];
    
    
    bool wantToSaveChanges = YES;
    bool didSave;
    CFErrorRef error = NULL;
    
    
    
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
    NSLog(@"Session %@ peer: %@ \n changed state:%d", session, peerID, state);
    //[sentInvites removeObject:peerID];
    [_delegate peer:peerID didChangeState:state];
    
    if (state == 2) {
        // Send contact data
        [self sendContact:_contactInfo toPeer:peerID];
        
        NSInteger index = [[discovered_peers valueForKey:@"peer_id"] indexOfObject:peerID];
        NSString *uuid = [(SCInvite*)[discovered_peers objectAtIndex:index] uuid];
        
        // Remove any UUIDs from invites
        for (SCInvite *i in invites){
            if ([i.uuid isEqualToString:uuid]) {
                [invites removeObject:i];
            }
        }
        
        
    }
}

-(void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID{
    NSLog(@"Session received data: %@", [[NSKeyedUnarchiver unarchiveObjectWithData:data] class]);
    
    
    // Add check for sent UUID
    
    if (contactPermissions) {
        [self addContact:data];
        [self addContact:data];
    }
    else{
        [self showContactPermissions];
    }
}

#pragma mark MCNearbyServiceBrowser Delegate methods

-(void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info{
    NSLog(@"Found Peer:%@", peerID);
    
    SCInvite *invite = [[SCInvite alloc] initWithPeerID:peerID UUID:[info objectForKey:@"UUID"] block:nil];
    [discovered_peers addObject:invite];
    
    [_delegate foundPeer:peerID];
}

-(void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID{
    NSLog(@"Lost Peer:%@", peerID);
    
    if ([[discovered_peers valueForKey:@"peer_id"] containsObject:peerID]) {
        [discovered_peers removeObjectAtIndex:[[discovered_peers valueForKey:@"peer_id"] indexOfObject:peerID]];
    }
    
    [_delegate lostPeer:peerID];
}

-(void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error{
    NSLog(@"Browser did not start browsing: %@", error);
}

#pragma mark MCNearbyServiceAdvertiser Delegate methods

-(void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession *))invitationHandler{
    NSString *uuid = [[NSString alloc] initWithData:context encoding:NSUTF8StringEncoding];

    NSLog(@"Received Invite from: %@", peerID);

    
    SCInvite *invite = [[SCInvite alloc] initWithPeerID:peerID UUID:uuid block:invitationHandler];
    [invites addObject:invite];
    
    
    
    if ([sentInvites containsObject:peerID]) {
        //NSLog(@"Delaying Accept Invite...");
        float r = ((arc4random() % 80))/10;
        [self performSelector:@selector(invitePeer:) withObject:peerID afterDelay:0];
    }

}





@end
