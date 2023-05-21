//
//  SoundEffect.h

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioServices.h>

@interface SoundEffect : NSObject {
	SystemSoundID _soundID;
	BOOL isMuted;
}

- (id)initWithContentsOfFile:(NSString *)path;
- (void)play;
- (void)mute;
- (void)unmute;

@end