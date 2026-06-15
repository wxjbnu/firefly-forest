//
//  GameScene.m
//  Firefly Forest
//

#import "GameScene.h"
#import "MainMenuScene.h"

static const NSString *BackgroundTextureKey = @"background";
static const NSString *ScoreLabelName = @"scoreLabel";
static const NSString *TimerLabelName = @"timerLabel";
static const NSString *PauseButtonName = @"pauseButton";
static const NSString *PauseOverlayName = @"pauseOverlay";
static const NSString *PausePanelName = @"pausePanel";
static const NSString *OverlayRestartButtonName = @"overlayRestartButton";
static const NSString *OverlayMenuButtonName = @"overlayMenuButton";
static const NSString *OverlayResumeButtonName = @"overlayResumeButton";

@interface GameScene () <SKSceneDelegate>

@property (nonatomic, strong) SKSpriteNode *pauseButton;
@property (nonatomic, strong) SKSpriteNode *pauseOverlay;
@property (nonatomic, strong) SKSpriteNode *pausePanel;
@property (nonatomic, assign) BOOL isCountingDown;
@property (nonatomic, assign) NSTimeInterval countdownTime;
@property (nonatomic, strong) NSTimer *countdownTimer;
@property (nonatomic, assign) BOOL isPausedByUser;

@end

@implementation GameScene

#pragma mark - Scene Lifecycle

- (instancetype)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    if (self) {
        _currentLevel = 1;
        _score = 0;
        _gameTime = 0;
        _hasCountdown = NO;
        _isCountingDown = NO;
        _countdownTime = 0;
    }
    return self;
}

+ (instancetype)sceneWithSize:(CGSize)size {
    return [[self alloc] initWithSize:size];
}

- (void)didMoveToView:(SKView *)view {
    [super didMoveToView:view];
    
    // Setup background
    [self setupBackground];
    
    // Setup UI elements respecting safe area
    [self setupUIElements];
    
    // Setup game-specific elements (to be overridden by subclasses)
    [self setupGameElements];
}

- (void)update:(CFTimeInterval)currentTime {
    [super update:currentTime];
    
    if (_isCountingDown && _countdownTime > 0) {
        _countdownTime -= 1.0/60.0; // Approximate frame-based decrement
        if (_countdownTime <= 0) {
            _countdownTime = 0;
            [self updateTimerLabel];
            [self handleCountdownFinished];
        } else {
            [self updateTimerLabel];
        }
    }
}

#pragma mark - Background Setup

- (void)setupBackground {
    // Remove existing background if any
    [_backgroundSprite removeFromParent];
    
    // Create background sprite with texture replacement support
    _backgroundSprite = [SKSpriteNode spriteNodeWithColor:[UIColor clearColor] size:self.size];
    _backgroundSprite.anchorPoint = CGPointMake(0.5, 0.5);
    _backgroundSprite.position = CGPointMake(self.size.width / 2.0, self.size.height / 2.0);
    _backgroundSprite.name = BackgroundTextureKey;
    _backgroundSprite.zPosition = -1;
    
    // Try to load background image from assets
    UIImage *bgImage = [UIImage imageNamed:@"Backgrounds"];
    if (bgImage) {
        SKTexture *texture = [SKTexture textureWithCGImage:bgImage.CGImage];
        _backgroundSprite.texture = texture;
        _backgroundSprite.color = [UIColor whiteColor];
        _backgroundSprite.colorBlendFactor = 0.0;
    } else {
        // Default gradient background if no image
        _backgroundSprite.color = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1.0];
    }
    
    [self addChild:_backgroundSprite];
}

- (void)setBackgroundTexture:(SKTexture *)texture {
    _backgroundSprite.texture = texture;
    _backgroundSprite.colorBlendFactor = 0.0;
}

- (void)setBackgroundImageNamed:(NSString *)imageName {
    UIImage *image = [UIImage imageNamed:imageName];
    if (image) {
        SKTexture *texture = [SKTexture textureWithCGImage:image.CGImage];
        [self setBackgroundTexture:texture];
    }
}

#pragma mark - UI Elements Setup

