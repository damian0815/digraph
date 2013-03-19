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

@property (assign,readwrite,atomic) CGPoint pos;
@property (assign,readwrite,atomic) CGSize size;
@property (assign,readwrite,atomic) int index;

- (CGPoint)centrePos;
- (void)setCentrePos:(CGPoint)centrePos;


@end
