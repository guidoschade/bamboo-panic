//
//  BambooPanicViewController.h
//  BambooPanic
//
//  Created by Guido Schade on 6/08/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioServices.h>
#import <Foundation/Foundation.h>

#import "LittleMan.h"

@class SoundEffect;

@interface BambooPanicViewController : UIViewController {

	// sounds
	SoundEffect * tickSound;
	SoundEffect * tockSound;
	SoundEffect * fallSound;
	SoundEffect * swishSound;
	SoundEffect * stepSound;

	// views / images
	UIView			* menuView;
	UIView			* gameView;
	UIView			* helpView;
	UIView			* infoView;
	UIImageView * lid01;
  UIImageView * messView;
	UIImageView * menuBGView;
	UIImageView * gameBGView;
	UIImageView * helpBGView;
	UIImageView * infoBGView;
	
	// buttons and switches
	UIButton * startButton;
	UIButton * aboutButton;
	UIButton * menuButton;
	UIButton * helpButton;
	UIButton * infoButton;
	UIButton * fastButton;
	UISwitch * soundSwitch;
	
	// text labels
	UILabel * textLabel;
	UILabel * livesLabel;
	UILabel * scoreLabel;
	UILabel * highScoreLabel;
	UILabel * stageLabel;
	
	NSInteger lidLocation;
	NSInteger lastLidLocation;
	NSInteger gameState;
	NSInteger myMoves;
	NSInteger myScore;
	NSInteger myScoreLastStage;
	NSInteger myHighscore;
	NSInteger myLives;
	NSInteger lastUp;
	NSInteger lastDown;
	NSInteger myStage;
	
	// speed and number of men
	float myInterval;
	float myRandomizer;
	
	// timer
	NSTimer * myTimer;
	NSTimer * clearTimer;
	
	// game 
	Boolean viewLoaded;
	Boolean soundEnabled;
	Boolean gameInProgress;
	Boolean fastForward;
	Boolean prevFastForward;
	
	// men
	NSMutableArray * littleMen;
	LittleMan * fallenMan;
	
	// quotes
	NSArray * quotes;
}

@property(nonatomic) NSInteger gameState;
@property(assign) UIImageView * menuBGView;
@property(assign) UIImageView * gameBGView;

-(void) reset;
-(void) savegame;
-(void) loadgame;
-(void) updateLabels;
-(void) startButtonPushed:(id) sender;
-(void) helpButtonPushed:(id) sender;
-(void) infoButtonPushed:(id) sender;
-(void) menuButtonPushed:(id) sender;
-(void) fastButtonPushed:(id) sender;

@end

