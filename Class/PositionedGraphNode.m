//
//  PositionedGraphNode.m
//  drawify
//
//  Created by Damian Stewart on 12.08.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PositionedGraphNode.h"

@implementation PositionedGraphNode

@synthesize index, pos, size;

- (void)setCentrePos:(CGPoint)centrePos
{
	pos.x = centrePos.x - size.width/2;
	pos.y = centrePos.y - size.height/2;
}

- (CGPoint)centrePos
{
	return CGPointMake( pos.x + size.width/2, pos.y + size.height/2 );
}

+ (id)node {
	return [[[PositionedGraphNode alloc] init] autorelease];
}

+ (id)nodeWithKey:(NSString*)key {
	return [[[PositionedGraphNode alloc] initWithKey:key] autorelease];
}

@end
