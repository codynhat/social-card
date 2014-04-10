//
//  SCAppDelegate.m
//  social-card
//
//  Created by Cody Hatfield on 2/11/14.
//  Copyright (c) 2014 Cody Hatfield. All rights reserved.
//

#import "SCAppDelegate.h"
#import "SCTransfer.h"
#import <Crashlytics/Crashlytics.h>
#import "KeenClient.h"

@implementation SCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [Crashlytics startWithAPIKey:@"5fc44a7ce50e8303b0f41c2e0e28c897fb86f2a0"];
    
    [KeenClient disableGeoLocation];
    [KeenClient sharedClientWithProjectId:@"5347044373f4bb3191000002"
                              andWriteKey:@"536ae2e09ae411cc4c68290832bcc6b647ff48328c7a76010126b7365840518c0418ff88c671aca582bae786ade9f93cd1d052f02593d6ed5bc5b1647a1926d8b1a90dc4454c9806a60d3cba5872727d6754005204d1cff73d1718a83522b18d77e6d0c9b5acfce48fab32ab72931b7e"
                               andReadKey:@""];
    
    
    
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    UIBackgroundTaskIdentifier taskId = [application beginBackgroundTaskWithExpirationHandler:^(void) {
        NSLog(@"Background task is being expired.");
    }];
    
    [[KeenClient sharedClient] uploadWithFinishedBlock:^(void) {
        [application endBackgroundTask:taskId];
    }];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    //NSLog(@"FOREGROUND");
    [[[SCTransfer sharedInstance] delegate] clearPeers];

}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    //NSLog(@"ACTIVE");
    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
