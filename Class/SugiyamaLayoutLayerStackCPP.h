//
//  SugiyamaLayoutLayerStack.h
//  drawify
//
//  Created by Damian Stewart on 12.08.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#pragma once

#include <vector>
#include <map>
#import "GRaph.h"
#import "PositionedGraphNode.h"

using namespace std;

class Node;

class SugiyamaLayoutLayerStack 
{
public:
	
	void add(PositionedGraphNode* n1, int layerIndex);
	double avgX(const vector<PositionedGraphNode*>& ln);
	int barycenter(const vector<PositionedGraphNode*>& ln);
	vector<PositionedGraphNode*> getConnectedTo(PositionedGraphNode* n1, int layerIndex);
	int getLayer(PositionedGraphNode* n);
	
	void init(int height, int nodeQty);	
	void initIndexes();
	
	void layerHeights();
	double maxHeight(const vector<PositionedGraphNode*>& ln);
	void reduceCrossings();
	void reduceCrossings2L(int staticIndex, int flexIndex);	
	void setOrderedIndexes(vector<PositionedGraphNode*>& ln);	
	/*
	 @Override
	 public String toString() {
	 StringBuilder sb = new StringBuilder(getClass().getSimpleName());
	 sb.append("(").append(layers.size()).append(")");
	 int lc = 0;
	 for (vector<Node*> l : layers) {
	 sb.append("\n\t").append(lc++).append(" # ").append(l);
	 }
	 return sb.toString();
	 }*/
	
	void xPos();
	
	
	void xPosDown(int staticIndex, int flexIndex);
	void xPosPack(int flexIndex);
	
	void xPosUp(int staticIndex, int flexIndex);

private:
	vector<vector<PositionedGraphNode*> > layers;
	map<PositionedGraphNode*, int> nodemap;
	


};
