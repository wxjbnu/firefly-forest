#import "SSFireflyForestScene.h"
#import "LevelSelectScene.h"

#pragma mark - Sound Event Types

typedef NS_ENUM(NSInteger, SSSoundEvent) {
    SSSoundEventLanternSwitch,
    SSSoundEventCatchSuccess,
    SSSoundEventCatchWrong,
    SSSoundEventCombo,
    SSSoundEventRareCatch,
    SSSoundEventLevelComplete,
    SSSoundEventLevelFail,
    SSSoundEventTimeWarning
};

static const NSInteger SSMaxFireflyForestLevel = 50;
static NSString * const SSUnlockedLevelKey = @"FireflyForestUnlockedLevel";

#pragma mark - Private Interface

@interface SSFireflyForestScene ()

// Core gameplay state
@property (nonatomic, assign) CGRect playRect;
@property (nonatomic, assign) NSInteger captured;
@property (nonatomic, assign) NSInteger targetCapture;
@property (nonatomic, assign) NSInteger lanternLightType;
@property (nonatomic, copy) NSString *feedbackMessage;
@property (nonatomic, assign) NSTimeInterval feedbackUntilTime;
@property (nonatomic, assign) BOOL levelEnded;
@property (nonatomic, assign) BOOL levelCleared;
@property (nonatomic, strong) NSMutableArray<NSMutableDictionary *> *fireflies;
@property (nonatomic, strong) SKSpriteNode *player;
@property (nonatomic, strong) SKNode *forestNode;
@property (nonatomic, strong) SKLabelNode *headerLabel;
@property (nonatomic, strong) SKLabelNode *statusLabel;
@property (nonatomic, assign) CGFloat controlBarY;
@property (nonatomic, strong) SKNode *resultOverlay;

// Visual effects
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, SKEmitterNode *> *glowEmitters;
@property (nonatomic, strong) SKEmitterNode *lanternGlowEmitter;
@property (nonatomic, strong) SKShapeNode *lanternGlowSprite;

// Combo system
@property (nonatomic, assign) NSInteger comboCount;
@property (nonatomic, assign) NSInteger lastCatchType;
@property (nonatomic, assign) NSTimeInterval comboExpireTime;
@property (nonatomic, strong) SKLabelNode *comboLabel;

// Score tracking
@property (nonatomic, assign) NSInteger levelScore;
@property (nonatomic, assign) NSInteger totalScore;

// Time limit
@property (nonatomic, assign) NSTimeInterval levelTimeLimit;
@property (nonatomic, assign) NSTimeInterval timeRemaining;
@property (nonatomic, assign) BOOL timeWarningTriggered;
@property (nonatomic, assign) BOOL advancingLevel;

// Progress bar
@property (nonatomic, strong) SKShapeNode *progressBarBg;
@property (nonatomic, strong) SKShapeNode *progressBarFill;
@property (nonatomic, assign) CGFloat progressBarMaxWidth;

// Animation / transition
@property (nonatomic, assign) CGPoint playerTargetPosition;
@property (nonatomic, assign) BOOL isMovingPlayer;

@end

@implementation SSFireflyForestScene

#pragma mark - Helpers

- (void)ss_addGeneratedTextureBackdropNamed:(NSString *)backgroundName accentNames:(NSArray<NSString *> *)accentNames {
    UIImage *backgroundImage = [UIImage imageNamed:backgroundName];
    if (backgroundImage) {
        SKTexture *texture = [SKTexture textureWithImage:backgroundImage];
        SKSpriteNode *background = [SKSpriteNode spriteNodeWithTexture:texture size:self.size];
        background.position = CGPointMake(self.size.width / 2.0, self.size.height / 2.0);
        background.zPosition = -1000.0;
        background.alpha = 1.0;
        [self addChild:background];
    }

    CGFloat iconSize = 46.0;
    CGFloat spacing = 54.0;
    CGFloat startX = self.size.width - (accentNames.count * spacing) - 18.0;
    CGFloat y = self.size.height * 0.18;
    for (NSInteger index = 0; index < accentNames.count; index++) {
        NSString *name = accentNames[index];
        UIImage *image = [UIImage imageNamed:name];
        if (!image) {
            continue;
        }
        SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithTexture:[SKTexture textureWithImage:image] size:CGSizeMake(iconSize, iconSize)];
        sprite.position = CGPointMake(startX + index * spacing, y);
        sprite.zPosition = 900.0;
        sprite.alpha = 0.92;
        [self addChild:sprite];
    }
}

- (SKSpriteNode *)ss_spriteNamed:(NSString *)imageName fallbackColor:(UIColor *)color size:(CGSize)size {
    UIImage *image = [UIImage imageNamed:imageName];
    if (image) {
        SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithTexture:[SKTexture textureWithImage:image] size:size];
        sprite.color = [UIColor whiteColor];
        sprite.colorBlendFactor = 0.0;
        return sprite;
    }
    return [SKSpriteNode spriteNodeWithColor:color size:size];
}

#pragma mark - Type Helpers

- (NSString *)fireflyImageNameForType:(NSInteger)type {
    if (type == 1) return @"ff_firefly_green";
    if (type == 2) return @"ff_firefly_blue";
    return @"ff_firefly_gold";
}

- (NSString *)lightNameForType:(NSInteger)type {
    if (type == 1) return @"Green";
    if (type == 2) return @"Blue";
    return @"Gold";
}

- (NSInteger)activeLightColorCount {
    return self.currentLevel <= 1 ? 2 : 3;
}

- (NSInteger)normalizedCurrentLevel {
    return MAX(1, MIN(SSMaxFireflyForestLevel, self.currentLevel));
}

- (UIColor *)colorForType:(NSInteger)type {
    switch (type) {
        case 0: return [UIColor colorWithRed:1.0 green:0.90 blue:0.36 alpha:1.0];
        case 1: return [UIColor colorWithRed:0.44 green:0.98 blue:0.60 alpha:1.0];
        default: return [UIColor colorWithRed:0.42 green:0.74 blue:1.0 alpha:1.0];
    }
}