- (void)setupUIElements {
    UIEdgeInsets safeInsets = self.view.safeAreaInsets;

    CGFloat topPadding = MAX(safeInsets.top, 20.0);
    CGFloat sidePadding = MAX(safeInsets.left, safeInsets.right);
    sidePadding = MAX(sidePadding, 15.0);

    // Score Label (top left)
    _scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"Helvetica-Bold"];
    _scoreLabel.text = @"Score: 0";
    _scoreLabel.fontSize = 24;
    _scoreLabel.fontColor = [UIColor whiteColor];
    _scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    _scoreLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    _scoreLabel.position = CGPointMake(sidePadding + 10, self.size.height - topPadding - 30);
    _scoreLabel.name = ScoreLabelName;
    _scoreLabel.zPosition = 100;
    [self addChild:_scoreLabel];

    // Timer Label (top center)
    _timerLabel = [SKLabelNode labelNodeWithFontNamed:@"Helvetica-Bold"];
    _timerLabel.text = @"";
    _timerLabel.fontSize = 28;
    _timerLabel.fontColor = [UIColor yellowColor];
    _timerLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
    _timerLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    _timerLabel.position = CGPointMake(self.size.width / 2.0, self.size.height - topPadding - 30);
    _timerLabel.name = TimerLabelName;
    _timerLabel.zPosition = 100;
    [self addChild:_timerLabel];

    // Pause Button (top right)
    CGSize pauseSize = CGSizeMake(44, 44);
    _pauseButton = [SKSpriteNode spriteNodeWithColor:[[UIColor blackColor] colorWithAlphaComponent:0.4] size:pauseSize];
    _pauseButton.anchorPoint = CGPointMake(0.5, 0.5);
    _pauseButton.position = CGPointMake(self.size.width - sidePadding - pauseSize.width / 2 - 10,
                                         self.size.height - topPadding - pauseSize.height / 2 - 8);
    _pauseButton.name = PauseButtonName;
    _pauseButton.zPosition = 100;

    // Draw "||" pause icon using two thin white bars
    CGFloat barWidth = 5;
    CGFloat barHeight = 20;
    CGFloat barGap = 6;
    SKSpriteNode *bar1 = [SKSpriteNode spriteNodeWithColor:[UIColor whiteColor] size:CGSizeMake(barWidth, barHeight)];
    bar1.position = CGPointMake(-barGap / 2.0 - barWidth / 2.0, 0);
    bar1.zPosition = 2;
    [_pauseButton addChild:bar1];
    SKSpriteNode *bar2 = [SKSpriteNode spriteNodeWithColor:[UIColor whiteColor] size:CGSizeMake(barWidth, barHeight)];
    bar2.position = CGPointMake(barGap / 2.0 + barWidth / 2.0, 0);
    bar2.zPosition = 2;
    [_pauseButton addChild:bar2];

    [self addChild:_pauseButton];
}

- (SKShapeNode *)createButtonWithTitle:(NSString *)title
                                  color:(UIColor *)color
                                   size:(CGSize)size
                               fontSize:(CGFloat)fontSize {
    SKShapeNode *sprite = [SKShapeNode shapeNodeWithRectOfSize:size cornerRadius:12.0];
    sprite.fillColor = [UIColor colorWithRed:0.03 green:0.16 blue:0.13 alpha:0.94];
    sprite.strokeColor = [UIColor colorWithRed:0.94 green:0.78 blue:0.34 alpha:0.96];
    sprite.lineWidth = 2.0;

    SKLabelNode *label = [SKLabelNode labelNodeWithFontNamed:@"Helvetica-Bold"];
    label.text = title;
    label.fontSize = fontSize;
    label.fontColor = [UIColor whiteColor];
    label.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
    label.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    label.zPosition = 2;
    [sprite addChild:label];

    return sprite;
}

#pragma mark - Pause Overlay

