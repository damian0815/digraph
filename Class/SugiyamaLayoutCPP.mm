/**
 * Copyright 2008 Andrew Vishnyakov <avishn@gmail.com>
 * 
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy of
 * the License at
 * 
 * http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations under
 * the License.
 */


/*
 class diagram Sample {
 abstract class AbstractElement {
 name; parent; type;
 abstract accept(AbstractVisitor);
 } 
 abstract class AbstractBox extends AbstractElement {
 pos; disp; size;
 }
 class Edge extends AbstractElement {
 labels; bends; node1; node2;
 }
 class Bend extends AbstractBox {}
 class Graph extends AbstractBox {
 reqSize; labels; 
 1->*(Edge);
 1->*(Node);
 }
 class Node extends AbstractBox {
 connectedEdges; labels;
 }    
 }
 */

/**
 * Sugiyama layout algorithm
 * @author avishnyakov
 * Converted from Java to C++ by Damian Stewart
 * @author damian@damianstewart.com
 *
 */

#include "SugiyamaLayoutLayerStackCPP.h"
#include "SugiyamaLayoutCPP.h"
#include <set>
#include <algorithm>

#import "PositionedGraphNode.h"


class SugiyamaLayout
{
public:
	
	void apply(Graph* _graph) ;
	
private:
	
	
	void insertDummies();
	void splitIntoLayers();
	bool dup(GraphEdge* e1);
	void removeCycles();
	vector<PositionedGraphNode*> sortByOutDegree();
	
	vector<PositionedGraphNode*> sortByInMinusOutDegree();
	vector<PositionedGraphNode*> sources();
	vector<PositionedGraphNode*> topologicalSort();
	void undoRemoveCycles();
	
	Graph* graph;
	SugiyamaLayoutLayerStack stack;
	
	
};



int sugiyamaLayout( Graph* graphToLayout )
{
	// check class of all nodes
	bool fail = false;
	for ( id node in [graphToLayout allNodes] ) {
		if ( ![[node class] isSubclassOfClass:[PositionedGraphNode class]] ) {
			NSLog(@"sugiyamaLayout: can't perform, node %@ is not a subclass of PositionedGraphNode", [node key] );
			fail = true;
		}
	}
	
	if ( [[graphToLayout connectedComponents] count] > 1 ) {
		NSLog(@"sugiyamaLayout: can't perform, graph has >1 connected components" );
		fail = true;
	}
	
	if ( fail )
		return 0;
	
	SugiyamaLayout layout;
	layout.apply( graphToLayout );

	return 1;
}






void SugiyamaLayout::apply(Graph* _graph) 
{
	graph = _graph;
	//NSLog(@"removeCycles");
	removeCycles();
	//NSLog(@"splitIntoLayers");
	splitIntoLayers();
	//NSLog(@"insertDummies");
	insertDummies();
	//NSLog(@"initIndexes");
	stack.initIndexes();
	//NSLog(@"reduceCrossings");
	stack.reduceCrossings();
	//NSLog(@"undoRemoveCycles");
	undoRemoveCycles();
	//NSLog(@"layerHoughts");
	stack.layerHeights();
	//NSLog(@"xPos");
	stack.xPos();
	// log.debug(new ToStringVisitor().toString(graph));
}


void SugiyamaLayout::insertDummies() {
	NSSet* edges = [graph allEdges];
	for ( GraphEdge* currEdge in edges ) {
		int fromLayer = stack.getLayer((PositionedGraphNode*)[currEdge fromNode]);
		int toLayer = stack.getLayer((PositionedGraphNode*)[currEdge toNode]);
		if (toLayer - fromLayer > 1) {
			for (int layer = fromLayer + 1; layer < toLayer; layer++) {
				assert( false && "busted" );
				/*
				Bend b = new Bend();
				currEdge->add(b);
				stack.add(b, layer);*/
			}
		}
	}
}

