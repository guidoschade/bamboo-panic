//
//  SoundEffect.m

#import "SoundEffect.h"

@implementation SoundEffect

- (id)initWithContentsOfFile:(NSString *)path {

	self = [super init];
    
	if (self != nil)
	{
		NSURL *aFileURL = [NSURL fileURLWithPath:path isDirectory:NO];
        
		if (aFileURL != nil)  
		{
      SystemSoundID aSoundID;
      OSStatus error = AudioServicesCreateSystemSoundID((CFURLRef)aFileURL, &aSoundID);
            
      if (error == kAudioServicesNoError)
			{
        _soundID = aSoundID;
			}
			else
			{
				NSLog(@"Error %d loading sound at path: %@", error, path);
        [self release], self = nil;
			}
		} 
		else
		{
			NSLog(@"NSURL is nil for path: %@", path);
			[self release], self = nil;
		}
	}
	isMuted = FALSE;
	return self;
}

-(void)dealloc {
    AudioServicesDisposeSystemSoundID(_soundID);
    [super dealloc];
}

-(void)mute {
	isMuted = TRUE;
}

-(void)unmute {
  isMuted = FALSE;	
}

-(void)play {
	if (isMuted == FALSE) { AudioServicesPlaySystemSound(_soundID); }
}

@end