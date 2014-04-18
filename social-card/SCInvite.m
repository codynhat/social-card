//
//  SCInvite.m
//  social-card
//
//  Created by Cody Hatfield on 4/15/14.
//  Copyright (c) 2014 Cody Hatfield. All rights reserved.
//

#import "SCInvite.h"

@implementation SCInvite

-(id)initWithPeerID:(MCPeerID*)peer_id UUID:(NSString*)uuid block:(void (^)(BOOL, MCSession *))invitationHandler{
    self = [super init];
    if (self) {
        _invitationHandler = invitationHandler;
        _uuid = uuid;
        _peer_id = peer_id;
    }
    return self;
    
}

@end
