//
//  AppDelegate.h
//  ConductorApp
//
//  Created by Andrew Smith on 12/12/12.
//  Copyright (c) 2012 Andrew B. Smith. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Conductor/Conductor.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, strong) CDQueueController *mainQueueController;

@end