void SugiyamaLayout::splitIntoLayers() {
	// topo sort
	NSArray* sortedNSA = [Graph topologicalSortWithNodes:[graph allNodes]];
	// convert to C++ vector
	vector<PositionedGraphNode*> sorted;
	for ( PositionedGraphNode* node in sortedNSA )
		sorted.push_back( node );

	
	map<PositionedGraphNode*, int> lmap;
	for ( vector<PositionedGraphNode*>::iterator it = sorted.begin(); it != sorted.end(); ++it )
	{
		PositionedGraphNode* n = *it;
		lmap[n] = 0;
	}

	int h = 1;
	for ( vector<PositionedGraphNode*>::iterator it = sorted.begin(); it != sorted.end(); ++it )
	{
		PositionedGraphNode* n1 = *it;
		
		NSSet* outEdges = [n1 edgesOut];
		
		for ( GraphEdge* e in outEdges )
		{
			PositionedGraphNode* n2 = (PositionedGraphNode*)[e toNode];
			// ???? int inc = dup(e) ? 2 : 1; 
			// need to put nodes connected with
			// > 1 edge further away
			int inc = 1;
			lmap[n2] = max(lmap[n1] + inc, lmap[n2]);
			h = max(h, lmap[n2] + 1);
		}
	}
	stack.init(h, (int)sorted.size());
	for ( vector<PositionedGraphNode*>::iterator it = sorted.begin(); it != sorted.end(); ++it )
	{
		PositionedGraphNode* n = *it;
		stack.add(n, lmap[n]);
	}
}

/*
bool SugiyamaLayout::dup(GraphEdge* e1) {
	vector<GraphEdge*> parentEdges = e1->getParent()->getEdges();
	for ( vector<GraphEdge*>::iterator it = parentEdges.begin() ;it != parentEdges.end(); ++it )
	{
		GraphEdge* e2 = (*it);
		if ( e2 != e1 && (
						  ( e1->getNode1()==e2->getNode1() && e1->getNode2()==e2->getNode2() ) || 
						  ( e1->getNode2()==e2->getNode1() && e1->getNode1()==e2->getNode2() )
						  )
			) 
		{
			return true;
		}
	}
	return false;
}*/

/*
void removeCycles() {
	List<Node> nodes = sortByInMinusOutDegree();
	Set<Edge> removed = new HashSet<Edge>(graph.getEdges().size());
	for (Node n : nodes) {
		List<Edge> inEdges = new ArrayList<Edge>(n.getInEdges());
		List<Edge> outEdges = new ArrayList<Edge>(n.getOutEdges());
		for (Edge in : inEdges) {
			if (!removed.contains(in)) {
				in.setReverted(true);
				removed.add(in);
			}
		}
		for (Edge out : outEdges) {
			if (!removed.contains(out)) {
				removed.add(out);
			}
		}
	}
}
*/

void SugiyamaLayout::removeCycles() {
	vector<PositionedGraphNode*> nodes = sortByInMinusOutDegree();
	set<GraphEdge*> removed;
	//removed.reserve(graph->getEdges().size());
	
	
	
	for ( vector<PositionedGraphNode*>::iterator it = nodes.begin(); it != nodes.end(); ++it )
	{
		PositionedGraphNode* n = *it;
		//NSLog(@"removing cycles for node %@", [n key] );

		
		NSSet* inEdges = [n edgesIn];
		NSSet* outEdges = [n edgesOut];
		
		for ( GraphEdge* inEdge in inEdges )
		{
			if (removed.find(inEdge)==removed.end()) {
				[graph unrevertEdge:inEdge];
				removed.insert(inEdge);
			}
		}

		for ( GraphEdge* outEdge in outEdges )
		{
			if (removed.find(outEdge)==removed.end()) {
				removed.insert(outEdge);
			}
		}
	}
}

bool compareOutDegrees( PositionedGraphNode* n1, PositionedGraphNode* n2 );
bool compareOutDegrees( PositionedGraphNode* n1, PositionedGraphNode* n2 ) {
	return [n2 outDegree] < [n1 outDegree];
}

vector<PositionedGraphNode*> SugiyamaLayout::sortByOutDegree() {
	
	vector<PositionedGraphNode*> nodes;// = new /*Array*/vector<PositionedGraphNode*>(graph.getNodes());
	for ( PositionedGraphNode* node in [graph allNodes] )
		nodes.push_back( node );
	
	sort( nodes.begin(), nodes.end(), compareOutDegrees );
	
	return nodes;
}

