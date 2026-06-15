//
//  ViewController.m
//  Firefly Forest
//
//  Created on 2024.
//

#import "ViewController.h"
#import "MainMenuScene.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)loadView {
    SKView *skView = [[SKView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view = skView;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Configure SKView
    SKView *skView = (SKView *)self.view;
    skView.showsFPS = NO;
    skView.showsNodeCount = NO;

    // Create and configure the main menu scene
    MainMenuScene *mainMenuScene = [MainMenuScene sceneWithSize:skView.bounds.size];
    mainMenuScene.scaleMode = SKSceneScaleModeAspectFill;

    [skView presentScene:mainMenuScene];
}

@end
