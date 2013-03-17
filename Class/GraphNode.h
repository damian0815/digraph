//
//  GraphNode.h
//  danmaku
//
//  Created by aaron qian on 4/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GraphEdge;

@interface GraphNode : NSObject<NSCopying, NSCoding> 

@property (nonatomic, readonly, strong) NSMutableSet *edgesIn;
@property (nonatomic, readonly, strong) NSMutableSet *edgesOut;
@property (nonatomic, readonly, copy) NSString* key;
@property (nonatomic, readonly, strong) id value;

- (id)init;
- (id)initWithKey:(NSString*)key;
- (BOOL)isEqualToGraphNode:(GraphNode*)otherNode;

- (NSUInteger)inDegree;
- (NSUInteger)outDegree;
- (BOOL)isSource;
- (BOOL)isSink;
- (NSSet*)outNodes;
- (NSSet*)inNodes;
- (GraphEdge*)edgeConnectedTo:(GraphNode*)toNode;
- (GraphEdge*)edgeConnectedFrom:(GraphNode*)fromNode;

+ (id)node;
+ (id)nodeWithKey:(NSString*)key;
@end
