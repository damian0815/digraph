//
//  SugiyamaLayout.h
//  drawify
//
//  Created by Damian Stewart on 12.08.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#pragma once

#include "SugiyamaLayoutLayerStackCPP.h"

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

