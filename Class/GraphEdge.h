//
//  GraphEdge.h
//  danmaku
//
//  Created by aaron qian on 4/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GraphNode;

@interface GraphEdge : NSObject<NSCoding> 

@property (nonatomic, readonly, strong)  GraphNode *fromNode;
@property (nonatomic, readonly, strong)  GraphNode *toNode;
@property (nonatomic, readwrite, assign) float     weight;
@property (nonatomic, assign)	 BOOL      reverted;

- (id)init;
- (id)initWithFromNode:(GraphNode*)fromNode toNode:(GraphNode*)toNode;
- (id)initWithFromNode:(GraphNode*)fromNode toNode:(GraphNode*)toNode weight:(float)weight;
- (BOOL)isEqualToGraphEdge:(GraphEdge*)other;

+ (id)edge;
+ (id)edgeWithFromNode:(GraphNode*)fromNode toNode:(GraphNode*)toNode;
+ (id)edgeWithFromNode:(GraphNode*)fromNode toNode:(GraphNode*)toNode weight:(float)weight;

@end
