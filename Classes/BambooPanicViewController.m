//
//  BambooPanicViewController.m
//  BambooPanic
//
//  Created by Guido Schade on 6/08/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

// Todo
// 1. fix sleep continuity issue
// 2. fix all warnings
// 3. memory leak testing
// 4. demo mode
// 5. 

#import "BambooPanicViewController.h"
#import "SoundEffect.h"

// game states
#define gameStateInMenu						1
#define gameStateRunning					2
#define gameStateFalling					3
#define gameStateWaitingContinue	4
#define gameStateWaitingOver			5
#define gameStateInInfo						6
#define gameStateInHelp						7

#define myConfigFile "Documents/savegame.dat"

@implementation BambooPanicViewController

@synthesize gameState, gameBGView, menuBGView;


// initialising view
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
  NSLog(@"INFO: viewWillAppear: initialising....");
	
	// initialize men array
	littleMen = [[NSMutableArray alloc] init];

	// init quotes
	quotes = [NSArray arrayWithObjects:
						@"Study the past if you would define the future.",
						@"When anger rises, think of the consequences.",
						@"To go beyond is as wrong as to fall short.",
						@"Life is really simple, but we insist on making it complicated.",
						@"It does not matter how slowly you go as long as you do not stop.",
						@"Wheresoever you go, go with all your heart.",
						@"It is better to play than do nothing.",
						@"Success depends upon previous preparation, and without such preparation there is sure to be failure.",
						@"Our greatest glory is not in never falling but in rising every time we fall.",
						@"No matter where you go - there you are.",
						@"Gravity is only the bark of wisdom; but it preserves it.",
						@"Do not worry about holding high position; worry rather about playing your proper role.",
						@"To go too far is as bad as to fall short.",
						@"Forget injuries, never forget kindnesses.",
						@"To love a thing means wanting it to live.",
						@"The cautious seldom err.",
						@"To know what is right and not to do it is the worst cowardice.",
						nil];
	
	// make sure to keep the array
	[quotes retain];
	
	// init timer
	myTimer = [[NSTimer alloc] init];
	clearTimer = [[NSTimer alloc] init];
	
	// some global inits - surviving game restarts - will be overridden by saved data - if any
	myHighscore = 0;
	soundEnabled = YES;
	
	// init other variables
	[self reset];
	
	// loading saved game and high scores at some stage
	[self loadgame];
	
	// fix up saved game info, score and speed
	if (gameInProgress == YES)
	{
		myScore = myScoreLastStage;
		myInterval = 1.025 - (myStage * 0.025);
		myRandomizer = 6.5 - (myStage * 0.25);
	}
	
	// view loaded
	viewLoaded = NO;
}

// set back to defaults
-(void)reset {
	NSLog(@"INFO: reset");
	
	gameState = gameStateInMenu;
	gameInProgress = NO;
	
	// clear all counters
	myMoves = 0;
	myScore = 0;
	myScoreLastStage = 0;
	myLives = 3;
	myStage = 0;
	myRandomizer = 10;
	lidLocation = 1;
	fastForward = NO;
	prevFastForward = NO;
	
	lid01.center = CGPointMake(160,130);
	lastLidLocation = lidLocation;
	lastUp = lastDown = 0; // make sure the first man shows up
	myInterval = 1.0;
	fallenMan = nil;
	
	[self updateLabels];
}

// falling sequence
-(void)animateFall {
  BOOL x;
	x = [fallenMan fall];
	
	// are we finished?
	if (x == TRUE)
	{		
		// invalidate timer
		[myTimer invalidate];
	
		// vibrate and play hit sound
		AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
		[stepSound play];
		
		// make text label visible
		textLabel.hidden = NO;
					
		// clear fallen man
		[fallenMan release];
		fallenMan = nil;
		
		// remove all subviews
		for (LittleMan * man in littleMen) { [man.view removeFromSuperview]; }
		
		// remove all men from array
		[littleMen removeAllObjects];
	
		// TODO: fix the timer like the clear one ...
		// set new timer
		myTimer = [NSTimer scheduledTimerWithTimeInterval:myInterval target:self selector:@selector(gameLoop) userInfo:nil repeats:YES];		
	}
}

