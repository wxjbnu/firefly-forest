//
//  LevelSelectScene.m
//  Firefly Forest
//

#import "LevelSelectScene.h"
#import "MainMenuScene.h"
#import "SSFireflyForestScene.h"

static const NSString *BackgroundNodeName = @"levelSelectBackground";
static const NSString *TitleLabelName = @"titleLabel";
static const NSString *BackButtonName = @"backButton";
static const NSInteger MaxLevels = 50;
static NSString * const FFUnlockedLevelKey = @"FireflyForestUnlockedLevel";

@interface LevelSelectScene ()

@property (nonatomic, strong) SKSpriteNode *backgroundNode;
@property (nonatomic, strong) SKLabelNode *titleLabel;
@property (nonatomic, strong) SKShapeNode *backButton;
@property (nonatomic, strong) SKNode *pageContainer;
@property (nonatomic, strong) SKLabelNode *pageLabel;
@property (nonatomic, strong) SKShapeNode *prevButton;
@property (nonatomic, strong) SKShapeNode *nextButton;
@property (nonatomic, assign) NSInteger unlockedLevel;
@property (nonatomic, assign) NSInteger currentPage;

@end

@implementation LevelSelectScene

+ (instancetype)sceneWithSize:(CGSize)size {
    return [[self alloc] initWithSize:size];
}

- (void)didMoveToView:(SKView *)view {
    [super didMoveToView:view];
    _currentPage = 0;
    _unlockedLevel = [self currentUnlockedLevel];
    [self setupBackground];
    [self setupTitle];
    [self setupBackButton];
    [self setupPageControls];
    [self setupLevelButtons];
}

- (NSInteger)currentUnlockedLevel {
    NSInteger unlocked = [[NSUserDefaults standardUserDefaults] integerForKey:FFUnlockedLevelKey];
    if (unlocked < 1) {
        unlocked = 1;
        [[NSUserDefaults standardUserDefaults] setInteger:unlocked forKey:FFUnlockedLevelKey];
    }
    return MIN(MaxLevels, unlocked);
}

- (NSInteger)levelsPerPage {
    return 16;
}

- (NSInteger)pageCount {
    return (MaxLevels + [self levelsPerPage] - 1) / [self levelsPerPage];
}

#pragma mark - Background

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
}

#pragma mark - Title

- (void)setupTitle {
    UIEdgeInsets safe = self.view.safeAreaInsets;
    CGFloat topPad = MAX(safe.top, 20);
    
    _titleLabel = [SKLabelNode labelNodeWithFontNamed:@"Helvetica-Bold"];
    _titleLabel.text = [NSString stringWithFormat:@"Forest Areas  %ld/%ld", (long)_unlockedLevel, (long)MaxLevels];
    _titleLabel.fontSize = 28;
    _titleLabel.fontColor = [UIColor whiteColor];
    _titleLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
    _titleLabel.position = CGPointMake(self.size.width/2, self.size.height - topPad - 40);
    _titleLabel.name = TitleLabelName;
    _titleLabel.zPosition = 10;
    [self addChild:_titleLabel];
}

#pragma mark - Back Button

- (void)setupBackButton {
    UIEdgeInsets safe = self.view.safeAreaInsets;
    CGFloat topPad = MAX(safe.top, 20);
    CGFloat sidePad = MAX(MAX(safe.left, safe.right), 15);
    
    _backButton = [SKShapeNode shapeNodeWithRectOfSize:CGSizeMake(100, 40) cornerRadius:10.0];
    _backButton.position = CGPointMake(sidePad + 60, self.size.height - topPad - 20);
    _backButton.fillColor = [UIColor colorWithRed:0.03 green:0.16 blue:0.13 alpha:0.90];
    _backButton.strokeColor = [UIColor colorWithRed:0.94 green:0.78 blue:0.34 alpha:0.94];
    _backButton.lineWidth = 1.8;
    _backButton.name = BackButtonName;
    _backButton.zPosition = 100;
    
    SKLabelNode *bl = [SKLabelNode labelNodeWithFontNamed:@"Helvetica-Bold"];
    bl.text = @"< Back"; bl.fontSize = 18; bl.fontColor = [UIColor whiteColor];
    bl.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    bl.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
    bl.zPosition = 2;
    [_backButton addChild:bl];
    [self addChild:_backButton];
}

#pragma mark - Page Controls

- (void)setupPageControls {
    CGFloat bottomY = MAX(self.view.safeAreaInsets.bottom + 44.0, 58.0);

    _prevButton = [self pageButtonWithTitle:@"Prev" name:@"page_prev"];
    _prevButton.position = CGPointMake(self.size.width * 0.24, bottomY);
    [self addChild:_prevButton];

    _nextButton = [self pageButtonWithTitle:@"Next" name:@"page_next"];
    _nextButton.position = CGPointMake(self.size.width * 0.76, bottomY);
    [self addChild:_nextButton];

    _pageLabel = [SKLabelNode labelNodeWithFontNamed:@"Helvetica-Bold"];
    _pageLabel.fontSize = 16.0;
    _pageLabel.fontColor = [UIColor colorWithRed:0.90 green:0.96 blue:0.92 alpha:0.95];
    _pageLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    _pageLabel.position = CGPointMake(self.size.width / 2.0, bottomY);
    _pageLabel.zPosition = 20.0;
    [self addChild:_pageLabel];
    [self updatePageControls];
}