#pragma mark - Lifecycle

- (void)didMoveToView:(SKView *)view {
    [super didMoveToView:view];
    self.scoreLabel.hidden = NO;
    self.timerLabel.hidden = NO;
    self.backgroundColor = [UIColor colorWithRed:0.05 green:0.11 blue:0.10 alpha:1.0];
    [self ss_addGeneratedTextureBackdropNamed:@"forest_bg" accentNames:@[]];
    self.playRect = CGRectMake(24.0, self.size.height * 0.24, self.size.width - 48.0, self.size.height * 0.54);
    self.fireflies = [NSMutableArray array];
    self.glowEmitters = [NSMutableDictionary dictionary];
    self.currentLevel = [self normalizedCurrentLevel];
    self.targetCapture = MIN(24, 6 + self.currentLevel * 2);
    self.lanternLightType = 0;
    self.comboCount = 0;
    self.lastCatchType = -1;
    self.levelScore = 0;
    self.totalScore = self.score;
    self.timeWarningTriggered = NO;
    self.advancingLevel = NO;
    self.levelCleared = NO;
    self.isMovingPlayer = NO;
    [self setupScene];
    [self startArea];
}

- (void)setupScene {
    UIEdgeInsets safe = self.view.safeAreaInsets;
    CGFloat topPad = MAX(safe.top, 20.0);
    CGFloat sidePad = MAX(MAX(safe.left, safe.right), 15.0);

    self.scoreLabel.fontSize = 16.0;
    self.scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    self.scoreLabel.position = CGPointMake(sidePad + 8.0, self.size.height - topPad - 18.0);

    self.timerLabel.fontSize = 17.0;
    self.timerLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeRight;
    self.timerLabel.position = CGPointMake(self.size.width - sidePad - 72.0, self.size.height - topPad - 18.0);

    SKNode *pauseButton = [self childNodeWithName:@"pauseButton"];
    if (pauseButton) {
        pauseButton.position = CGPointMake(self.size.width - sidePad - 26.0, self.size.height - topPad - 20.0);
    }

    // Header label
    self.headerLabel = [SKLabelNode labelNodeWithFontNamed:@"Helvetica-Bold"];
    self.headerLabel.fontSize = 18.0;
    self.headerLabel.position = CGPointMake(self.size.width / 2.0, self.size.height - topPad - 54.0);
    self.headerLabel.zPosition = 100;
    [self addChild:self.headerLabel];

    // Status / feedback label
    self.statusLabel = [SKLabelNode labelNodeWithFontNamed:@"Helvetica"];
    self.statusLabel.fontSize = 12.0;
    self.statusLabel.position = CGPointMake(self.size.width / 2.0, self.size.height - topPad - 76.0);
    self.statusLabel.zPosition = 100;
    [self addChild:self.statusLabel];

    // Combo label
    self.comboLabel = [SKLabelNode labelNodeWithFontNamed:@"Helvetica-Bold"];
    self.comboLabel.fontSize = 14.0;
    self.comboLabel.fontColor = [UIColor colorWithRed:1.0 green:0.85 blue:0.2 alpha:1.0];
    self.comboLabel.position = CGPointMake(self.size.width / 2.0, self.size.height - topPad - 94.0);
    self.comboLabel.zPosition = 100;
    self.comboLabel.hidden = YES;
    [self addChild:self.comboLabel];

    // Progress bar background
    self.progressBarMaxWidth = self.size.width * 0.55;
    CGFloat barHeight = 6.0;
    CGFloat barY = self.size.height - topPad - 108.0;
    self.progressBarBg = [SKShapeNode shapeNodeWithRectOfSize:CGSizeMake(self.progressBarMaxWidth, barHeight) cornerRadius:barHeight / 2.0];
    self.progressBarBg.fillColor = [UIColor colorWithWhite:0.2 alpha:0.6];
    self.progressBarBg.strokeColor = [UIColor clearColor];
    self.progressBarBg.position = CGPointMake(self.size.width / 2.0, barY);
    self.progressBarBg.zPosition = 100;
    [self addChild:self.progressBarBg];

    // Progress bar fill
    self.progressBarFill = [SKShapeNode shapeNodeWithRectOfSize:CGSizeMake(0, barHeight) cornerRadius:barHeight / 2.0];
    self.progressBarFill.fillColor = [UIColor colorWithRed:0.5 green:0.9 blue:0.5 alpha:0.9];
    self.progressBarFill.strokeColor = [UIColor clearColor];
    self.progressBarFill.position = CGPointMake(self.size.width / 2.0 - self.progressBarMaxWidth / 2.0, barY);
    self.progressBarFill.zPosition = 101;
    [self addChild:self.progressBarFill];

    // Game container node
    self.forestNode = [[SKNode alloc] init];
    [self addChild:self.forestNode];

    self.controlBarY = MAX(safe.bottom + 54.0, 72.0);
}

#pragma mark - Area / Level Start