bool compareInMinusOutDegree( PositionedGraphNode* n1, PositionedGraphNode* n2 );
bool compareInMinusOutDegree( PositionedGraphNode* n1, PositionedGraphNode* n2 ){
	return ([n1 inDegree]*2 - [n1 outDegree]) < ([n2 inDegree]*2 - [n2 outDegree]);
}

vector<PositionedGraphNode*> SugiyamaLayout::sortByInMinusOutDegree() {
	vector<PositionedGraphNode*> nodes;// = new /*Array*/vector<PositionedGraphNode*>(graph.getNodes());
	for ( PositionedGraphNode* node in [graph allNodes] )
		nodes.push_back( node );
	
	sort( nodes.begin(), nodes.end(), compareInMinusOutDegree );
	
	return nodes;
}

vector<PositionedGraphNode*> SugiyamaLayout::sources() {
	
	vector<PositionedGraphNode*> sources;// = new /*Linked*/vector<PositionedGraphNode*>();
	
	for ( PositionedGraphNode* n in [graph allNodes] )
	{
		if ( [n inDegree] == 0) {
			sources.push_back(n);
		}
	}
	return sources;
}

/*
vector<PositionedGraphNode*> SugiyamaLayout::topologicalSort() {
	vector<PositionedGraphNode*> q = sources();
	vector<PositionedGraphNode*> l;// = new ArrayList<PositionedGraphNode*>(this.graph.getNodes().size());
	vector<GraphEdge*> r;// = new ArrayList<GraphEdge*>(this.graph.getEdges().size()); // removed
	// edges
	while (q.size() > 0) {
		PositionedGraphNode* n = q[0];
		q.erase( q.front() );
		l.push_back(n);
		
		vector<GraphEdge*> outEdges = n->getOutEdges();
		for ( vector<GraphEdge*>::iterator it = outEdges.begin(); it != outEdges.end(); ++it )
		{
			GraphEdge* e = (*it);
			PositionedGraphNode* m = e->getNode2();
			r.push_back(e); // removing edge from the graph
			bool allEdgesRemoved = true;
			// then checking if the target has any more "in" edges left
			
			vector<GraphEdge*> inEdges = n->getInEdges();
			for ( vector<GraphEdge*>::iterator jt = inEdges.begin(); jt != inEdges.end(); ++jt )
			{
				GraphEdge* e2 = (*jt);
				if (r.find(e2)==r.end()) {
					allEdgesRemoved = false;
				}
			}
			if (allEdgesRemoved) {
				q.push_back(m);
			}
		}
	}
	if (graph.getNodes().size() != l.size()) {
		
		printf("Topological sort failed for graph in Sugiyama layout, %i total nodes, %i sorted nodes, %i remaining nodes\n", graph.getNodes().size(), l.size(), q.size() );
		assert(false && "topological sort failed");
	}
	return l;
}*/

void SugiyamaLayout::undoRemoveCycles() {
	
	vector<PositionedGraphNode*> nodes;
	for ( PositionedGraphNode* node in [graph allNodes] )
		nodes.push_back( node );
	
	set<GraphEdge*> removed;
	//removed.reserve(graph->getEdges().size());
	
	for ( vector<PositionedGraphNode*>::iterator it = nodes.begin(); it != nodes.end(); ++it )
	{
		PositionedGraphNode* n = *it;
		
		NSSet* inEdges = [n edgesIn];
		NSSet* outEdges = [n edgesOut];

		for ( GraphEdge* inEdge in inEdges )
		{
			if (removed.find(inEdge)==removed.end()) {
				[graph unrevertEdge:inEdge];
				removed.insert(inEdge);
			}
		}
		
		for ( GraphEdge* outEdge in outEdges )
		{
			if (removed.find(outEdge)==removed.end()) {
				[graph unrevertEdge:outEdge];
				removed.insert(outEdge);
			}
		}
	}
}

