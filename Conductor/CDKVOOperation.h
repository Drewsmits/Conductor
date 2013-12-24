//
//  CDThreadOperation.h
//  Conductor
//
//  Created by Andrew Smith on 3/29/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import "CDOperation.h"

typedef enum {
    CDOperationStateReady,
    CDOperationStateExecuting,
    CDOperationStateFinished,
} CDOperationState;

@interface CDKVOOperation : CDOperation

@end
