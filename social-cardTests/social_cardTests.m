//
//  social_cardTests.m
//  social-cardTests
//
//  Created by Cody Hatfield on 2/11/14.
//  Copyright (c) 2014 Cody Hatfield. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SCTransfer.h"

@interface social_cardTests : XCTestCase{
    SCTransfer *scTransfer;
}

@end

@implementation social_cardTests

- (void)setUp
{
    [super setUp];

    scTransfer = [SCTransfer sharedInstance];
    
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSetup
{
    XCTAssertNoThrow([scTransfer performSelector:@selector(start) withObject:nil afterDelay:3.0], @"Exception thrown while setting up");
}


@end
