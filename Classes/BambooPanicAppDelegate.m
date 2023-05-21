//
//  BambooPanicAppDelegate.m
//  BambooPanic
//
//  Created by Guido Schade on 6/08/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "BambooPanicAppDelegate.h"
#import "BambooPanicViewController.h"

@implementation BambooPanicAppDelegate

@synthesize window;
@synthesize viewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	NSLog(@"INFO: applicationDidFinishLaunching");

	// Override point for customization after app launch    
	[window addSubview:viewController.view];
	[window makeKeyAndVisible];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	NSLog(@"INFO: applicationTerminating");
	
	// call function in ViewController to save state
	[viewController savegame];
	
	NSLog(@"INFO: applicationTerminating - finished");
}

- (void)dealloc {
	NSLog(@"INFO: AppDel - dealloc");
	[viewController release];
	[window release];
	[super dealloc];
}

@end
