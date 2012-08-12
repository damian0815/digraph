//
//  Graph.m
//  danmaku
//
//  Created by aaron qian on 4/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Graph.h"


@interface GraphNode()
@property (nonatomic, readwrite, retain) NSSet *edgesIn;
@property (nonatomic, readwrite, retain) NSSet *edgesOut;
@property (nonatomic, readwrite, retain) id    value;
- (GraphEdge*)linkToNode:(GraphNode*)node;
- (GraphEdge*)linkToNode:(GraphNode*)node usingEdgeObject:(GraphEdge*)edge;
- (GraphEdge*)linkToNode:(GraphNode*)node weight:(float)weight;
- (GraphEdge*)linkFromNode:(GraphNode*)node;
- (GraphEdge*)linkFromNode:(GraphNode*)node weight:(float)weight;
- (void)unlinkToNode:(GraphNode*)node;
- (void)unlinkFromNode:(GraphNode*)node;
@end

// private methods for Graph
@interface Graph()
@property (nonatomic, readwrite, retain) NSSet *nodes;
- (GraphNode*)smallest_distance:(NSMutableDictionary*)dist nodes:(NSMutableSet*)nodes;
- (BOOL)hasNode:(GraphNode*)node;
@end


@implementation Graph

@synthesize nodes = nodes_;

- (id)init
{
    if ( (self = [super init]) ) {
        self.nodes = [NSMutableSet set];
    }
    
    return self;
}

- (void)dealloc
{
    [nodes_ release];
    [super dealloc];
}




// Using Dijkstra's algorithm to find shortest path
// See http://en.wikipedia.org/wiki/Dijkstra%27s_algorithm
- (NSArray*)shortestPath:(GraphNode*)source to:(GraphNode*)target {
    if (![nodes_ containsObject:source] || ![nodes_ containsObject:target]) {
        return [NSArray array];
    }

    NSUInteger size = [nodes_ count];
    NSMutableDictionary* dist = [NSMutableDictionary dictionaryWithCapacity:size];
    NSMutableDictionary* prev = [NSMutableDictionary dictionaryWithCapacity:size];
    NSMutableSet* remaining = [[nodes_ mutableCopy] autorelease];
    
    for(GraphNode* node in [nodes_ objectEnumerator])
        [dist setObject:[NSNumber numberWithFloat:INFINITY] forKey:node];
    
    [dist setObject:[NSNumber numberWithFloat:0.0f] forKey:source];
    
    while ([remaining count] != 0) {
        // find the node in remaining with the smallest distance
        GraphNode* minNode = [self smallest_distance:dist nodes:remaining];
        float min = [[dist objectForKey: minNode] floatValue];

        if (min == INFINITY)
            break;
        
        // we found it!
        if( [minNode isEqual: target] ) {
            NSMutableArray* path = [NSMutableArray array];
            GraphNode* temp = target;
            while ([prev objectForKey:temp]) {
                [path addObject:temp];
                temp = [prev objectForKey:temp];
            }
            return [ NSMutableArray arrayWithArray:
                    [ [path reverseObjectEnumerator ] allObjects]];
        }
        
        // didn't find it yet, keep going
        
        [remaining removeObject:minNode];

        // find neighbors that have not been removed yet
        NSMutableSet* neighbors = [[minNode outNodes] mutableCopy];
        [neighbors intersectSet:remaining];
        
        // loop through each neighbor to find min dist
        for (GraphNode* neighbor in [neighbors objectEnumerator]) {
            NSLog(@"Looping neighbor %@", (NSString*)[neighbor key]);
            float alt = [[dist objectForKey: minNode] floatValue];
            alt += [[minNode edgeConnectedTo: neighbor] weight];
            
            if( alt < [[dist objectForKey: neighbor] floatValue] ) {
                [dist setObject:[NSNumber numberWithFloat:alt] forKey:neighbor];
                [prev setObject:minNode forKey:neighbor];
            }
        }
    }
    
    return [NSArray array];
}

- (GraphNode*)smallest_distance:(NSMutableDictionary*)dist nodes:(NSMutableSet*)nodes {
    NSEnumerator *e = [nodes objectEnumerator];
    GraphNode* node;
    GraphNode* minNode = [e nextObject];
    NSNumber *min = [dist objectForKey: minNode];
    
    while ( (node = [e nextObject]) ) {
        NSNumber *temp = [dist objectForKey:node];
        
        if ( [temp floatValue] < [min floatValue] ) {
            min = temp;
            minNode = node;
        }
    }
    
    return minNode;
}

- (BOOL)hasNode:(GraphNode*)node {
    return nil != [nodes_ member:node];
}

- (BOOL)hasNodeWithKey:(NSString*)key {
	return [self hasNode:[GraphNode nodeWithKey:key]];
}

- (GraphNode*)nodeWithKey:(NSString*)key {
	return [nodes_ member:[GraphNode nodeWithKey:key]];
}


// addNode first checks to see if we already have a node
// that is equal to the passed in node.
// If an equal node already exists, the existing node is returned
// Otherwise, the new node is added to the set and then returned.
- (GraphNode*)addNode:(GraphNode*)node {
    GraphNode* existing = [nodes_ member:node];
    if (!existing) {
       [nodes_ addObject:node]; 
        existing = node;
    }
    return existing;
}

