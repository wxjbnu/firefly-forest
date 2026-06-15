//
//  SettingsScene.m
//  Firefly Forest
//
//  Created on 2024.
//

#import "SettingsScene.h"
#import "MainMenuScene.h"

static const NSString *BackgroundNodeName = @"settingsBackground";
static const NSString *TitleLabelName = @"titleLabel";
static const NSString *BackButtonName = @"backButton";
static const NSString *MusicToggleName = @"musicToggle";
static const NSString *SoundToggleName = @"soundToggle";
static const NSString *MusicLabelName = @"musicLabel";
static const NSString *SoundLabelName = @"soundLabel";

static NSString * const MusicEnabledKey = @"MusicEnabled";
static NSString * const SoundEnabledKey = @"SoundEnabled";

@interface SettingsScene ()

@property (nonatomic, strong) SKSpriteNode *backgroundNode;
@property (nonatomic, strong) SKLabelNode *titleLabel;
@property (nonatomic, strong) SKShapeNode *backButton;
@property (nonatomic, strong) SKSpriteNode *musicToggle;
@property (nonatomic, strong) SKSpriteNode *soundToggle;
@property (nonatomic, strong) SKLabelNode *musicLabel;
@property (nonatomic, strong) SKLabelNode *soundLabel;
@property (nonatomic, assign) BOOL musicEnabled;
@property (nonatomic, assign) BOOL soundEnabled;

@end

@implementation SettingsScene

+ (instancetype)sceneWithSize:(CGSize)size {
    return [[self alloc] initWithSize:size];
}

- (void)didMoveToView:(SKView *)view {
    [super didMoveToView:view];
    
    // Load saved settings
    [self loadSettings];
    
    // Setup background
    [self setupBackground];
    
    // Setup title
    [self setupTitle];
    
    // Setup back button
    [self setupBackButton];
    
    // Setup settings options
    [self setupSettingsOptions];
}

#pragma mark - Settings Persistence

- (void)loadSettings {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _musicEnabled = [defaults boolForKey:MusicEnabledKey];
    _soundEnabled = [defaults boolForKey:SoundEnabledKey];
    
    // Default to YES if not set
    if (![defaults objectForKey:MusicEnabledKey]) {
        _musicEnabled = YES;
    }
    if (![defaults objectForKey:SoundEnabledKey]) {
        _soundEnabled = YES;
    }
}

- (void)saveSettings {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:_musicEnabled forKey:MusicEnabledKey];
    [defaults setBool:_soundEnabled forKey:SoundEnabledKey];
    [defaults synchronize];
}

#pragma mark - Background Setup

- (void)setupBackground {
    [_backgroundNode removeFromParent];
    
    _backgroundNode = [SKSpriteNode spriteNodeWithColor:[UIColor clearColor] size:self.size];
    _backgroundNode.anchorPoint = CGPointMake(0.5, 0.5);
    _backgroundNode.position = CGPointMake(self.size.width / 2.0, self.size.height / 2.0);
    _backgroundNode.name = BackgroundNodeName;
    _backgroundNode.zPosition = -1;
    
    UIImage *bgImage = [UIImage imageNamed:@"forest_bg"];
    if (bgImage) {
        SKTexture *texture = [SKTexture textureWithCGImage:bgImage.CGImage];
        _backgroundNode.texture = texture;
        _backgroundNode.color = [UIColor whiteColor];
        _backgroundNode.colorBlendFactor = 0.0;
    } else {
        _backgroundNode.color = [UIColor colorWithRed:0.2 green:0.2 blue:0.3 alpha:1.0];
    }
    
    [self addChild:_backgroundNode];
}

- (void)setBackgroundTexture:(SKTexture *)texture {
    _backgroundNode.texture = texture;
    _backgroundNode.colorBlendFactor = 0.0;
}

- (void)setBackgroundImageNamed:(NSString *)imageName {
    UIImage *image = [UIImage imageNamed:imageName];
    if (image) {
        SKTexture *texture = [SKTexture textureWithCGImage:image.CGImage];
        [self setBackgroundTexture:texture];
    }
}