// Implement viewDidLoad to do additional setup after loading the view
- (void)viewDidLoad {
	NSLog(@"INFO: viewDidLoad");
	[super viewDidLoad];
	
	if (viewLoaded == NO)
	{
	  viewLoaded = YES;
		
		// set timer for splash screen
	  [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(buildAndFadeScreen) userInfo:nil repeats:NO];
	}
}

// touch to start - and move if not start screen
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	
	NSLog(@"INFO: touchesBegan");
	
	// fell - and waiting for screen touch to continue game
	if (gameState == gameStateWaitingContinue)
	{
		textLabel.hidden = YES;
		lid01.hidden = NO;
		gameState = gameStateRunning;
		lastUp = lastDown = myMoves - 4;
		[swishSound play];
	}
	
	// died - touch to go back to main menu
	if (gameState == gameStateWaitingOver)
	{
		[swishSound play];
		[self reset];
		[self menuButtonPushed:self];
	}
		
	// running - normal state, check touches on screen
	if (gameState == gameStateRunning)
	{
		[self checkTouch:touches withEvent:event];
	}
	
	// help
	if (gameState == gameStateInInfo)
	{
		helpView.hidden = YES;
		[self.view bringSubviewToFront:menuView];
		gameState = gameStateInMenu;
		[swishSound play];
	}
	
	// info
	if (gameState == gameStateInHelp)
	{
		infoView.hidden = YES;
		[self.view bringSubviewToFront:menuView];
		gameState = gameStateInMenu;
		[swishSound play];
	}
}

// inherited touch moved function - don't need at the moment
//- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event { }

// move lid with finger
- (void)checkTouch:(NSSet *)touches withEvent:(UIEvent *)event {
	
	UITouch *touch = [[event allTouches] anyObject];
	CGPoint location = [touch locationInView:touch .view];
	CGPoint xLocation;
	
	NSLog(@"INFO: checktouch x = %f, y = %f",location.x,location.y);
	
	// calculate new position depending on area touched x=320 * y=480
	if ((location.x  > 100) && (location.y <= 240)) { xLocation = CGPointMake(160,130); lidLocation = 1; }
	if ((location.x  > 100) && (location.y  > 240)) { xLocation = CGPointMake(160,340); lidLocation = 2; }
	if ((location.x <= 100) && (location.y <= 240)) { xLocation = CGPointMake(35,130); lidLocation = 3; }
	if ((location.x <= 100) && (location.y  > 240)) { xLocation = CGPointMake(35,340); lidLocation = 4; }
	
	// if lid location moved, play swoosh sound
	if (lidLocation != lastLidLocation)
	{
		lastLidLocation = lidLocation;
		[swishSound play];
	}
	
	// set new position - automatically updates it on screen
	lid01.center = xLocation;
}

// help button pushed - start game
-(void) helpButtonPushed:(id) sender {
	NSLog(@"INFO: helpButtonPushed:");
	[swishSound play];
	helpView.hidden = NO;
	[self.view bringSubviewToFront:helpView];
	gameState = gameStateInHelp;
}
	
// info button pushed - start game
-(void) infoButtonPushed:(id) sender {
	NSLog(@"INFO: infoButtonPushed:");
	[swishSound play];
	infoView.hidden = NO;
	[self.view bringSubviewToFront:infoView];
	gameState = gameStateInInfo;
}

// fast button pushed - toggle speed
-(void) fastButtonPushed:(id) sender {
	NSLog(@"INFO: fastButtonPushed:");
	if (fastForward == NO)
	{
	  fastForward = YES;
	}
	else
	{
	  fastForward = NO; 
	}
	[swishSound play];
}