- (SKShapeNode *)pageButtonWithTitle:(NSString *)title name:(NSString *)name {
    SKShapeNode *button = [SKShapeNode shapeNodeWithRectOfSize:CGSizeMake(92.0, 42.0) cornerRadius:10.0];
    button.name = name;
    button.fillColor = [UIColor colorWithRed:0.03 green:0.15 blue:0.13 alpha:0.90];
    button.strokeColor = [UIColor colorWithRed:0.94 green:0.78 blue:0.34 alpha:0.94];
    button.lineWidth = 1.8;
    button.zPosition = 20.0;

    SKLabelNode *label = [SKLabelNode labelNodeWithFontNamed:@"Helvetica-Bold"];
    label.text = title;
    label.fontSize = 15.0;
    label.fontColor = [UIColor whiteColor];
    label.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    label.name = name;
    label.zPosition = 2.0;
    [button addChild:label];
    return button;
}

- (void)updatePageControls {
    NSInteger pageCount = [self pageCount];
    _pageLabel.text = [NSString stringWithFormat:@"%ld / %ld", (long)(_currentPage + 1), (long)pageCount];
    _prevButton.alpha = _currentPage > 0 ? 1.0 : 0.36;
    _nextButton.alpha = _currentPage < pageCount - 1 ? 1.0 : 0.36;
}

#pragma mark - Level Buttons

- (void)setupLevelButtons {
    [_pageContainer removeFromParent];
    _pageContainer = [[SKNode alloc] init];
    _pageContainer.zPosition = 5;
    [self addChild:_pageContainer];
    
    CGFloat btnW = 68, btnH = 68, padX = 16, padY = 16;
    NSInteger cols = 4;
    NSInteger rows = 4;
    CGFloat startX = (self.size.width - (cols * btnW + (cols - 1) * padX)) / 2.0 + btnW / 2.0;
    
    UIEdgeInsets safe = self.view.safeAreaInsets;
    CGFloat topPad = MAX(safe.top, 20);
    CGFloat startY = self.size.height - topPad - 122;
    NSInteger firstLevel = _currentPage * [self levelsPerPage] + 1;
    NSInteger lastLevel = MIN(MaxLevels, firstLevel + [self levelsPerPage] - 1);
    
    for (NSInteger levelNumber = firstLevel; levelNumber <= lastLevel; levelNumber++) {
        NSInteger pageIndex = levelNumber - firstLevel;
        BOOL unlocked = levelNumber <= _unlockedLevel;
        NSInteger row = pageIndex / cols;
        NSInteger col = pageIndex % cols;
        CGFloat x = startX + col * (btnW + padX);
        CGFloat y = startY - row * (btnH + padY);
        
        SKShapeNode *btn = [SKShapeNode shapeNodeWithRectOfSize:CGSizeMake(btnW, btnH) cornerRadius:10.0];
        btn.position = CGPointMake(x, y);
        btn.name = [NSString stringWithFormat:@"%@_%ld", unlocked ? @"level" : @"locked", (long)levelNumber];
        btn.zPosition = 1;
        btn.fillColor = unlocked ? [UIColor colorWithRed:0.03 green:0.16 blue:0.13 alpha:0.92] : [UIColor colorWithRed:0.03 green:0.10 blue:0.10 alpha:0.55];
        btn.strokeColor = unlocked ? [UIColor colorWithRed:0.94 green:0.78 blue:0.34 alpha:0.96] : [UIColor colorWithRed:0.94 green:0.78 blue:0.34 alpha:0.28];
        btn.lineWidth = unlocked ? 2.0 : 1.0;
        
        SKLabelNode *lbl = [SKLabelNode labelNodeWithFontNamed:@"Helvetica-Bold"];
        lbl.text = unlocked ? [NSString stringWithFormat:@"%ld", (long)levelNumber] : @"Lock";
        lbl.fontSize = unlocked ? 18 : 11;
        lbl.fontColor = unlocked ? [UIColor whiteColor] : [UIColor colorWithWhite:0.72 alpha:0.86];
        lbl.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
        lbl.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
        lbl.position = CGPointZero; lbl.zPosition = 2;
        [btn addChild:lbl];
        
        [_pageContainer addChild:btn];
    }
    [self updatePageControls];
}

#pragma mark - Touch

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint rootLocation = [touch locationInNode:self];
    SKNode *rootNode = [self nodeAtPoint:rootLocation];
    while (rootNode) {
        if ([rootNode.name isEqualToString:@"page_prev"]) {
            if (_currentPage > 0) {
                _currentPage -= 1;
                [self setupLevelButtons];
            }
            return;
        }
        if ([rootNode.name isEqualToString:@"page_next"]) {
            if (_currentPage < [self pageCount] - 1) {
                _currentPage += 1;
                [self setupLevelButtons];
            }
            return;
        }
        if ([rootNode.name isEqualToString:BackButtonName]) {
            MainMenuScene *menu = [MainMenuScene sceneWithSize:self.size];
            menu.scaleMode = SKSceneScaleModeAspectFill;
            [self.view presentScene:menu transition:[SKTransition fadeWithDuration:0.3]];
            return;
        }
        rootNode = rootNode.parent;
    }

    CGPoint location = [touch locationInNode:_pageContainer];
    
    for (SKNode *node in _pageContainer.children) {
        if ([node.name hasPrefix:@"locked_"] && CGRectContainsPoint(node.frame, location)) {
            return;
        }
        if ([node.name hasPrefix:@"level_"] && CGRectContainsPoint(node.frame, location)) {
            NSInteger level = [[node.name stringByReplacingOccurrencesOfString:@"level_" withString:@""] integerValue];
            SSFireflyForestScene *gameScene = [SSFireflyForestScene sceneWithSize:self.size];
            gameScene.scaleMode = SKSceneScaleModeAspectFill;
            gameScene.currentLevel = level;
            [self.view presentScene:gameScene transition:[SKTransition fadeWithDuration:0.4]];
            return;
        }
    }
}

@end