#pragma mark - Title Setup

- (void)setupTitle {
    UIEdgeInsets safeInsets = self.view.safeAreaInsets;
    CGFloat topPadding = MAX(safeInsets.top, 20.0);
    
    _titleLabel = [SKLabelNode labelNodeWithFontNamed:@"Helvetica-Bold"];
    _titleLabel.text = @"Settings";
    _titleLabel.fontSize = 48;
    _titleLabel.fontColor = [UIColor whiteColor];
    _titleLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
    _titleLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    _titleLabel.position = CGPointMake(self.size.width / 2.0, self.size.height - topPadding - 60);
    _titleLabel.name = TitleLabelName;
    _titleLabel.zPosition = 10;
    // Shadow not available on iOS SKLabelNode
    
    [self addChild:_titleLabel];
}

#pragma mark - Back Button Setup

- (void)setupBackButton {
    UIEdgeInsets safeInsets = self.view.safeAreaInsets;
    CGFloat topPadding = MAX(safeInsets.top, 20.0);
    CGFloat sidePadding = MAX(safeInsets.left, safeInsets.right);
    sidePadding = MAX(sidePadding, 15.0);
    
    CGSize buttonSize = CGSizeMake(100, 40);

    _backButton = [SKShapeNode shapeNodeWithRectOfSize:buttonSize cornerRadius:10.0];
    _backButton.fillColor = [UIColor colorWithRed:0.03 green:0.16 blue:0.13 alpha:0.90];
    _backButton.strokeColor = [UIColor colorWithRed:0.94 green:0.78 blue:0.34 alpha:0.94];
    _backButton.lineWidth = 1.8;
    _backButton.position = CGPointMake(sidePadding + 60, self.size.height - topPadding - 30);
    _backButton.name = BackButtonName;
    _backButton.zPosition = 100;

    SKLabelNode *backLabel = [SKLabelNode labelNodeWithFontNamed:@"Helvetica-Bold"];
    backLabel.text = @"< Back";
    backLabel.fontSize = 18;
    backLabel.fontColor = [UIColor whiteColor];
    backLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
    backLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    backLabel.zPosition = 2;
    [_backButton addChild:backLabel];

    [self addChild:_backButton];
}

- (void)backButtonTapped:(id)sender {
    SKAction *scaleDown = [SKAction scaleTo:0.9 duration:0.1];
    SKAction *scaleUp = [SKAction scaleTo:1.0 duration:0.1];
    SKAction *sequence = [SKAction sequence:@[scaleDown, scaleUp]];
    
    [_backButton runAction:sequence completion:^{
        MainMenuScene *mainMenu = [MainMenuScene sceneWithSize:self.size];
        mainMenu.scaleMode = self.scaleMode;
        SKTransition *transition = [SKTransition fadeWithDuration:0.5];
        [self.view presentScene:mainMenu transition:transition];
    }];
}

#pragma mark - Settings Options Setup

- (void)setupSettingsOptions {
    UIEdgeInsets safeInsets = self.view.safeAreaInsets;
    CGFloat topPadding = MAX(safeInsets.top, 20.0);
    
    // Settings item dimensions
    CGFloat itemWidth = 300;
    CGFloat itemHeight = 70;
    CGFloat spacing = 30;
    
    // Starting Y position
    CGFloat startY = self.size.height * 0.6;
    
    // Music Toggle
    _musicLabel = [SKLabelNode labelNodeWithFontNamed:@"Helvetica-Bold"];
    _musicLabel.text = @"Music";
    _musicLabel.fontSize = 32;
    _musicLabel.fontColor = [UIColor whiteColor];
    _musicLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    _musicLabel.position = CGPointMake((self.size.width - itemWidth) / 2.0, startY);
    _musicLabel.name = MusicLabelName;
    _musicLabel.zPosition = 10;
    [self addChild:_musicLabel];
    
    _musicToggle = [self createToggleButtonWithEnabled:_musicEnabled];
    _musicToggle.position = CGPointMake((self.size.width - itemWidth) / 2.0 + itemWidth - 40, startY);
    _musicToggle.name = MusicToggleName;
    [self addChild:_musicToggle];
    
    // Sound Toggle
    _soundLabel = [SKLabelNode labelNodeWithFontNamed:@"Helvetica-Bold"];
    _soundLabel.text = @"Sound Effects";
    _soundLabel.fontSize = 32;
    _soundLabel.fontColor = [UIColor whiteColor];
    _soundLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    _soundLabel.position = CGPointMake((self.size.width - itemWidth) / 2.0, startY - itemHeight - spacing);
    _soundLabel.name = SoundLabelName;
    _soundLabel.zPosition = 10;
    [self addChild:_soundLabel];
    
    _soundToggle = [self createToggleButtonWithEnabled:_soundEnabled];
    _soundToggle.position = CGPointMake((self.size.width - itemWidth) / 2.0 + itemWidth - 40, startY - itemHeight - spacing);
    _soundToggle.name = SoundToggleName;
    [self addChild:_soundToggle];
}

