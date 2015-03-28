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

@interface Graph : NSObject

@property (nonatomic, readonly, strong) NSMutableDictionary *nodes;

- (NSArray*)shortestPath:(GraphNode*)source to:(GraphNode*)target;

- (void)clear;

- (GraphNode*)addNode:(GraphNode*)node;
- (void)removeNode:(GraphNode*)node;
- (BOOL)hasNodeWithKey:(NSString*)key;
- (GraphNode*)nodeWithKey:(NSString*)key;

- (NSArray*)allNodes;
- (NSSet*)allEdges;

- (GraphEdge*)addEdgeFromNode:(GraphNode*)fromNode toNode:(GraphNode*)toNode;
- (GraphEdge*)addEdgeFromNodeWithKey:(NSString*)fromKey toNodeWithKey:(NSString*)toKey;
- (GraphEdge*)addEdgeFromNode:(GraphNode*)fromNode toNode:(GraphNode*)toNode withWeight:(float)weight;
- (void)removeEdge:(GraphEdge*)edge;
- (BOOL)hasEdgeFromNode:(GraphNode*)fromNode toNode:(GraphNode*)toNode;
- (BOOL)hasEdgeFromNodeWithKey:(NSString*)fromKey toNodeWithKey:(NSString*)toKey;

- (void)revertEdge:(GraphEdge*)edge;
- (void)unrevertEdge:(GraphEdge *)edge;

- (NSSet*)connectedComponentContainingNodeWithKey:(NSString*)key;
/// returns an array of NSSets
- (NSArray*)connectedComponents;

+ (Graph*)graph;

+ (NSArray*)topologicalSortWithNodes:(NSSet*)nodes;

- (NSData*)serializeToNSData;
// returns YES on success
- (BOOL)serializeToPath:(NSString*)path;
- (BOOL)deserializeFromPath:(NSString*)path;

@end
