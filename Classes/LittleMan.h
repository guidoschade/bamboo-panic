//
//  LittleMan.h
//  BambooPanic
//
//  Created by Guido Schade on 7/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioServices.h>

// pixels to walk with each step
#define kStepWidth 30

@interface LittleMan : NSObject {
	NSInteger direction;
	CGRect frame;
	UIImageView * view;
	NSInteger expired;
	NSInteger fell;
	NSInteger mid;
	NSInteger scored;
	float angle;
	
	UIImage * image1, * image2;
}

- (id)initWithDir:(NSInteger) dir;
- (void)walk:(NSInteger) dir :(NSInteger) location;
- (BOOL)fall;
- (void)pause;
- (void)resume;

@property (nonatomic, retain) UIImageView * view;
@property NSInteger direction;
@property NSInteger mid;
@property NSInteger expired;
@property NSInteger fell;
@property NSInteger scored;

@end
