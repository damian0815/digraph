//
//  GraphEdge.m
//  danmaku
//
//  Created by aaron qian on 4/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GraphEdge.h"
#import "GraphNode.h"

#define NSUINT_BIT (CHAR_BIT * sizeof(NSUInteger))
#define NSUINTROTATE(val, howmuch) ((((NSUInteger)val) << howmuch) | (((NSUInteger)val) >> (NSUINT_BIT - howmuch)))

@interface GraphEdge()
@property (nonatomic, readwrite, retain)  GraphNode *fromNode;
@property (nonatomic, readwrite, retain)  GraphNode *toNode;

- (void)setFromNode:(GraphNode *)from toNode:(GraphNode*)to;

@end

@implementation GraphEdge

@synthesize fromNode = fromNode_;
@synthesize toNode = toNode_;
@synthesize weight = weight_;
@synthesize reverted = reverted_;

- (id)initWithCoder:(NSCoder*)coder
{
	self = [super init];
	if ( self ) {
		self.fromNode = [GraphNode nodeWithKey:[coder decodeObjectForKey:@"fromNodeKey"]];
		self.toNode = [GraphNode nodeWithKey:[coder decodeObjectForKey:@"toNodeKey"]];
		self.weight = [coder decodeFloatForKey:@"weight"];
		self.reverted =  [coder decodeBoolForKey:@"reverted"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:[self.fromNode key] forKey:@"fromNodeKey"];
	[coder encodeObject:[self.toNode key] forKey:@"toNodeKey"];
	[coder encodeFloat:self.weight forKey:@"weight"];
	[coder encodeBool:self.reverted forKey:@"reverted"];
}

- (id)init {
    if( (self = [super init]) ) {
        self.fromNode = nil;
        self.toNode = nil;
        self.weight = 0;
    }
    
    return self;
}

- (id)initWithFromNode:(GraphNode*)fromNode toNode:(GraphNode*)toNode {
    if( (self = [super init]) ) {
        self.fromNode = fromNode;
        self.toNode = toNode;
        self.weight = 0;
    }
    
    return self;
}

- (id)initWithFromNode:(GraphNode*)fromNode toNode:(GraphNode*)toNode weight:(float)weight {
    if( (self = [super init]) ) {
        self.fromNode = fromNode;
        self.toNode = toNode;
        self.weight = weight;
    }
    
    return self;
}

- (void)setFromNode:(GraphNode *)from toNode:(GraphNode*)to
{
	self.fromNode = from;
	self.toNode = to;
}

-(void) dealloc
{
	[fromNode_ release];
    [toNode_ release];
	[super dealloc];
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    return [self isEqualToGraphEdge:other];
}

- (BOOL)isEqualToGraphEdge:(GraphEdge*)other {
    if (self == other)
        return YES;
    if (![[self fromNode] isEqualToGraphNode: [other fromNode]])
        return NO;
    if (![[self toNode] isEqualToGraphNode: [other toNode]])
        return NO;

    return YES;
}

- (NSUInteger)hash
{
    return NSUINTROTATE([fromNode_ hash], NSUINT_BIT / 2) ^ [toNode_ hash];
}

+ (id)edge {
    return [[[self alloc] init] autorelease];
}

+ (id)edgeWithFromNode:(GraphNode*)fromNode toNode:(GraphNode*)toNode {
    return [[[self alloc] initWithFromNode:fromNode toNode:toNode] autorelease];  
}

+ (id)edgeWithFromNode:(GraphNode*)fromNode toNode:(GraphNode*)toNode weight:(float)weight {
    return [[[self alloc] initWithFromNode:fromNode toNode:toNode weight:weight] autorelease];  
}

- (NSString*)description
{
	return [NSString stringWithFormat:@"GraphEdge:%@->%@%@", [fromNode_ key], [toNode_ key], reverted_?@"(rev)":@""];
}

@end