- (void)startArea {
    [self.fireflies removeAllObjects];
    self.captured = 0;
    self.levelEnded = NO;
    self.levelCleared = NO;
    [self.resultOverlay removeFromParent];
    self.resultOverlay = nil;
    self.lanternLightType = 0;
    self.feedbackMessage = @"";
    self.feedbackUntilTime = 0;
    self.comboCount = 0;
    self.lastCatchType = -1;
    self.comboExpireTime = 0;
    self.isMovingPlayer = NO;
    self.timeWarningTriggered = NO;
    self.advancingLevel = NO;

    // Time limit decreases slightly as levels progress (min 25s)
    self.levelTimeLimit = MAX(25.0, 55.0 - self.currentLevel * 0.65);
    self.timeRemaining = self.levelTimeLimit;
    [self startCountdownFrom:self.levelTimeLimit];

    NSInteger colorCount = [self activeLightColorCount];
    NSInteger fireflyCount = MIN(34, 10 + self.currentLevel * 2);

    for (NSInteger idx = 0; idx < fireflyCount; idx++) {
        CGFloat x = CGRectGetMinX(self.playRect) + 20 + arc4random_uniform((uint32_t)(CGRectGetWidth(self.playRect) - 40));
        CGFloat y = CGRectGetMinY(self.playRect) + 20 + arc4random_uniform((uint32_t)(CGRectGetHeight(self.playRect) - 40));
        NSInteger type = arc4random_uniform((uint32_t)colorCount);

        // Rare golden firefly chance (only on level 3+)
        BOOL isRare = (self.currentLevel >= 3) && (arc4random_uniform(100) < 8);
        if (isRare) {
            type = 3; // Special rare type
        }

        CGFloat baseDx = (arc4random_uniform(7) - 3) / 10.0;
        CGFloat baseDy = (arc4random_uniform(7) - 3) / 10.0;

        NSMutableDictionary *firefly = [@{
            @"x": @(x),
            @"y": @(y),
            @"type": @(type),
            @"dx": @(baseDx),
            @"dy": @(baseDy),
            @"floatOffset": @(arc4random_uniform(100) / 100.0 * M_PI * 2.0),
            @"floatSpeed": @(0.8 + arc4random_uniform(40) / 100.0),
            @"isRare": @(isRare)
        } mutableCopy];
        [self.fireflies addObject:firefly];
    }

    // Player lantern
    self.player = [self ss_spriteNamed:@"ff_player_lantern"
                         fallbackColor:[UIColor colorWithRed:0.82 green:0.90 blue:0.76 alpha:1.0]
                                  size:CGSizeMake(42.0, 42.0)];
    self.player.position = CGPointMake(CGRectGetMidX(self.playRect), CGRectGetMinY(self.playRect) + 30.0);
    self.playerTargetPosition = self.player.position;
    [self setupLanternGlow];
    [self redraw];
}

#pragma mark - Lantern Glow

- (void)setupLanternGlow {
    // Soft glow sprite behind the lantern
    self.lanternGlowSprite = [SKShapeNode shapeNodeWithCircleOfRadius:45.0];
    self.lanternGlowSprite.fillColor = [UIColor colorWithRed:1.0 green:0.9 blue:0.4 alpha:0.15];
    self.lanternGlowSprite.strokeColor = [UIColor clearColor];
    self.lanternGlowSprite.zPosition = -1.0;
    [self.player addChild:self.lanternGlowSprite];

    // Pulsing animation
    SKAction *pulseOut = [SKAction scaleTo:1.15 duration:0.9];
    SKAction *pulseIn = [SKAction scaleTo:0.95 duration:0.9];
    SKAction *pulse = [SKAction sequence:@[pulseOut, pulseIn]];
    [self.lanternGlowSprite runAction:[SKAction repeatActionForever:pulse]];
}

- (void)updateLanternGlowColor {
    UIColor *color = [self colorForType:self.lanternLightType];
    CGFloat r, g, b, a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    self.lanternGlowSprite.fillColor = [UIColor colorWithRed:r green:g blue:b alpha:0.18];
}

#pragma mark - Sound Hooks

- (void)triggerSoundEvent:(SSSoundEvent)event {
    // Reserved for future audio playback. Release builds keep this silent.
    (void)event;
}

#pragma mark - Update Loop

- (void)update:(CFTimeInterval)currentTime {
    [super update:currentTime];
    if (self.levelEnded) return;

    // Update countdown
    if (self.hasCountdown && self.timeRemaining > 0) {
        // GameScene base class decrements its internal ivar _countdownTime each frame.
        // We mirror that into our own timeRemaining property.
        self.timeRemaining = MAX(0, [self valueForKey:@"countdownTime"] ? [[self valueForKey:@"countdownTime"] doubleValue] : self.timeRemaining);
        if (self.timeRemaining <= 10 && !self.timeWarningTriggered) {
            self.timeWarningTriggered = YES;
            [self triggerSoundEvent:SSSoundEventTimeWarning];
            // Flash timer label red
            SKAction *flash = [SKAction sequence:@[[SKAction colorizeWithColor:[UIColor redColor] colorBlendFactor:1.0 duration:0.2],
                                                    [SKAction colorizeWithColorBlendFactor:0.0 duration:0.2]]];
            [self.timerLabel runAction:[SKAction repeatAction:flash count:5]];
        }
        if (self.timeRemaining <= 0) {
            [self handleTimeUp];
        }
    }

    // Update combo expiration
    if (self.comboCount > 0 && CACurrentMediaTime() > self.comboExpireTime) {
        self.comboCount = 0;
        self.lastCatchType = -1;
        self.comboLabel.hidden = YES;
    }

    // Move player smoothly toward target
    if (self.isMovingPlayer) {
        CGFloat lerpFactor = 0.18;
        CGFloat newX = self.player.position.x + (self.playerTargetPosition.x - self.player.position.x) * lerpFactor;
        CGFloat newY = self.player.position.y + (self.playerTargetPosition.y - self.player.position.y) * lerpFactor;
        self.player.position = CGPointMake(newX, newY);
        if (hypot(self.playerTargetPosition.x - newX, self.playerTargetPosition.y - newY) < 2.0) {
            self.isMovingPlayer = NO;
        }
    }

    // Firefly movement with difficulty scaling
    CGFloat speed = 0.9 + MIN(1.6, self.currentLevel * 0.12);
    CGFloat time = currentTime;

    for (NSMutableDictionary *firefly in self.fireflies) {
        CGFloat dx = [firefly[@"dx"] doubleValue];
        CGFloat dy = [firefly[@"dy"] doubleValue];
        CGFloat x = [firefly[@"x"] doubleValue] + dx * speed;
        CGFloat y = [firefly[@"y"] doubleValue] + dy * speed;

        // Slight random direction jitter at higher levels (smarter avoidance feel)
        if (self.currentLevel >= 4 && arc4random_uniform(100) < 3) {
            dx += (arc4random_uniform(5) - 2) / 20.0;
            dy += (arc4random_uniform(5) - 2) / 20.0;
            // Clamp
            dx = MAX(-0.8, MIN(0.8, dx));
            dy = MAX(-0.8, MIN(0.8, dy));
            firefly[@"dx"] = @(dx);
            firefly[@"dy"] = @(dy);
        }

        // Bounce off playRect edges
        if (x < CGRectGetMinX(self.playRect) + 12 || x > CGRectGetMaxX(self.playRect) - 12) {
            firefly[@"dx"] = @(-dx);
        }
        if (y < CGRectGetMinY(self.playRect) + 12 || y > CGRectGetMaxY(self.playRect) - 12) {
            firefly[@"dy"] = @(-dy);
        }

        // Clamp position
        x = MAX(CGRectGetMinX(self.playRect) + 12, MIN(CGRectGetMaxX(self.playRect) - 12, x));
        y = MAX(CGRectGetMinY(self.playRect) + 12, MIN(CGRectGetMaxY(self.playRect) - 12, y));

        firefly[@"x"] = @(x);
        firefly[@"y"] = @(y);

        // Update bobbing offset
        CGFloat floatOffset = [firefly[@"floatOffset"] doubleValue] + 0.03 * [firefly[@"floatSpeed"] doubleValue];
        firefly[@"floatOffset"] = @(floatOffset);
    }

    [self redraw];
}