- (GraphEdge*)addEdgeFromNode:(GraphNode*)fromNode toNode:(GraphNode*)toNode {
    fromNode = [self addNode:fromNode];
    toNode   = [self addNode:toNode];
    return [fromNode linkToNode:toNode];
}

- (GraphEdge*)addEdgeFromNodeWithKey:(NSString*)fromKey toNodeWithKey:(NSString*)toKey
{
	return [self addEdgeFromNode:[GraphNode nodeWithKey:fromKey] toNode:[GraphNode nodeWithKey:toKey]];
}


- (GraphEdge*)addEdgeFromNode:(GraphNode*)fromNode toNode:(GraphNode*)toNode withWeight:(float)weight {
    fromNode = [self addNode:fromNode];
    toNode   = [self addNode:toNode];
    return [fromNode linkToNode:toNode weight:weight];    
}

- (void)removeNode:(GraphNode*)node {
    [nodes_ removeObject:node];
}

- (void)removeEdge:(GraphEdge*)edge {
    [[edge fromNode] unlinkToNode:[edge toNode]];
}


- (void)revertEdge:(GraphEdge *)edge
{
	if ( ![edge reverted] )
	{
		// remove existing edge
		[self removeEdge:edge];
		
		// replace + add again
		[[edge toNode] linkToNode:[edge fromNode] usingEdgeObject:edge];
		[edge setReverted:YES];
	}	
}

- (void)unrevertEdge:(GraphEdge *)edge
{
	if ( [edge reverted] )
	{
		// remove existing edge
		[self removeEdge:edge];
		
		// replace + add again
		[[edge toNode] linkToNode:[edge fromNode] usingEdgeObject:edge];
		[edge setReverted:NO];
	}	
}



+ (Graph*)graph {
    return [[[self alloc] init] autorelease];
}


- (NSSet*)allNodes{
	return nodes_;
}

- (NSSet*)allEdges{
	NSMutableSet* edges = [NSMutableSet set];
	NSSet* nodes = [self allNodes];
	for ( GraphNode* node in nodes ) {
		[edges unionSet:[node edgesIn]];
		[edges unionSet:[node edgesOut]];
	}
	return edges;
}

/// returns an array of NSSets
- (NSArray*)connectedComponents
{
	NSMutableArray* components = [NSMutableArray array];
	
	NSMutableSet* remaining = [[self allNodes] mutableCopy];
	while ( [remaining count] > 0 )
	{
		GraphNode* node = [remaining anyObject];
		[remaining removeObject:node];
		
		// get the component containing this node
		NSSet* component = [self connectedComponentContainingNodeWithKey:[node key]];
		[components addObject:component];

		// remove it from the remaining nodes to be checked
		[remaining minusSet:component];
	}
	
	// done
	return components;
	
}

- (NSSet*)connectedComponentContainingNodeWithKey:(NSString*)key
{
	// traverse
	NSMutableSet* visitedNodes = [NSMutableSet set];
	NSMutableSet* queue = [NSMutableSet setWithObject:[self nodeWithKey:key]];
	while ( [queue count] > 0 )
	{
		// get next from queue
		GraphNode* n = [queue anyObject];
		[queue removeObject:n];
		[visitedNodes addObject:n];
		// visit unvisited
		for ( GraphNode* next in [n outNodes] ) {
			if ( ![visitedNodes containsObject:next] )
				[queue addObject:next];
		}
		for ( GraphNode* prev in [n inNodes] ) {
			if ( ![visitedNodes containsObject:prev] )
				[queue addObject:prev];
		}
			
	}
	
	// done
	return visitedNodes;
}


+ (NSArray*)topologicalSortWithNodes:(NSSet*)nodes
{
	NSMutableArray* q = [NSMutableArray array];
	for ( GraphNode* node in nodes ){
		if ( [node isSource] )
			[q addObject:node];
	}
	
	NSMutableArray* l = [NSMutableArray array];// = new /*Array*/vector<Node*>(this.graph.getNodes().size());
	NSMutableSet* r = [NSMutableSet set];// = new /*Array*/vector<Edge*>(this.graph.getEdges().size()); // removed
	// edges
	while ([q count] > 0) {

		NSLog(@"Topological sort iteration: %i total nodes (%@), %i sorted nodes (%@), r contains %@, remaining nodes: %@\n", [nodes count], nodes, [l count], l, r, q );
		
		GraphNode* n = [q objectAtIndex:0];
		[q removeObjectAtIndex:0];
		[l addObject:n];

		NSSet* outEdges = [n edgesOut];
		for ( GraphEdge* e in outEdges ) {
			GraphNode* m = [e toNode];
			[r addObject:e];
			BOOL allEdgesRemoved = YES;
			// then checking if the target has any more "in" edges left
			
			NSSet* inEdges = [n edgesIn];
			for ( GraphEdge* e2 in inEdges ) {
				if ( ![r containsObject:e2] ) {
					allEdgesRemoved = false;
				}
			}
			if (allEdgesRemoved) {
				[q addObject:m];
			}
		}
	}
	if ( [nodes count] != [l count] ) {
		NSLog(@"Topological sort failed for graph, %i total nodes (%@), %i sorted nodes (%@), r contains %@, remaining nodes: %@\n", [nodes count], nodes, [l count], l, r, q );
		assert(false && "topological sort failed");
	}
	return l;

}

@end
