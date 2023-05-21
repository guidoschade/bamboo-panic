//
//  LittleMan.m
//  BambooPanic
//
//  Created by Guido Schade on 7/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "LittleMan.h"

@implementation LittleMan

@synthesize view;
@synthesize direction;
@synthesize mid;
@synthesize expired;
@synthesize fell;
@synthesize scored;

- (id)initWithDir:(NSInteger)dir {
	self = [super init];

	angle = 0.0;
	
	// set walking direction
	direction = dir;
	expired = 0;
	fell = 0;
	mid = 0;
	
	// set size of frame / box
	frame.size.width = 32; 
	frame.size.height = 32;
	
	if (direction == 1) // left to right
	{
	   frame.origin.x = 165; 
	   frame.origin.y = -35;
	}
	else // 2 = right to left
	{
	   frame.origin.x = 40; 
	   frame.origin.y = 475;
	}

	// initialise images
	image1 = [UIImage imageNamed:@"man01.png"];
	image2 = [UIImage imageNamed:@"man02.png"];
	
	// should initialise first man here - use subviews for each man
	view = [[[UIImageView alloc] initWithFrame:frame] autorelease];
	[view setImage:image1]; 
	
	return self;
}

-(void)walk: (NSInteger) dir :(NSInteger) location {

	// show current location
	// NSLog(@"man %d: dir: %d, x=%f, y=%f - move: %d location: %d",mid,direction,frame.origin.x,frame.origin.y, dir, location);

	fell = 0;
	scored = 0;
	
	// only move if we did not go last move
	if (dir == direction) 
	{
		[view setImage:image1];
		if (direction == 1) // move left to right
	  {
			frame.origin.y = frame.origin.y + kStepWidth;
			if (frame.origin.y > 475) { expired = 1; }	
		  
			//are we standing on the lid 1 (TL) position? [30*4 + 5 = 125]
			if (frame.origin.y == 115) { if (location != 1) { fell = 1; } else { scored = 1; } }	
		  
			// are we standing on the lid 2 (TR) position? [30*11 + 5 = 335]
			if (frame.origin.y == 325) { if (location != 2) { fell = 1; } else { scored = 1; } }			  
	  }
	  else // move right to left
	  {
			frame.origin.y = frame.origin.y - kStepWidth;
			if (frame.origin.y < 5) { expired = 1; }

			// are we standing on the lid 3 (BL) position? 
			if (frame.origin.y == 115) { if (location != 3) { fell = 1; } else { scored = 1; } }	
		  
			// are we standing on the lid 4 (BR) position? 
		if (frame.origin.y == 325) { if (location != 4) { fell = 1; } else { scored = 1; } }	
		}

	  // move the frame in our subview
	  [view setFrame:frame];
	}
	else { [view setImage:image2]; }
}

// stop animations
-(void)pause {
//	[view stopAnimating];
}

// start animations
-(void)resume {
//  [view startAnimating];
}

// falling animation and sounds ...
-(BOOL)fall {

	// move down
	frame.origin.x = frame.origin.x - 7;
	
	// turn sprite by a few degrees
	angle += 0.25;
  view.transform = CGAffineTransformMakeRotation (angle);
	[view setFrame:frame];

  // TODO: splash sound when hitting the water
	if (frame.origin.x < 0) { return TRUE; } else { return FALSE; }
}

-(void)dealloc {
  //[view stopAnimating]; - crashes if enabled
//  [view dealloc]; - crashes if enabled
//	[image1 release];
//	[image2 release];
  [super dealloc];
}

@end