// start button pushed - start game
-(void) startButtonPushed:(id) sender {
	NSLog(@"INFO: startButtonPushed:");
	
	// fix views
	gameView.hidden = NO;
	menuView.hidden = YES;
	helpView.hidden = YES;
	infoView.hidden = YES;
	[self.view bringSubviewToFront:gameView];
	
	gameState = gameStateRunning;
	gameInProgress = YES;
	textLabel.hidden = YES;
	lid01.hidden = NO;
	if (myMoves) { lastUp = lastDown = myMoves - 3; }
	
	[swishSound play];
	
	// update message
	if (myScore)
	{
		[textLabel setText:@"Resuming game at last stage"];
	}
	else
	{
		// randomise quote
		NSUInteger acount = [quotes count];
		NSInteger num = (int) (((float)rand() / RAND_MAX) * acount);
		// NSLog(@"Count: %d, Rand = %d", acount, num);
		[textLabel setText:[NSString stringWithFormat: @"Confucius says: %@",[quotes objectAtIndex:num]]];
	}
	
	textLabel.hidden = NO;
	
	// set text label timer to 5 seconds
	if (clearTimer) { [clearTimer invalidate]; [clearTimer release]; }
	clearTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(clearLabel) userInfo:nil repeats:NO];
	[clearTimer retain];
	
	// set timer interval
	myTimer = [NSTimer scheduledTimerWithTimeInterval:myInterval target:self selector:@selector(gameLoop) userInfo:nil repeats:YES];	
}
	 
// menu button pushed - pause / end game
-(void) menuButtonPushed:(id) sender {
	NSLog(@"INFO: menuButtonPushed");

	// stop timer
	[myTimer invalidate];
	
	// reset scores if game is over and menu button is pushed
	if (gameState == gameStateWaitingOver) { [self reset]; }
	
	// TODO: did not work
	// [[UIAlertView alloc] initWithTitle:@"Game Paused" message:@"Game Paused." delegate:nil cancelButtonTitle:@"Resume" otherButtonTitles:nil];
	// sleep(2);
	
	[swishSound play];
	
	// change state
  gameState = gameStateInMenu;
	textLabel.hidden = YES;
	lid01.hidden = YES;
	
	// stop all animations
	for (LittleMan * man in littleMen) { [man pause]; }
	
	// remove all subviews
	for (LittleMan * man in littleMen) { [man.view removeFromSuperview]; }
	
	// remove all men from array
	[littleMen removeAllObjects];
	
	// update start button
	if (gameInProgress == YES)
	{
	  [startButton setTitle:@"Resume Game" forState:UIControlStateNormal];
	} else {
	  [startButton setTitle:@"New Game" forState:UIControlStateNormal];
	}

	// swap screens
	gameView.hidden = YES;
	menuView.hidden = NO;
}

// sound switch pushed
-(void) soundSwitchPushed:(id) sender {
	NSLog(@"INFO: soundSwitchPushed");

	// TODO: sometimes out of sync ...
	
	// toggle switch and play sound when switched on
	if (soundSwitch.on == YES)
	{
		soundEnabled = YES;
		[stepSound unmute]; [tickSound unmute]; [tockSound unmute]; [swishSound unmute]; [fallSound unmute];
		[swishSound play];
	}
	else
	{
		soundEnabled = NO;
		[stepSound mute]; [tickSound mute]; [tockSound mute]; [swishSound mute]; [fallSound mute];
	}
}

// clear label
-(void) clearLabel
{
	textLabel.hidden = YES;
	[clearTimer release];
	clearTimer = nil;
}

/////////////
/// MAIN GAME LOOP
////////////

