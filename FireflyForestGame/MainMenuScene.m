//
//  MainMenuScene.m
//  Firefly Forest
//

#import "MainMenuScene.h"
#import "LevelSelectScene.h"
#import "SettingsScene.h"
#import "SSFireflyForestScene.h"

static const NSString *BackgroundNodeName = @"mainMenuBackground";
static const NSString *PlayButtonName = @"playButton";
static const NSString *LevelButtonName = @"levelButton";
static const NSString *SettingButtonName = @"settingButton";
static const NSString *TitleLabelName = @"titleLabel";

@interface MainMenuScene ()
@property (nonatomic, strong) SKSpriteNode *backgroundNode;
@property (nonatomic, strong) SKLabelNode *titleLabel;
@property (nonatomic, strong) SKLabelNode *subtitleLabel;
@property (nonatomic, strong) SKNode *playButton;
@property (nonatomic, strong) SKNode *levelButton;
@property (nonatomic, strong) SKNode *settingButton;
@end

@implementation MainMenuScene

+ (instancetype)sceneWithSize:(CGSize)size {
    return [[self alloc] initWithSize:size];
}

- (void)didMoveToView:(SKView *)view {
    [super didMoveToView:view];
    [self setupBackground];
    [self setupTitle];
    [self setupMenuButtons];
}

- (void)setupBackground {
    [_backgroundNode removeFromParent];
    _backgroundNode = [SKSpriteNode spriteNodeWithColor:[UIColor colorWithRed:0.05 green:0.07 blue:0.14 alpha:1.0] size:self.size];
    _backgroundNode.anchorPoint = CGPointMake(0.5, 0.5);
    _backgroundNode.position = CGPointMake(self.size.width/2, self.size.height/2);
    _backgroundNode.name = BackgroundNodeName;
    _backgroundNode.zPosition = -1;
    UIImage *bgImage = [UIImage imageNamed:@"forest_bg"];
    if (bgImage) {
        _backgroundNode.texture = [SKTexture textureWithImage:bgImage];
        _backgroundNode.colorBlendFactor = 0.0;
    }
    [self addChild:_backgroundNode];
    
    NSArray<NSString *> *glows = @[@"ff_firefly_gold", @"ff_firefly_green", @"ff_firefly_blue"];
    for (int i = 0; i < 16; i++) {
        NSString *imageName = glows[i % glows.count];
        SKSpriteNode *bug = [SKSpriteNode spriteNodeWithImageNamed:imageName];
        bug.size = CGSizeMake(24.0 + (i % 3) * 5.0, 24.0 + (i % 3) * 5.0);
        bug.position = CGPointMake(arc4random_uniform((uint32_t)self.size.width), arc4random_uniform((uint32_t)self.size.height));
        bug.alpha = 0.45;
        bug.zPosition = 1;
        [self addChild:bug];
    }
}

- (void)setupTitle {
    _titleLabel = [SKLabelNode labelNodeWithFontNamed:@"Helvetica-Bold"];
    _titleLabel.text = @"Firefly Forest";
    _titleLabel.fontSize = 48;
    _titleLabel.fontColor = [UIColor colorWithRed:0.98 green:0.86 blue:0.50 alpha:1.0];
    _titleLabel.position = CGPointMake(self.size.width/2, self.size.height*0.78);
    _titleLabel.name = TitleLabelName;
    _titleLabel.zPosition = 10;
    [self addChild:_titleLabel];
    
    _subtitleLabel = [SKLabelNode labelNodeWithFontNamed:@"Helvetica"];
    _subtitleLabel.text = @"Lanterns under moonlit leaves";
    _subtitleLabel.fontSize = 20;
    _subtitleLabel.fontColor = [UIColor colorWithRed:0.82 green:0.88 blue:1.0 alpha:1.0];
    _subtitleLabel.position = CGPointMake(self.size.width/2, self.size.height*0.72);
    _subtitleLabel.zPosition = 10;
    [self addChild:_subtitleLabel];
    
    SKAction *pulse = [SKAction repeatActionForever:[SKAction sequence:@[
        [SKAction scaleTo:1.05 duration:1.5],
        [SKAction scaleTo:1.0 duration:1.5]
    ]]];
    [_titleLabel runAction:pulse];
}

- (void)setupMenuButtons {
    CGFloat bw = 250, bh = 60, bs = 20;
    CGFloat startY = self.size.height * 0.48;
    
    _playButton = [self createBtn:@"Enter Forest" color:[UIColor colorWithRed:0.22 green:0.42 blue:0.30 alpha:1.0] size:CGSizeMake(bw,bh)];
    _playButton.position = CGPointMake(self.size.width/2, startY);
    _playButton.name = PlayButtonName;
    [self addChild:_playButton];
    
    _levelButton = [self createBtn:@"Areas" color:[UIColor colorWithRed:0.34 green:0.46 blue:0.52 alpha:1.0] size:CGSizeMake(bw,bh)];
    _levelButton.position = CGPointMake(self.size.width/2, startY-bh-bs);
    _levelButton.name = LevelButtonName;
    [self addChild:_levelButton];
    
    _settingButton = [self createBtn:@"Settings" color:[UIColor colorWithRed:0.36 green:0.30 blue:0.40 alpha:1.0] size:CGSizeMake(bw,bh)];
    _settingButton.position = CGPointMake(self.size.width/2, startY-(bh+bs)*2);
    _settingButton.name = SettingButtonName;
    [self addChild:_settingButton];
}

- (SKShapeNode *)createBtn:(NSString *)text color:(UIColor *)color size:(CGSize)size {
    SKShapeNode *btn = [SKShapeNode shapeNodeWithRectOfSize:size cornerRadius:14.0];
    btn.fillColor = [UIColor colorWithRed:0.03 green:0.16 blue:0.13 alpha:0.92];
    btn.strokeColor = [UIColor colorWithRed:0.94 green:0.78 blue:0.34 alpha:0.96];
    btn.lineWidth = 2.6;
    btn.zPosition = 10;
    
    SKLabelNode *lbl = [SKLabelNode labelNodeWithFontNamed:@"Helvetica-Bold"];
    lbl.text = text; lbl.fontSize = 22; lbl.fontColor = [UIColor whiteColor];
    lbl.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    lbl.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
    lbl.zPosition = 2;
    [btn addChild:lbl];
    
    return btn;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    SKNode *node = [self nodeAtPoint:location];
    
    while (node) {
        if ([node.name isEqualToString:PlayButtonName]) {
            SSFireflyForestScene *gameScene = [SSFireflyForestScene sceneWithSize:self.size];
            gameScene.scaleMode = SKSceneScaleModeAspectFill;
            gameScene.currentLevel = 1;
            [self.view presentScene:gameScene transition:[SKTransition fadeWithDuration:0.4]];
            return;
        }
        if ([node.name isEqualToString:LevelButtonName]) {
            LevelSelectScene *levelScene = [LevelSelectScene sceneWithSize:self.size];
            levelScene.scaleMode = SKSceneScaleModeAspectFill;
            [self.view presentScene:levelScene transition:[SKTransition fadeWithDuration:0.3]];
            return;
        }
        if ([node.name isEqualToString:SettingButtonName]) {
            SettingsScene *settingsScene = [SettingsScene sceneWithSize:self.size];
            settingsScene.scaleMode = SKSceneScaleModeAspectFill;
            [self.view presentScene:settingsScene transition:[SKTransition fadeWithDuration:0.3]];
            return;
        }
        node = node.parent;
    }
}

@end