- (void)handleTimeUp {
    if (self.captured >= self.targetCapture) {
        [self finishAreaCleared];
        return;
    }
    [self finishAreaFailed];
}

- (void)countdownDidFinish {
    if (self.levelEnded) {
        return;
    }
    if (self.captured >= self.targetCapture) {
        [self finishAreaCleared];
    } else {
        [self finishAreaFailed];
    }
}

- (void)finishAreaFailed {
    if (self.levelEnded) {
        return;
    }
    self.levelEnded = YES;
    self.levelCleared = NO;
    self.hasCountdown = NO;
    self.advancingLevel = NO;
    self.feedbackMessage = @"";
    self.feedbackUntilTime = 0;
    self.comboCount = 0;
    self.comboLabel.hidden = YES;
    [self triggerSoundEvent:SSSoundEventLevelFail];
    self.statusLabel.text = [NSString stringWithFormat:@"Failed  %ld / %ld", (long)self.captured, (long)self.targetCapture];
    self.statusLabel.fontColor = [UIColor redColor];
    [self redraw];
    [self showResultOverlayWithWin:NO];
}

- (void)finishAreaCleared {
    if (self.levelEnded && self.advancingLevel) {
        return;
    }
    self.captured = self.targetCapture;
    [self.fireflies removeAllObjects];
    self.levelEnded = YES;
    self.levelCleared = YES;
    self.hasCountdown = NO;
    [self unlockNextLevelIfNeeded];
    [self triggerSoundEvent:SSSoundEventLevelComplete];
    self.statusLabel.text = @"Area cleared!";
    self.statusLabel.fontColor = [UIColor colorWithRed:0.5 green:1.0 blue:0.5 alpha:1.0];
    [self redraw];
    [self showResultOverlayWithWin:YES];
}

- (void)scheduleAdvanceToNextArea {
    if (self.advancingLevel) {
        return;
    }
    self.advancingLevel = YES;
    [self removeActionForKey:@"advanceToNextArea"];
    SKAction *wait = [SKAction waitForDuration:0.85];
    SKAction *advance = [SKAction runBlock:^{
        [self advanceAfterLevelEnd];
    }];
    [self runAction:[SKAction sequence:@[wait, advance]] withKey:@"advanceToNextArea"];
}

- (void)advanceAfterLevelEnd {
    if (!self.levelEnded || !self.view) {
        return;
    }
    BOOL didClear = self.levelCleared;
    SSFireflyForestScene *scene = [SSFireflyForestScene sceneWithSize:self.size];
    scene.currentLevel = didClear ? MIN(SSMaxFireflyForestLevel, self.currentLevel + 1) : self.currentLevel;
    scene.score = didClear ? self.totalScore : 0;
    scene.scaleMode = self.scaleMode;
    SKTransition *transition = [SKTransition fadeWithDuration:0.35];
    [self.view presentScene:scene transition:transition];
}

- (void)returnToLevelSelect {
    if (!self.view) {
        return;
    }
    LevelSelectScene *levelScene = [LevelSelectScene sceneWithSize:self.size];
    levelScene.scaleMode = self.scaleMode;
    [self.view presentScene:levelScene transition:[SKTransition fadeWithDuration:0.3]];
}

- (void)restartGame {
    [self removeActionForKey:@"advanceToNextArea"];
    SSFireflyForestScene *scene = [SSFireflyForestScene sceneWithSize:self.size];
    scene.currentLevel = self.currentLevel;
    scene.score = 0;
    scene.scaleMode = self.scaleMode;
    SKTransition *transition = [SKTransition fadeWithDuration:0.25];
    [self.view presentScene:scene transition:transition];
}