// game logic
-(void) gameLoop 
{
	if(gameState == gameStateRunning)
	{
		NSInteger dir,dirx;
		BOOL scored;
		scored=NO;
		
		// count total moves so far
		myMoves++;
		
		// if fastButton pressed
		if (fastForward != prevFastForward)
		{
			float new_interval;
			
		  prevFastForward = fastForward;
			if (fastForward == YES) { new_interval = myInterval / 2; } else { new_interval = myInterval; }
			
			// updated timer
			[myTimer invalidate];
			myTimer = [NSTimer scheduledTimerWithTimeInterval:new_interval target:self selector:@selector(gameLoop) userInfo:nil repeats:YES];
		}
		
		// increase speed / number of men
		if (!(myMoves % 40) || (!myStage))
		{
			float new_interval;
			// increase stage and update display
			myStage++;
			myScoreLastStage = myScore;
			[self updateLabels];
			
			// set speed / difficulty values depending on stage
			myInterval = 1.025 - (myStage * 0.025);
			myRandomizer = 6.5 - (myStage * 0.25);
			if (myInterval < 0.1) { myInterval = 0.1; }
		  if (myRandomizer < 1.5) { myRandomizer = 1.5; }
			if (fastForward == YES) { new_interval = myInterval / 2; } else { new_interval = myInterval; }
			
			// change timer to new value
			[myTimer invalidate];
			myTimer = [NSTimer scheduledTimerWithTimeInterval:new_interval target:self selector:@selector(gameLoop) userInfo:nil repeats:YES];
		}
		
		// NSLog(@"res = %d", 0 % 2); // 1 % 2 = 1, 2 % 2 = 0 , 0 % 2 = 0
		
		// get random number and start new man - also if there is none on the screen
		if (!littleMen.count || (rand() < (RAND_MAX / myRandomizer)))
		{
			if (rand() < (RAND_MAX / 2)) { dir = 1; } else { dir = 2; }
			/*
		  // set direction
		  if (myMoves % 2) { dir = 1; } else { dir = 2; }
		
			// first stage - only dir = 1
			if (myStage < 2) { dir = 1; }
			
			// first man comes always from left
			if (myMoves == 1) { dir = 1; lastUp = myMoves - 4; }
			
			 */
			
		  // and make sure there are spaces of a multiple of 4 between men on each level
			if (((dir == 1) && ((myMoves - lastUp) % 4)) || ((dir == 2) && ((myMoves - lastDown) % 4)))
		  {
				NSLog(@"INFO: preventing doubles ...");
		  }
		  else
		  {
				if (dir == 1) { lastUp = myMoves; }
		    if (dir == 2) { lastDown = myMoves; }
						
		    // create new man - use direction as parameter
		    LittleMan * man = [[LittleMan alloc] initWithDir:dir ];
						
		    // set man ID
		    man.mid = myMoves;
			
		    // add litte man to array	
		    [littleMen addObject: man];
						
		    // add subview to current view controller
		    [gameView addSubview: man.view];
		  }
		}
		
		// move all men - remove if they have left the screen
		if (myMoves % 2) { dirx = 1; } else { dirx = 2; }
		
		// go through all men and walk
		for (LittleMan * man in littleMen) { [man walk:dirx :lidLocation]; }
		
    // go through all men and remove them if they need to
		for (LittleMan * man in littleMen)
		{
			if (man.expired)
		  {
				// remove view from superview
				[man.view removeFromSuperview];
				
				// remove man from list
				[littleMen removeObject: man];
				
				// remove the man
				[man dealloc];
				
				// get out of the loop, don't want to mess up the array - remove one at a time
				break;
			}	
		}
				
		// need to update scores and check for collision
		for (LittleMan * man in littleMen)
		{ 
		  if (man.scored)
			{
			  myScore ++;
				scored = YES;
				[self updateLabels];
			} 

		  if (man.fell)
			{
				
			  myLives --; 
				[fallSound play];
				[self updateLabels];
				
				// remember man for animation
				fallenMan = man;
				
				// halt game and re-display label
				gameState = gameStateFalling;
		  }
		
  		// update high score
	  	if (myScore > myHighscore)
			{
			  myHighscore = myScore;
				[self updateLabels];
			}
		}		

		// play sound when moving - always
		if (scored) { [stepSound play]; }
		else { if (myMoves % 2) { [tockSound play]; } else { [tickSound play]; } }

		// we fell - display on screen, stop game
		if (gameState == gameStateFalling)
		{
			// stop timer
			[myTimer invalidate];

			// stop all animations
			for (LittleMan * man in littleMen) { [man pause]; }
			
			// animate falllen man
			lid01.hidden = YES;
							
			// set new status and prepare the text label
			if (myLives > 0)
			{
				[textLabel setText:[NSString stringWithFormat: @"Ouch. Tap to continue"]];
				gameState = gameStateWaitingContinue;
			}
			else
			{
				[textLabel setText:[NSString stringWithFormat: @"... GAME OVER ..."]];
				gameInProgress = NO;
				gameState = gameStateWaitingOver;
			}
			
			// set new timer with animation callback
			myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(animateFall) userInfo:nil repeats:YES];			
		}
	}
}

// ***********************************************
// BUILD / FADE SCREEN
// ***********************************************