- (void)showPauseOverlay {
    if (_pauseOverlay) return;

    // Semi-transparent dim background
    _pauseOverlay = [SKSpriteNode spriteNodeWithColor:[[UIColor blackColor] colorWithAlphaComponent:0.5]
                                                 size:self.size];
    _pauseOverlay.anchorPoint = CGPointMake(0.5, 0.5);
    _pauseOverlay.position = CGPointMake(self.size.width / 2.0, self.size.height / 2.0);
    _pauseOverlay.name = PauseOverlayName;
    _pauseOverlay.zPosition = 500;
    [self addChild:_pauseOverlay];

    // Panel
    CGSize panelSize = CGSizeMake(300, 320);
    _pausePanel = [SKSpriteNode spriteNodeWithColor:[UIColor colorWithWhite:0.15 alpha:0.95]
                                             size:panelSize];
    _pausePanel.anchorPoint = CGPointMake(0.5, 0.5);
    _pausePanel.position = CGPointMake(self.size.width / 2.0, self.size.height / 2.0);
    _pausePanel.name = PausePanelName;
    _pausePanel.zPosition = 501;
    [self addChild:_pausePanel];

    // "Paused" title
    SKLabelNode *pausedLabel = [SKLabelNode labelNodeWithFontNamed:@"Helvetica-Bold"];
    pausedLabel.text = @"PAUSED";
    pausedLabel.fontSize = 36;
    pausedLabel.fontColor = [UIColor whiteColor];
    pausedLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
    pausedLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    pausedLabel.position = CGPointMake(0, 110);
    pausedLabel.zPosition = 2;
    [_pausePanel addChild:pausedLabel];

    // Resume button
    CGSize btnSize = CGSizeMake(220, 50);
    CGFloat btnY = 30;
    CGFloat btnSpacing = 62;
    SKShapeNode *resumeBtn = [self createButtonWithTitle:@"Resume"
                                                    color:[UIColor colorWithRed:0.2 green:0.7 blue:0.3 alpha:1.0]
                                                     size:btnSize
                                                 fontSize:24];
    resumeBtn.position = CGPointMake(0, btnY);
    resumeBtn.name = OverlayResumeButtonName;
    resumeBtn.zPosition = 2;
    [_pausePanel addChild:resumeBtn];

    // Restart button
    SKShapeNode *restartBtn = [self createButtonWithTitle:@"Restart"
                                                     color:[UIColor colorWithRed:0.9 green:0.55 blue:0.1 alpha:1.0]
                                                      size:btnSize
                                                  fontSize:24];
    restartBtn.position = CGPointMake(0, btnY - btnSpacing);
    restartBtn.name = OverlayRestartButtonName;
    restartBtn.zPosition = 2;
    [_pausePanel addChild:restartBtn];

    // Menu button
    SKShapeNode *menuBtn = [self createButtonWithTitle:@"Menu"
                                                  color:[UIColor colorWithRed:0.3 green:0.4 blue:0.55 alpha:1.0]
                                                   size:btnSize
                                               fontSize:24];
    menuBtn.position = CGPointMake(0, btnY - btnSpacing * 2);
    menuBtn.name = OverlayMenuButtonName;
    menuBtn.zPosition = 2;
    [_pausePanel addChild:menuBtn];

    // Pause scene AFTER overlay is fully visible
    _isPausedByUser = YES;
    self.paused = YES;
}

- (void)dismissPauseOverlay {
    // Unpause first so we can interact normally
    _isPausedByUser = NO;
    self.paused = NO;

    // Remove overlay directly (no animation needed)
    [_pauseOverlay removeFromParent];
    _pauseOverlay = nil;
    [_pausePanel removeFromParent];
    _pausePanel = nil;
}

#pragma mark - Touch Handling

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];

    // Use nodesAtPoint: to get ALL nodes at touch location (button + label + panel)
    NSArray<SKNode *> *hitNodes = [self nodesAtPoint:location];

    for (SKNode *n in hitNodes) {
        // Overlay buttons (only when overlay is visible)
        if (_pauseOverlay) {
            if ([n.name isEqualToString:OverlayResumeButtonName]) {
                [self dismissPauseOverlay];
                return;
            }
            if ([n.name isEqualToString:OverlayRestartButtonName]) {
                [self dismissPauseOverlay];
                [self restartGame];
                return;
            }
            if ([n.name isEqualToString:OverlayMenuButtonName]) {
                [self dismissPauseOverlay];
                MainMenuScene *mainMenu = [MainMenuScene sceneWithSize:self.size];
                mainMenu.scaleMode = self.scaleMode;
                SKTransition *transition = [SKTransition fadeWithDuration:0.5];
                [self.view presentScene:mainMenu transition:transition];
                return;
            }
        }

        // Pause button (only when overlay is NOT visible)
        if ([n.name isEqualToString:PauseButtonName] && !_pauseOverlay) {
            [self showPauseOverlay];
            return;
        }
    }
}