- (void)unlockNextLevelIfNeeded {
    NSInteger unlocked = [[NSUserDefaults standardUserDefaults] integerForKey:SSUnlockedLevelKey];
    if (unlocked < 1) {
        unlocked = 1;
    }
    NSInteger nextLevel = MIN(SSMaxFireflyForestLevel, self.currentLevel + 1);
    if (nextLevel > unlocked) {
        [[NSUserDefaults standardUserDefaults] setInteger:nextLevel forKey:SSUnlockedLevelKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)showResultOverlayWithWin:(BOOL)didWin {
    [self.resultOverlay removeFromParent];

    SKNode *overlay = [[SKNode alloc] init];
    overlay.name = @"resultOverlay";
    overlay.zPosition = 700.0;
    self.resultOverlay = overlay;
    [self addChild:overlay];

    SKSpriteNode *dim = [SKSpriteNode spriteNodeWithColor:[[UIColor blackColor] colorWithAlphaComponent:0.58] size:self.size];
    dim.position = CGPointMake(self.size.width / 2.0, self.size.height / 2.0);
    dim.name = @"resultOverlay";
    dim.zPosition = 0.0;
    [overlay addChild:dim];

    CGSize panelSize = CGSizeMake(MIN(self.size.width - 46.0, 340.0), 250.0);
    SKShapeNode *panel = [SKShapeNode shapeNodeWithRectOfSize:panelSize cornerRadius:18.0];
    panel.position = CGPointMake(self.size.width / 2.0, self.size.height / 2.0 + 14.0);
    panel.fillColor = [UIColor colorWithRed:0.02 green:0.11 blue:0.10 alpha:0.96];
    panel.strokeColor = didWin ? [UIColor colorWithRed:0.54 green:1.0 blue:0.62 alpha:1.0] : [UIColor colorWithRed:1.0 green:0.36 blue:0.30 alpha:1.0];
    panel.lineWidth = 3.0;
    panel.name = @"resultOverlay";
    panel.zPosition = 1.0;
    [overlay addChild:panel];

    SKLabelNode *title = [SKLabelNode labelNodeWithFontNamed:@"Helvetica-Bold"];
    title.text = didWin ? @"Area Clear" : @"Area Failed";
    title.fontSize = 30.0;
    title.fontColor = didWin ? [UIColor colorWithRed:0.64 green:1.0 blue:0.68 alpha:1.0] : [UIColor colorWithRed:1.0 green:0.42 blue:0.38 alpha:1.0];
    title.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    title.position = CGPointMake(0.0, 82.0);
    title.zPosition = 2.0;
    [panel addChild:title];

    SKLabelNode *details = [SKLabelNode labelNodeWithFontNamed:@"Helvetica-Bold"];
    details.text = [NSString stringWithFormat:@"Area %ld   %@   %ld/%ld", (long)self.currentLevel, didWin ? @"Won" : @"Lost", (long)self.captured, (long)self.targetCapture];
    details.fontSize = 15.0;
    details.fontColor = [UIColor colorWithRed:0.88 green:0.98 blue:0.94 alpha:0.94];
    details.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    details.position = CGPointMake(0.0, 36.0);
    details.zPosition = 2.0;
    [panel addChild:details];

    SKLabelNode *scoreText = [SKLabelNode labelNodeWithFontNamed:@"Helvetica"];
    scoreText.text = [NSString stringWithFormat:@"Score %ld", (long)self.totalScore];
    scoreText.fontSize = 13.0;
    scoreText.fontColor = [UIColor colorWithRed:0.82 green:0.90 blue:0.88 alpha:0.88];
    scoreText.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    scoreText.position = CGPointMake(0.0, 8.0);
    scoreText.zPosition = 2.0;
    [panel addChild:scoreText];

    [self addResultButtonWithTitle:(didWin && self.currentLevel < SSMaxFireflyForestLevel) ? @"Next" : @"Retry"
                              name:didWin ? @"result_next" : @"result_retry"
                          position:CGPointMake(-74.0, -68.0)
                            toNode:panel
                             color:[UIColor colorWithRed:0.03 green:0.16 blue:0.13 alpha:0.94]];
    [self addResultButtonWithTitle:@"Areas"
                              name:@"result_areas"
                          position:CGPointMake(74.0, -68.0)
                            toNode:panel
                             color:[UIColor colorWithRed:0.03 green:0.16 blue:0.13 alpha:0.94]];
}

- (void)addResultButtonWithTitle:(NSString *)title
                            name:(NSString *)name
                        position:(CGPoint)position
                          toNode:(SKNode *)parent
                           color:(UIColor *)color {
    SKShapeNode *button = [SKShapeNode shapeNodeWithRectOfSize:CGSizeMake(122.0, 46.0) cornerRadius:10.0];
    button.position = position;
    button.fillColor = color;
    button.strokeColor = [UIColor colorWithRed:0.94 green:0.78 blue:0.34 alpha:0.96];
    button.lineWidth = 2.0;
    button.name = name;
    button.zPosition = 2.0;
    [parent addChild:button];

    SKLabelNode *label = [SKLabelNode labelNodeWithFontNamed:@"Helvetica-Bold"];
    label.text = title;
    label.fontSize = 18.0;
    label.fontColor = [UIColor whiteColor];
    label.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    label.name = name;
    label.zPosition = 3.0;
    [button addChild:label];
}

#pragma mark - Catch Logic

- (CGFloat)catchRadius {
    return 42.0;
}

- (void)setFeedback:(NSString *)message duration:(NSTimeInterval)duration {
    self.feedbackMessage = message;
    self.feedbackUntilTime = CACurrentMediaTime() + duration;
}

- (void)showCatchFeedbackAtPoint:(CGPoint)point color:(UIColor *)color success:(BOOL)success {
    // Burst ring
    SKShapeNode *burst = [SKShapeNode shapeNodeWithCircleOfRadius:success ? 18.0 : 14.0];
    burst.position = point;
    burst.strokeColor = color;
    burst.fillColor = [color colorWithAlphaComponent:success ? 0.24 : 0.10];
    burst.lineWidth = success ? 4.0 : 2.0;
    burst.zPosition = 40.0;
    [self addChild:burst];

    SKAction *scale = [SKAction scaleTo:success ? 2.2 : 1.6 duration:0.28];
    SKAction *fade = [SKAction fadeOutWithDuration:0.28];
    [burst runAction:[SKAction sequence:@[[SKAction group:@[scale, fade]], [SKAction removeFromParent]]]];

    if (success) {
        // Particle burst effect using SKEmitterNode (programmatic, no external assets)
        [self spawnParticleBurstAt:point color:color];
    }
}

- (void)spawnParticleBurstAt:(CGPoint)point color:(UIColor *)color {
    SKEmitterNode *emitter = [[SKEmitterNode alloc] init];
    emitter.particleBirthRate = 60;
    emitter.numParticlesToEmit = 18;
    emitter.particleLifetime = 0.5;
    emitter.particleLifetimeRange = 0.2;
    emitter.position = point;
    emitter.particlePositionRange = CGVectorMake(4.0, 4.0);
    emitter.particleSpeed = 60.0;
    emitter.particleSpeedRange = 30.0;
    emitter.emissionAngleRange = M_PI * 2.0;
    emitter.particleAlpha = 0.8;
    emitter.particleAlphaSpeed = -1.5;
    emitter.particleScale = 0.25;
    emitter.particleScaleRange = 0.1;
    emitter.particleScaleSpeed = -0.4;
    emitter.particleColor = color;
    emitter.particleColorBlendFactor = 1.0;
    emitter.particleBlendMode = SKBlendModeAdd;
    emitter.particleTexture = [SKTexture textureWithImage:[self circleImageWithDiameter:8 color:[UIColor whiteColor]]];
    emitter.zPosition = 50.0;
    [self addChild:emitter];

    // Auto-remove after burst completes
    SKAction *wait = [SKAction waitForDuration:1.0];
    SKAction *remove = [SKAction removeFromParent];
    [emitter runAction:[SKAction sequence:@[wait, remove]]];
}

- (UIImage *)circleImageWithDiameter:(CGFloat)diameter color:(UIColor *)color {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(diameter, diameter), NO, 0.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [color setFill];
    CGContextFillEllipseInRect(ctx, CGRectMake(0, 0, diameter, diameter));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)tryCatchAtPoint:(CGPoint)location {
    if (self.levelEnded) return;

    NSMutableArray<NSMutableDictionary *> *caughtFireflies = [NSMutableArray array];
    NSMutableDictionary *wrongFirefly = nil;

    for (NSMutableDictionary *firefly in self.fireflies) {
        CGFloat dist = hypot([firefly[@"x"] doubleValue] - location.x, [firefly[@"y"] doubleValue] - location.y);
        if (dist <= [self catchRadius]) {
            NSInteger type = [firefly[@"type"] integerValue];
            // Rare golden firefly (type 3) can be caught with any Gold light (type 0)
            NSInteger effectiveType = (type == 3) ? 0 : type;
            if (effectiveType == self.lanternLightType) {
                [caughtFireflies addObject:firefly];
            } else if (!wrongFirefly) {
                wrongFirefly = firefly;
            }
        }
    }

    if (caughtFireflies.count > 0) {
        NSInteger catchType = self.lanternLightType;
        BOOL hasRare = NO;

        for (NSDictionary *firefly in caughtFireflies) {
            CGPoint point = CGPointMake([firefly[@"x"] doubleValue], [firefly[@"y"] doubleValue]);
            [self showCatchFeedbackAtPoint:point color:[self colorForType:catchType] success:YES];
            if ([firefly[@"isRare"] boolValue]) {
                hasRare = YES;
            }
        }

        [self.fireflies removeObjectsInArray:caughtFireflies];
        self.captured += caughtFireflies.count;

        // Combo system
        if (self.lastCatchType == catchType) {
            self.comboCount += caughtFireflies.count;
        } else {
            self.comboCount = caughtFireflies.count;
        }
        self.lastCatchType = catchType;
        self.comboExpireTime = CACurrentMediaTime() + 2.5; // Combo window

        // Score calculation
        NSInteger basePoints = caughtFireflies.count * 10;
        NSInteger comboBonus = MAX(0, self.comboCount - 1) * 5;
        NSInteger rareBonus = hasRare ? 50 : 0;
        NSInteger totalPoints = basePoints + comboBonus + rareBonus;
        self.levelScore += totalPoints;
        self.totalScore += totalPoints;
        [self updateScore:self.totalScore];

        // Sound triggers
        [self triggerSoundEvent:SSSoundEventCatchSuccess];
        if (self.comboCount >= 3) {
            [self triggerSoundEvent:SSSoundEventCombo];
        }
        if (hasRare) {
            [self triggerSoundEvent:SSSoundEventRareCatch];
        }

        // Feedback
        NSMutableString *feedback = [NSMutableString stringWithFormat:@"%@ light matched", [self lightNameForType:catchType]];
        if (self.comboCount >= 3) {
            [feedback appendFormat:@"  Combo x%ld!", (long)self.comboCount];
        }
        if (hasRare) {
            [feedback appendString:@"  Rare catch!"];
        }
        [self setFeedback:feedback duration:1.0];

        // Check level complete
        if (self.captured >= self.targetCapture) {
            [self finishAreaCleared];
            return;
        }
        [self redraw];
    } else if (wrongFirefly) {
        NSInteger neededType = [wrongFirefly[@"type"] integerValue];
        // Rare golden shows as Gold hint
        if (neededType == 3) neededType = 0;
        CGPoint point = CGPointMake([wrongFirefly[@"x"] doubleValue], [wrongFirefly[@"y"] doubleValue]);
        [self showCatchFeedbackAtPoint:point color:[self colorForType:neededType] success:NO];
        [self setFeedback:[NSString stringWithFormat:@"Switch to %@ light", [self lightNameForType:neededType]] duration:1.1];
        [self triggerSoundEvent:SSSoundEventCatchWrong];
        // Reset combo on wrong attempt
        self.comboCount = 0;
        self.lastCatchType = -1;
        [self redraw];
    }
}

- (void)movePlayerToward:(CGPoint)location {
    CGPoint clamped = CGPointMake(MAX(CGRectGetMinX(self.playRect) + 12,
                                       MIN(CGRectGetMaxX(self.playRect) - 12, location.x)),
                                   MAX(CGRectGetMinY(self.playRect) + 12,
                                       MIN(CGRectGetMaxY(self.playRect) - 12, location.y)));
    self.playerTargetPosition = clamped;
    self.isMovingPlayer = YES;
}

#pragma mark - Redraw

- (void)redraw {
    [self.forestNode removeAllChildren];

    // Header
    self.headerLabel.text = [NSString stringWithFormat:@"Area %ld", (long)self.currentLevel];

    // Status
    if (!self.levelEnded) {
        if (self.feedbackMessage.length > 0 && CACurrentMediaTime() < self.feedbackUntilTime) {
            self.statusLabel.text = self.feedbackMessage;
        } else {
            self.statusLabel.text = [NSString stringWithFormat:@"Match light color, then drag through  %ld / %ld", (long)self.captured, (long)self.targetCapture];
            self.statusLabel.fontColor = [UIColor whiteColor];
        }
    }

    // Combo label
    if (self.comboCount >= 3) {
        self.comboLabel.text = [NSString stringWithFormat:@"COMBO x%ld!", (long)self.comboCount];
        self.comboLabel.hidden = NO;
        CGFloat pulseScale = 1.0 + (self.comboCount >= 5 ? 0.15 : 0.08);
        SKAction *pulse = [SKAction sequence:@[[SKAction scaleTo:pulseScale duration:0.15],
                                                [SKAction scaleTo:1.0 duration:0.15]]];
        if (![self.comboLabel hasActions]) {
            [self.comboLabel runAction:pulse];
        }
    } else {
        self.comboLabel.hidden = YES;
    }

    // Progress bar
    CGFloat progress = self.targetCapture > 0 ? (CGFloat)self.captured / (CGFloat)self.targetCapture : 0.0;
    progress = MIN(1.0, progress);
    CGFloat barHeight = 6.0;
    CGFloat fillWidth = self.progressBarMaxWidth * progress;
    self.progressBarFill.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, -barHeight / 2.0, fillWidth, barHeight) cornerRadius:barHeight / 2.0].CGPath;
    // Color shift from green to gold as progress increases
    if (progress < 0.5) {
        self.progressBarFill.fillColor = [UIColor colorWithRed:0.5 green:0.9 blue:0.5 alpha:0.9];
    } else if (progress < 0.8) {
        self.progressBarFill.fillColor = [UIColor colorWithRed:0.9 green:0.85 blue:0.4 alpha:0.9];
    } else {
        self.progressBarFill.fillColor = [UIColor colorWithRed:1.0 green:0.7 blue:0.3 alpha:0.9];
    }

    // Play area frame
    SKShapeNode *frame = [SKShapeNode shapeNodeWithRect:self.playRect cornerRadius:18.0];
    frame.fillColor = [UIColor clearColor];
    frame.strokeColor = [UIColor colorWithRed:0.74 green:0.95 blue:0.67 alpha:0.46];
    frame.lineWidth = 2.0;
    frame.zPosition = -0.5;
    [self.forestNode addChild:frame];

    SKShapeNode *innerFrame = [SKShapeNode shapeNodeWithRect:CGRectInset(self.playRect, 10.0, 10.0) cornerRadius:16.0];
    innerFrame.fillColor = [UIColor clearColor];
    innerFrame.strokeColor = [UIColor colorWithRed:0.72 green:0.95 blue:0.76 alpha:0.20];
    innerFrame.lineWidth = 1.0;
    innerFrame.zPosition = -0.45;
    [self.forestNode addChild:innerFrame];

    // Fireflies
    CGFloat time = CACurrentMediaTime();
    for (NSDictionary *firefly in self.fireflies) {
        NSInteger type = [firefly[@"type"] integerValue];
        UIColor *lightColor = [self colorForType:type];
        CGFloat x = [firefly[@"x"] doubleValue];
        CGFloat y = [firefly[@"y"] doubleValue];
        CGFloat floatOffset = [firefly[@"floatOffset"] doubleValue];
        CGFloat bobY = sin(floatOffset) * 4.0; // Gentle bobbing

        SKSpriteNode *light = [self ss_spriteNamed:[self fireflyImageNameForType:type]
                                     fallbackColor:lightColor
                                              size:CGSizeMake(30.0, 30.0)];
        light.colorBlendFactor = 0.0;
        light.position = CGPointMake(x, y + bobY);
        light.name = @"firefly";
        light.zPosition = 2.0;

        // Rare fireflies get a subtle motion cue without drawing a background plate.
        if ([firefly[@"isRare"] boolValue]) {
            if (![light hasActions]) {
                SKAction *rotate = [SKAction rotateByAngle:M_PI duration:3.0];
                [light runAction:[SKAction repeatActionForever:rotate]];
            }
        }

        [self.forestNode addChild:light];
    }

    // Player
    [self updateLanternGlowColor];
    [self.forestNode addChild:self.player];
    [self drawCatchRing];

    // Lantern control
    CGFloat controlWidth = MIN(self.size.width - 28.0, 360.0);
    CGFloat controlHeight = 74.0;
    CGPoint controlCenter = CGPointMake(self.size.width / 2.0, self.controlBarY);
    SKShapeNode *controlPanel = [SKShapeNode shapeNodeWithRectOfSize:CGSizeMake(controlWidth, controlHeight) cornerRadius:14.0];
    controlPanel.position = controlCenter;
    controlPanel.fillColor = [UIColor colorWithRed:0.02 green:0.12 blue:0.10 alpha:0.92];
    controlPanel.strokeColor = [[self colorForType:self.lanternLightType] colorWithAlphaComponent:0.95];
    controlPanel.lineWidth = 2.6;
    controlPanel.name = @"lantern";
    controlPanel.zPosition = 3.0;
    [self.forestNode addChild:controlPanel];

    SKSpriteNode *lanternIcon = [self ss_spriteNamed:@"ff_player_lantern"
                                      fallbackColor:[UIColor colorWithRed:0.88 green:0.72 blue:0.30 alpha:1.0]
                                               size:CGSizeMake(42.0, 42.0)];
    lanternIcon.position = CGPointMake(controlCenter.x - controlWidth / 2.0 + 38.0, controlCenter.y + 2.0);
    lanternIcon.name = @"lantern";
    lanternIcon.zPosition = 4.0;
    [self.forestNode addChild:lanternIcon];

    SKLabelNode *modeLabel = [SKLabelNode labelNodeWithFontNamed:@"Helvetica-Bold"];
    modeLabel.text = [NSString stringWithFormat:@"Capture: %@", [self lightNameForType:self.lanternLightType]];
    modeLabel.fontSize = 14.0;
    modeLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    modeLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    modeLabel.position = CGPointMake(controlCenter.x - controlWidth / 2.0 + 72.0, controlCenter.y + 18.0);
    modeLabel.fontColor = [self colorForType:self.lanternLightType];
    modeLabel.name = @"lantern";
    modeLabel.zPosition = 4.0;
    [self.forestNode addChild:modeLabel];

    SKLabelNode *guideLabel = [SKLabelNode labelNodeWithFontNamed:@"Helvetica"];
    guideLabel.text = @"Tap color, then drag lantern";
    guideLabel.fontSize = 10.0;
    guideLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    guideLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    guideLabel.fontColor = [UIColor colorWithRed:0.88 green:0.98 blue:0.95 alpha:0.88];
    guideLabel.position = CGPointMake(modeLabel.position.x, controlCenter.y - 18.0);
    guideLabel.name = @"lantern";
    guideLabel.zPosition = 4.0;
    [self.forestNode addChild:guideLabel];

    CGFloat chipStartX = controlCenter.x + controlWidth / 2.0 - 132.0;
    NSArray<NSString *> *chipLabels = @[@"Gold", @"Green", @"Blue"];
    for (NSInteger type = 0; type < [self activeLightColorCount]; type++) {
        BOOL selected = type == self.lanternLightType;
        UIColor *chipColor = [self colorForType:type];
        SKShapeNode *chip = [SKShapeNode shapeNodeWithCircleOfRadius:selected ? 17.0 : 14.0];
        chip.position = CGPointMake(chipStartX + type * 42.0, controlCenter.y);
        chip.fillColor = selected ? chipColor : [chipColor colorWithAlphaComponent:0.72];
        chip.strokeColor = selected ? [UIColor whiteColor] : [[UIColor whiteColor] colorWithAlphaComponent:0.45];
        chip.lineWidth = selected ? 3.0 : 1.4;
        chip.name = [NSString stringWithFormat:@"light_%ld", (long)type];
        chip.zPosition = 4.0;
        [self.forestNode addChild:chip];

        SKLabelNode *chipLabel = [SKLabelNode labelNodeWithFontNamed:@"Helvetica-Bold"];
        chipLabel.text = chipLabels[type];
        chipLabel.fontSize = 8.2;
        chipLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
        chipLabel.fontColor = selected ? [UIColor whiteColor] : [UIColor colorWithRed:0.84 green:0.94 blue:0.88 alpha:0.82];
        chipLabel.position = CGPointMake(chip.position.x, chip.position.y - 25.0);
        chipLabel.name = chip.name;
        chipLabel.zPosition = 5.0;
        [self.forestNode addChild:chipLabel];
    }
}