- (SKSpriteNode *)createToggleButtonWithEnabled:(BOOL)enabled {
    CGSize toggleSize = CGSizeMake(70, 40);

    UIColor *bgColor = enabled ?
        [UIColor colorWithRed:0.10 green:0.50 blue:0.32 alpha:1.0] :
        [UIColor colorWithRed:0.08 green:0.13 blue:0.13 alpha:1.0];

    SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithColor:bgColor size:toggleSize];
    sprite.anchorPoint = CGPointMake(0.5, 0.5);

    // Knob (white circle)
    CGFloat knobSize = toggleSize.height - 8;
    SKSpriteNode *knob = [SKSpriteNode spriteNodeWithColor:[UIColor whiteColor]
                                                      size:CGSizeMake(knobSize, knobSize)];
    knob.position = CGPointMake(enabled ? (toggleSize.width / 2.0 - knobSize / 2.0 - 2) : -(toggleSize.width / 2.0 - knobSize / 2.0 - 2), 0);
    knob.zPosition = 2;
    knob.name = @"toggleKnob";
    [sprite addChild:knob];

    return sprite;
}

- (BOOL)node:(SKNode *)node isInsideToggleNamed:(NSString *)toggleName {
    while (node) {
        if ([node.name isEqualToString:toggleName]) {
            return YES;
        }
        node = node.parent;
    }
    return NO;
}

- (void)updateToggle:(SKSpriteNode *)toggle enabled:(BOOL)enabled {
    toggle.color = enabled ?
        [UIColor colorWithRed:0.10 green:0.50 blue:0.32 alpha:1.0] :
        [UIColor colorWithRed:0.08 green:0.13 blue:0.13 alpha:1.0];

    CGFloat knobSize = toggle.size.height - 8;
    CGFloat knobX = enabled ? (toggle.size.width / 2.0 - knobSize / 2.0 - 2) : -(toggle.size.width / 2.0 - knobSize / 2.0 - 2);

    SKNode *knob = [toggle childNodeWithName:@"toggleKnob"];
    if (knob) {
        SKAction *move = [SKAction moveToX:knobX duration:0.2];
        [knob runAction:move];
    }
}

#pragma mark - Touch Handling

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];

    NSArray<SKNode *> *hitNodes = [self nodesAtPoint:location];
    for (SKNode *n in hitNodes) {
        if ([n.name isEqualToString:BackButtonName]) {
            [self backButtonTapped:nil];
            return;
        }
        if ([self node:n isInsideToggleNamed:MusicToggleName]) {
            [self toggleMusic];
            return;
        }
        if ([self node:n isInsideToggleNamed:SoundToggleName]) {
            [self toggleSound];
            return;
        }
    }
}

#pragma mark - Toggle Actions

- (void)toggleMusic {
    _musicEnabled = !_musicEnabled;
    [self saveSettings];
    [self updateToggle:_musicToggle enabled:_musicEnabled];
    
}

- (void)toggleSound {
    _soundEnabled = !_soundEnabled;
    [self saveSettings];
    [self updateToggle:_soundToggle enabled:_soundEnabled];
    
}

@end
