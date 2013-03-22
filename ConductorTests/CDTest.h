//
//  CDTest.h
//  Conductor
//
//  Created by Andrew Smith on 5/3/12.
//  Copyright (c) 2012 Andrew B. Smith. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#import "CDQueueController.h"
#import "CDOperationQueue.h"
#import "CDProgressObserver.h"

#define CONDUCTOR_TEST_QUEUE @"com.conductor.testQueue"

@interface CDTest : SenTestCase {
    CDOperationQueue *testOperationQueue;
    CDQueueController *conductor;
}

@end