#pragma mark - Button Actions

- (void)backButtonTapped:(id)sender {
    if (self.gameDelegate && [self.gameDelegate respondsToSelector:@selector(gameSceneDidRequestReturnToMainMenu)]) {
        [self.gameDelegate gameSceneDidRequestReturnToMainMenu];
    }
}

- (void)restartButtonTapped:(id)sender {
    [self restartGame];
}

#pragma mark - Game Control Methods

- (void)restartGame {
    // Reset game state
    _score = 0;
    _gameTime = 0;
    _isCountingDown = NO;
    _countdownTime = 0;
    
    [self updateScoreLabel];
    [self updateTimerLabel];
    
    // Remove all game-specific nodes (keep UI and background)
    NSMutableArray *nodesToRemove = [NSMutableArray array];
    for (SKNode *child in self.children) {
        if (![child.name isEqualToString:BackgroundTextureKey] &&
            ![child.name isEqualToString:ScoreLabelName] &&
            ![child.name isEqualToString:TimerLabelName] &&
            ![child.name isEqualToString:PauseButtonName]) {
            [nodesToRemove addObject:child];
        }
    }
    
    for (SKNode *node in nodesToRemove) {
        [node removeFromParent];
    }
    
    // Re-setup game elements
    [self setupGameElements];
}

- (void)updateScore:(NSInteger)newScore {
    _score = newScore;
    [self updateScoreLabel];
}

- (void)updateScoreLabel {
    _scoreLabel.text = [NSString stringWithFormat:@"Score: %ld", (long)_score];
}

- (void)startCountdownFrom:(NSTimeInterval)seconds {
    _hasCountdown = YES;
    _isCountingDown = YES;
    _countdownTime = seconds;
    [self updateTimerLabel];
}

- (void)updateTimerLabel {
    if (_hasCountdown) {
        NSInteger minutes = (NSInteger)(_countdownTime / 60);
        NSInteger seconds = (NSInteger)(_countdownTime) % 60;
        _timerLabel.text = [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
        
        // Change color when time is running low
        if (_countdownTime <= 10) {
            _timerLabel.fontColor = [UIColor redColor];
        } else {
            _timerLabel.fontColor = [UIColor yellowColor];
        }
    } else {
        // Show elapsed time
        NSInteger minutes = (NSInteger)(_gameTime / 60);
        NSInteger seconds = (NSInteger)(_gameTime) % 60;
        _timerLabel.text = [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
    }
}

- (void)handleCountdownFinished {
    _isCountingDown = NO;
    // Subclasses can override this method or listen for notifications
    [self countdownDidFinish];
}

- (void)countdownDidFinish {
    // Default implementation - can be overridden by subclasses
}

- (void)gameOver {
    // Stop any timers
    _isCountingDown = NO;
    [_countdownTimer invalidate];
    _countdownTimer = nil;
    
    // Show game over message
    SKLabelNode *gameOverLabel = [SKLabelNode labelNodeWithFontNamed:@"Helvetica-Bold"];
    gameOverLabel.text = @"Game Over!";
    gameOverLabel.fontSize = 48;
    gameOverLabel.fontColor = [UIColor redColor];
    gameOverLabel.position = CGPointMake(self.size.width / 2.0, self.size.height / 2.0);
    gameOverLabel.zPosition = 200;
    [self addChild:gameOverLabel];
    
    // Fade out effect
    SKAction *fadeOut = [SKAction fadeOutWithDuration:2.0];
    [gameOverLabel runAction:fadeOut];
}

#pragma mark - Customization Hooks

- (void)setupGameElements {
    // Override this method in subclasses to add game-specific elements
}

@end
