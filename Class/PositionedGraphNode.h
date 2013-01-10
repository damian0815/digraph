//
//  PositionedGraphNode.h
//  drawify
//
//  Created by Damian Stewart on 12.08.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GraphNode.h"
#import <Foundation/Foundation.h>

@interface PositionedGraphNode : GraphNode<NSCoding>

@property (assign) CGPoint pos;
@property (assign) CGSize size;


@property (assign) int index;

- (CGPoint)centrePos;
- (void)setCentrePos:(CGPoint)centrePos;


@end