- (void)drawCatchRing {
    CGFloat radius = [self catchRadius];
    SKShapeNode *ring = [SKShapeNode shapeNodeWithCircleOfRadius:radius];
    ring.position = self.player.position;
    UIColor *lightColor = [self colorForType:self.lanternLightType];
    ring.strokeColor = [lightColor colorWithAlphaComponent:0.95];
    ring.fillColor = [lightColor colorWithAlphaComponent:0.10];
    ring.lineWidth = 3.0;
    ring.zPosition = self.player.zPosition - 0.1;
    [self.forestNode addChild:ring];
}

#pragma mark - Touch Handling

- (void)handlePlayTouchAtPoint:(CGPoint)location {
    if (!CGRectContainsPoint(self.playRect, location)) return;
    [self movePlayerToward:location];
    [self tryCatchAtPoint:self.player.position];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];

    if (self.resultOverlay) {
        for (SKNode *node in [self nodesAtPoint:location]) {
            if ([node.name isEqualToString:@"result_next"]) {
                [self advanceAfterLevelEnd];
                return;
            }
            if ([node.name isEqualToString:@"result_retry"]) {
                [self restartGame];
                return;
            }
            if ([node.name isEqualToString:@"result_areas"]) {
                [self returnToLevelSelect];
                return;
            }
        }
        return;
    }

    if (self.levelEnded) {
        if (self.levelCleared) {
            [self advanceAfterLevelEnd];
        } else {
            [self restartGame];
        }
        return;
    }

    [super touchesBegan:touches withEvent:event];

    for (SKNode *node in [self nodesAtPoint:location]) {
        if ([node.name hasPrefix:@"light_"]) {
            NSInteger selectedType = [[node.name substringFromIndex:6] integerValue];
            if (selectedType < [self activeLightColorCount]) {
                self.lanternLightType = selectedType;
                [self setFeedback:[NSString stringWithFormat:@"%@ light selected", [self lightNameForType:self.lanternLightType]] duration:0.8];
                [self triggerSoundEvent:SSSoundEventLanternSwitch];
                [self redraw];
                return;
            }
        }
        if ([node.name isEqualToString:@"lantern"]) {
            self.lanternLightType = (self.lanternLightType + 1) % [self activeLightColorCount];
            [self setFeedback:[NSString stringWithFormat:@"%@ light selected", [self lightNameForType:self.lanternLightType]] duration:0.8];
            [self triggerSoundEvent:SSSoundEventLanternSwitch];
            [self redraw];
            return;
        }
    }
    [self handlePlayTouchAtPoint:location];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    if (self.levelEnded) return;
    CGPoint location = [[touches anyObject] locationInNode:self];
    [self handlePlayTouchAtPoint:location];
}

@end
