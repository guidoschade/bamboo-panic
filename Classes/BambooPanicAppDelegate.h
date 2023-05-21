//
//  BambooPanicAppDelegate.h
//  BambooPanic
//
//  Created by Guido Schade on 6/08/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BambooPanicViewController;

@interface BambooPanicAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    BambooPanicViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet BambooPanicViewController *viewController;

@end

