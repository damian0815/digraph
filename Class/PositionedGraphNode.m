//
//  PositionedGraphNode.m
//  drawify
//
//  Created by Damian Stewart on 12.08.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PositionedGraphNode.h"

@implementation PositionedGraphNode

- (id)initWithCoder:(NSCoder *)aDecoder {
	if ( ( self=[super initWithCoder:aDecoder] ) ) {
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[super encodeWithCoder:aCoder];
}

- (void)setCentrePos:(CGPoint)centrePos {
	self.pos = CGPointMake( centrePos.x - self.size.width/2, centrePos.y - self.size.height/2 );
}

- (CGPoint)centrePos {
	return CGPointMake( self.pos.x + self.size.width/2, self.pos.y + self.size.height/2 );
}

+ (id)node {
	return [[PositionedGraphNode alloc] init];
}

+ (id)nodeWithKey:(NSString*)key {
	return [[PositionedGraphNode alloc] initWithKey:key];
}

@end