// build views and subviews for game and menu
- (void) buildAndFadeScreen {
	NSLog(@"INFO: buildAndFadeScreen");

	// setup sounds handles
	NSBundle * mainBundle = [NSBundle mainBundle];
	tickSound  = [[SoundEffect alloc] initWithContentsOfFile:[mainBundle pathForResource:@"tick"  ofType:@"wav"]];
	tockSound  = [[SoundEffect alloc] initWithContentsOfFile:[mainBundle pathForResource:@"tock"  ofType:@"wav"]];
	fallSound  = [[SoundEffect alloc] initWithContentsOfFile:[mainBundle pathForResource:@"fall"  ofType:@"wav"]];
	swishSound = [[SoundEffect alloc] initWithContentsOfFile:[mainBundle pathForResource:@"swish" ofType:@"wav"]];
	stepSound  = [[SoundEffect alloc] initWithContentsOfFile:[mainBundle pathForResource:@"step"  ofType:@"wav"]];

	// make sure to mute all samples if saved
	if (soundEnabled == NO) { [stepSound mute]; [tickSound mute]; [tockSound mute]; [swishSound mute]; [fallSound mute]; };
	
// GAME VIEWS AND BUTTONS

	/*
	- (void)createGrayButton
	{	
		// create the UIButtons with various background images
		// white button:
		UIImage *buttonBackground = [UIImage imageNamed:@"whiteButton.png"];
		UIImage *buttonBackgroundPressed = [UIImage imageNamed:@"blueButton.png"];
		
		CGRect frame = CGRectMake(0.0, 0.0, kStdButtonWidth, kStdButtonHeight);
		
		grayButton = [ButtonsViewController buttonWithTitle:@"Gray"
																								 target:self
																							 selector:@selector(action:)
																									frame:frame
																									image:buttonBackground
																					 imagePressed:buttonBackgroundPressed
																					darkTextColor:YES];
	}
	*/
	
	
	// create subview for game background
	gameView = [[UIView alloc] initWithFrame: [[UIScreen mainScreen] applicationFrame]];
	gameBGView = [[[UIImageView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]] autorelease];
	[gameBGView setImage:[[UIImage imageAtPath:[[NSBundle mainBundle] pathForResource:@"background" ofType:@"png"]] retain]];
	gameView.hidden = YES;
	[gameView addSubview:gameBGView];
	[self.view addSubview:gameView];
	
	UIImage * buttonbg = [UIImage imageNamed:@"button1.png"];
	UIImage * buttonbgpressed = [UIImage imageNamed:@"button2.png"];
	
	// add menu button to game view	
	menuButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[menuButton setTitle:@"Menu" forState:UIControlStateNormal];
	menuButton.frame = CGRectMake(-20, 240, 60, 20);
	menuButton.transform = CGAffineTransformMakeRotation (M_PI/2);
	[menuButton addTarget:self action:@selector(menuButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
  //menuButton.backgroundColor = [UIColor clearColor];
	[gameView addSubview:menuButton];
	
	// add fast button to game view
	fastButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[fastButton setTitle:@">>" forState:UIControlStateNormal];
	fastButton.frame = CGRectMake(150, 230, 30, 30);
	fastButton.transform = CGAffineTransformMakeRotation (M_PI/2);
	[fastButton addTarget:self action:@selector(fastButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
	[gameView addSubview:fastButton];
	
// HELP VIEW

	helpView = [[UIView alloc] initWithFrame: [[UIScreen mainScreen] applicationFrame]];
	helpBGView = [[[UIImageView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]] autorelease];
	[helpBGView setImage:[[UIImage imageAtPath:[[NSBundle mainBundle] pathForResource:@"help" ofType:@"png"]] retain]];
	helpView.hidden = YES;
	[helpView addSubview:helpBGView];
	[self.view addSubview:helpView];
	
// INFO VIEW

	infoView = [[UIView alloc] initWithFrame: [[UIScreen mainScreen] applicationFrame]];
	infoBGView = [[[UIImageView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]] autorelease];
	[infoBGView setImage:[[UIImage imageAtPath:[[NSBundle mainBundle] pathForResource:@"info" ofType:@"png"]] retain]];
	infoView.hidden = YES;
	[infoView addSubview:infoBGView];
	[self.view addSubview:infoView];
		
// MENU VIEWS AND BUTTONS
	
	// create subview for menu
	menuView = [[UIView alloc] initWithFrame: [[UIScreen mainScreen] applicationFrame]];
	menuBGView = [[[UIImageView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]] autorelease];
	[menuBGView setImage:[[UIImage imageAtPath:[[NSBundle mainBundle] pathForResource:@"menu" ofType:@"png"]] retain]];
	menuView.hidden = NO;
	[menuView addSubview:menuBGView];
	[self.view addSubview:menuView];
	
	// add start button to menu view
	startButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	if (gameInProgress == YES)	{ [startButton setTitle:@"Resume Game" forState:UIControlStateNormal]; }
	else { [startButton setTitle:@"New Game" forState:UIControlStateNormal]; }
	startButton.frame = CGRectMake(-10,50, 130, 50);
	startButton.transform = CGAffineTransformMakeRotation (M_PI/2);
	[startButton addTarget:self action:@selector(startButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
	[startButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	[startButton setBackgroundImage:[buttonbg stretchableImageWithLeftCapWidth:12.0 topCapHeight:0.0] forState:UIControlStateNormal];
	[startButton setBackgroundImage:[buttonbgpressed stretchableImageWithLeftCapWidth:12.0 topCapHeight:0.0] forState:UIControlStateHighlighted];
	[menuView addSubview:startButton];
	
	// add help button to menu view
	helpButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[helpButton setTitle:@"Help" forState:UIControlStateNormal];
	helpButton.frame = CGRectMake(15, 180, 80, 50);
	helpButton.transform = CGAffineTransformMakeRotation (M_PI/2);
	[helpButton addTarget:self action:@selector(helpButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
	[menuView addSubview:helpButton];

	// add info button to menu view
	infoButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[infoButton setTitle:@"Info" forState:UIControlStateNormal];
	infoButton.frame = CGRectMake(15, 280, 80, 50);
	infoButton.transform = CGAffineTransformMakeRotation (M_PI/2);
	[infoButton addTarget:self action:@selector(infoButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
	[menuView addSubview:infoButton];
	
	// add sounds switch to menu view
	soundSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(10, 395, 0, 0)];
	soundSwitch.transform = CGAffineTransformMakeRotation (M_PI/2);
	[soundSwitch setOn:soundEnabled animated:NO];
	[soundSwitch addTarget:self action:@selector(soundSwitchPushed:) forControlEvents:UIControlEventValueChanged];
	[menuView addSubview:soundSwitch];
	
// GAME VIEW SPRITES AND LABELS
	
	// add subview for lid / cover
	lid01 = [[[UIImageView alloc] initWithFrame:CGRectMake(155,115,10,30)] autorelease];
	[lid01 setImage:[[UIImage imageAtPath:[[NSBundle mainBundle] pathForResource:@"hole_cover" ofType:@"png"]] retain]]; 
  lid01.hidden = YES;
	[gameView addSubview:lid01];
	
	// initialise text label
	textLabel = [[[UILabel alloc] initWithFrame:CGRectMake(50,200,400,90)] autorelease];
	[textLabel setText:@"Please TAP to start ..."];
	textLabel.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0]; 
	[textLabel setTextAlignment:UITextAlignmentCenter];
	textLabel.font = [UIFont fontWithName:@"AmericanTypewriter-Bold" size:16.0];
	textLabel.lineBreakMode = UILineBreakModeWordWrap;
	textLabel.numberOfLines = 3;
	textLabel.transform = CGAffineTransformMakeRotation (M_PI/2);
	[gameView addSubview:textLabel];
	
	// initialise lives frame and label
	livesLabel = [[[UILabel alloc] initWithFrame:CGRectMake(220,30,150,30)] autorelease];
	livesLabel.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0]; 
	[livesLabel setTextAlignment:UITextAlignmentCenter];
	livesLabel.transform = CGAffineTransformMakeRotation (M_PI/2);
	[gameView addSubview:livesLabel];

	// initialise stage frame and label
	stageLabel = [[[UILabel alloc] initWithFrame:CGRectMake(220,120,150,30)] autorelease];
	stageLabel.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0]; 
	[stageLabel setTextAlignment:UITextAlignmentCenter];
	stageLabel.transform = CGAffineTransformMakeRotation (M_PI/2);
	[gameView addSubview:stageLabel];
		
	// initialise score frame and label
	scoreLabel = [[[UILabel alloc] initWithFrame:CGRectMake(220,230,150,30)] autorelease];
	scoreLabel.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0]; 
	[scoreLabel setTextAlignment:UITextAlignmentCenter];
	scoreLabel.transform = CGAffineTransformMakeRotation (M_PI/2);
	[gameView addSubview:scoreLabel];
	
	// initialise high score frame and label
	highScoreLabel = [[[UILabel alloc] initWithFrame:CGRectMake(220,370,150,30)] autorelease];
	highScoreLabel.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0]; 
	[highScoreLabel setTextAlignment:UITextAlignmentCenter];
	highScoreLabel.transform = CGAffineTransformMakeRotation (M_PI/2);
	[gameView addSubview:highScoreLabel];

	// update Labels
	[self updateLabels];
		
	// bring menu to front - waiting for game button to be pushed
	[self.view bringSubviewToFront:menuView];
	
	//NSLog(@"INFO: finished button creation");
}

// Update labels
- (void)updateLabels {
  NSLog(@"INFO: updateLabels");
	[livesLabel setText:[NSString stringWithFormat: @"Lives: %d", myLives]];
	[stageLabel setText:[NSString stringWithFormat: @"Stage: %d", myStage]];
	[scoreLabel setText:[NSString stringWithFormat: @"Score: %04d", myScore]];
	[highScoreLabel setText:[NSString stringWithFormat: @"High Score: %04d", myHighscore]];
}

// loading saved game
-(void)loadgame {
  NSLog(@"INFO: loading game ...");	
	
	CFStringRef homeDir = (CFStringRef)NSHomeDirectory();
	
	NSError *err = nil;
  NSString *strPath = [[NSString alloc] initWithFormat:@"%@/%s", homeDir, myConfigFile];
	NSMutableData *data = [[NSMutableData alloc] initWithContentsOfFile:strPath error:&err];
	// check if file exists, if not, keep defaults
	if (err) { NSLog(@"Error loading config file: %@/%s", homeDir, myConfigFile); }
	else
	{
		NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
		
		myHighscore = [unarchiver decodeIntegerForKey:@"HighScore"];
		myStage = [unarchiver decodeIntegerForKey:@"Stage"];
		myLives = [unarchiver decodeIntegerForKey:@"Lives"];
		myScoreLastStage = [unarchiver decodeIntegerForKey:@"ScoreLastStage"];
		soundEnabled = [unarchiver decodeBoolForKey:@"SoundEnabled"];
		gameInProgress = [unarchiver decodeBoolForKey:@"GameInProgress"];
		
		[unarchiver finishDecoding];
		[unarchiver release];
		NSLog(@"INFO: read config file: %@/%s", homeDir, myConfigFile);
	}
	[data release];
	[strPath release];
}

// saving current game and high scores
-(void)savegame {
	NSLog(@"INFO: saving game ...");
	
	CFStringRef homeDir = (CFStringRef)NSHomeDirectory();
	
	NSError *err = nil;
	NSString *strPath = [[NSString alloc] initWithFormat:@"%@/%s", homeDir, myConfigFile];
	NSMutableData *data = [NSMutableData alloc];
	NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
	
	[archiver encodeInteger:myHighscore forKey:@"HighScore"];
	[archiver encodeInteger:myStage forKey:@"Stage"];
	[archiver encodeInteger:myLives forKey:@"Lives"];
	[archiver encodeInteger:myScoreLastStage forKey:@"ScoreLastStage"];
	[archiver encodeBool:soundEnabled forKey:@"SoundEnabled"];
	[archiver encodeBool:gameInProgress forKey:@"GameInProgress"];
	
	[archiver finishEncoding];
	[data writeToFile:strPath atomically:YES error:&err];
	
	if (err) { NSLog(@"Error writing config file: %@/%s", homeDir, myConfigFile); }
	else { NSLog(@"INFO: wrote config file: %@/%s", homeDir, myConfigFile); }
	
	[archiver release];
	[data release];
	[strPath release];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
  NSLog(@"INFO: .. unloading view...");
}

- (void)dealloc {
	NSLog(@"INFO:.. dealloc ..");
	[super dealloc];
	[littleMen release];
	[myTimer release];
	NSLog(@"INFO:.. dealloc finished ..");
}

@end
