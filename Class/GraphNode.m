//
//  GraphNode.m
//  danmaku
//
//  Created by aaron qian on 4/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GraphNode.h"
#import "GraphEdge.h"

@interface GraphEdge()
- (void)setFromNode:(GraphNode *)from toNode:(GraphNode*)to;
@end

@interface GraphNode()
@property (nonatomic, readwrite, strong) NSMutableSet *edgesIn;
@property (nonatomic, readwrite, strong) NSMutableSet *edgesOut;
@property (nonatomic, readwrite, copy) NSString* key;
@property (nonatomic, readwrite, strong) id value;
- (GraphEdge*)linkToNode:(GraphNode*)node;
- (GraphEdge*)linkToNode:(GraphNode*)node usingEdgeObject:(GraphEdge*)edge;
- (GraphEdge*)linkToNode:(GraphNode*)node weight:(float)weight;
- (void)unlinkToNode:(GraphNode*)node;
@end

@implementation GraphNode

- (id)init {
    if( (self=[super init]) ) {
		self.key = nil;
		self.edgesIn  = [NSMutableSet set];
        self.edgesOut = [NSMutableSet set];
	}
    return self; 
}

- (id)initWithKey:(NSString*)key {
    if( (self=[super init]) ) {
		self.key = key;
        self.edgesIn  = [NSMutableSet set];
        self.edgesOut = [NSMutableSet set];
	}
    return self; 
}


- (id)initWithCoder:(NSCoder *)coder {
	if ( (self=[super init]) ) {
		self.key = [coder decodeObjectForKey:@"key"];
		self.value = [coder decodeObjectForKey:@"value"];
        self.edgesIn  = [NSMutableSet set];
        self.edgesOut = [NSMutableSet set];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:self.key forKey:@"key"];
	[coder encodeObject:self.value forKey:@"value"];
}


- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isSubclassOfClass:[GraphNode class]])
        return NO;
    return [self isEqualToGraphNode:other];
}

- (BOOL)isEqualToGraphNode:(GraphNode*)other {
    if (self == other)
        return YES;
    return [[self key] isEqualToString: [other key]];
}

- (NSUInteger)hash
{
    return [self.key hash];
}

-(GraphNode*) copyWithZone: (NSZone*) zone {
	assert(false && "likely broken -- edges not copied");
    return [[GraphNode allocWithZone: zone] initWithKey:self.key];
}

- (GraphEdge*)linkToNode:(GraphNode*)node {
    GraphEdge* edge = [GraphEdge edgeWithFromNode:self toNode:node];
    [self.edgesOut          addObject:edge];
    [node.edgesIn     addObject:edge];
    return edge;
}

- (GraphEdge*)linkToNode:(GraphNode *)node usingEdgeObject:(GraphEdge *)edge {
	[edge setFromNode:self toNode:node];
	[self.edgesOut addObject:edge];
	[node.edgesIn addObject:edge];
	return edge;
}

- (GraphEdge*)linkToNode:(GraphNode*)node weight:(float)weight {
    GraphEdge* edge = [GraphEdge edgeWithFromNode:self toNode:node weight:weight];
    [self.edgesOut          addObject:edge];
    [node.edgesIn     addObject:edge];
    return edge;
}

- (void)unlinkToNode:(GraphNode*)node {
    GraphEdge* edge = [self edgeConnectedTo: node];
    GraphNode* from = [edge   fromNode];
    GraphNode* to   = [edge   toNode];
    [from.edgesOut removeObject:edge];
    [to.edgesIn    removeObject:edge];
}

- (NSUInteger)inDegree {
    return [[self edgesIn] count];
}

- (NSUInteger)outDegree {
    return [[self edgesOut] count];    
}

- (BOOL)isSource {
    return [self inDegree] == 0;
}

- (BOOL)isSink {
    return [self outDegree] == 0;
}

- (NSSet*)outNodes {
    NSMutableSet* set = [NSMutableSet setWithCapacity:[self.edgesOut count]];
    for( GraphEdge* edge in [self.edgesOut objectEnumerator] ) {
        [set addObject: [edge toNode]];
    }
    return set;
}

- (GraphNode*)inNode
{
	NSAssert(self.edgesIn.count < 2, @"Failure: graph is not a tree");
	if ( self.edgesIn.count==0 ) {
		return nil;
	} else {
		return [(GraphEdge*)[self.edgesIn anyObject] fromNode];
	}
}

- (NSSet*)inNodes
{
    NSMutableSet* set = [NSMutableSet setWithCapacity:[self.edgesIn count]];
    for( GraphEdge* edge in [self.edgesIn objectEnumerator] ) {
        [set addObject: [edge fromNode]];
    }
    return set;    
}

- (GraphEdge*)edgeConnectedTo:(GraphNode*)toNode
{
    for(GraphEdge* edge in [ self.edgesOut objectEnumerator]) {
        if( [edge toNode] == toNode )
            return edge;
    }
    return nil;
}

- (GraphEdge*)edgeConnectedFrom:(GraphNode*)fromNode {
    for(GraphEdge* edge in [ self.edgesIn objectEnumerator]) {
        if( [edge fromNode] == fromNode )
            return edge;
    }
    return nil;    
}

+ (id)node {
    return [[GraphNode alloc] init];
}

+ (id)nodeWithKey:(NSString*)key {
    return [[GraphNode alloc] initWithKey:key];
}

- (NSString*)description {
	return [NSString stringWithFormat:@"GraphNode:%@", [self key]];
}

@end
