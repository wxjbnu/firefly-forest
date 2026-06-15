//
//  GameScene.h
//  Firefly Forest
//
//  Created on 2024.
//

#import <SpriteKit/SpriteKit.h>

@protocol GameSceneDelegate <NSObject>
@optional
- (void)gameSceneDidRequestReturnToMainMenu;
@end

@interface GameScene : SKScene

@property (nonatomic, weak) id<GameSceneDelegate> gameDelegate;
@property (nonatomic, assign) NSInteger currentLevel;
@property (nonatomic, assign) NSInteger score;
@property (nonatomic, assign) NSTimeInterval gameTime;
@property (nonatomic, assign) BOOL hasCountdown;

// UI Elements
@property (nonatomic, strong) SKLabelNode *scoreLabel;
@property (nonatomic, strong) SKLabelNode *timerLabel;
@property (nonatomic, strong) SKSpriteNode *backgroundSprite;

// Methods for customization
- (void)setupBackground;
- (void)setupGameElements;
- (void)setBackgroundTexture:(SKTexture *)texture;
- (void)setBackgroundImageNamed:(NSString *)imageName;
- (void)updateScore:(NSInteger)newScore;
- (void)startCountdownFrom:(NSTimeInterval)seconds;
- (void)gameOver;

@end
