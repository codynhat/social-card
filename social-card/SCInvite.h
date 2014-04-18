//
//  SCInvite.h
//  social-card
//
//  Created by Cody Hatfield on 4/15/14.
//  Copyright (c) 2014 Cody Hatfield. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

typedef void(^InviteBlock)(BOOL, MCSession *);

@interface SCInvite : NSObject

-(id)initWithPeerID:(MCPeerID*)peer_id UUID:(NSString*)uuid block:(void (^)(BOOL, MCSession *))invitationHandler;

@property (strong, nonatomic) MCPeerID *peer_id;
@property (strong, nonatomic) NSString *uuid;
@property (nonatomic, copy) InviteBlock invitationHandler;

@end
