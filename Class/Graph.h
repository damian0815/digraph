//
//  Graph.h
//  danmaku
//
//  Created by aaron qian on 4/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GraphEdge.h"
#import "GraphNode.h"

@interface Graph : NSObject {
    NSMutableSet *nodes_;
}

@property (nonatomic, readonly, retain) NSSet *nodes;

- (NSArray*)shortestPath:(GraphNode*)source to:(GraphNode*)target;

- (GraphNode*)addNode:(GraphNode*)node;
- (void)removeNode:(GraphNode*)node;
- (BOOL)hasNodeWithKey:(NSString*)key;
- (GraphNode*)nodeWithKey:(NSString*)key;

- (NSSet*)allNodes;

- (GraphEdge*)addEdgeFromNode:(GraphNode*)fromNode toNode:(GraphNode*)toNode;
- (GraphEdge*)addEdgeFromNodeWithKey:(NSString*)fromKey toNodeWithKey:(NSString*)toKey;
- (GraphEdge*)addEdgeFromNode:(GraphNode*)fromNode toNode:(GraphNode*)toNode withWeight:(float)weight;
- (void)removeEdge:(GraphEdge*)edge;

- (NSSet*)connectedComponentContainingNodeWithKey:(NSString*)key;

+ (Graph*)graph;
+ (NSArray*)topologicalSortWithNodes:(NSSet*)nodes;

@end
