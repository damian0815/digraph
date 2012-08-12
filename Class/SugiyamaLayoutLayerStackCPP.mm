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

#include "SugiyamaLayoutLayerStackCPP.h"
#include <math.h>
#include <algorithm>
#include <limits>
#import "Graph.h"
#import "PositionedGraphNode.h"

/**
 * A stack of layers for the Sugiyama layout
 * 
 * @author avishnyakov
 */
static const int MAX_SWEEPS = 100;
static const double X_SEP = 40;
static const double Y_SEP = 75;

void SugiyamaLayoutLayerStack::add(PositionedGraphNode* n1, int layerIndex) {
	layers[layerIndex].push_back(n1);
	nodemap[n1] = layerIndex;
}

double SugiyamaLayoutLayerStack::avgX(const vector<PositionedGraphNode*>& ln) {
	double m = 0;
	for ( vector<PositionedGraphNode*>::const_iterator it = ln.begin(); it != ln.end(); ++it ) {
		PositionedGraphNode* n = *it;
		m += [n centrePos].x;
	}
	return m / ln.size();
}

int SugiyamaLayoutLayerStack::barycenter(const vector<PositionedGraphNode*>& ln) {
	if (ln.size() == 0) {
		return 0;
	} else {
		double bc = 0;
		for ( vector<PositionedGraphNode*>::const_iterator it = ln.begin(); it != ln.end(); ++it ) {
			PositionedGraphNode* n = *it;
			bc += [n index];
		}
		return (int) floor((bc / ln.size())+0.5f);
	}
}

vector<PositionedGraphNode*> SugiyamaLayoutLayerStack::getConnectedTo(PositionedGraphNode* n1, int layerIndex) {
	vector<PositionedGraphNode*> ln;
	if (layerIndex < layers.size() && layerIndex >= 0) {
		for ( vector<PositionedGraphNode*>::iterator it = layers.at(layerIndex).begin(); it != layers.at(layerIndex).end(); ++it )
		{
			PositionedGraphNode* n2 = *it;
			if (nil!=[n1 edgeConnectedTo:n2]) {
				ln.push_back(n2);
			}
		}
	}
	return ln;
}

int SugiyamaLayoutLayerStack::getLayer(PositionedGraphNode* n) {
	map<PositionedGraphNode*, int>::iterator it = nodemap.find(n);
	if ( it == nodemap.end() )
		return 0;
	else
		return (*it).second;
}

void SugiyamaLayoutLayerStack::init(int height, int nodeQty) {
	layers.clear();
	layers.resize(height);
	for (int i = 0; i < height; i++) {
		layers[i].resize( nodeQty / (height+1) );
	}
	//nodemap.reserve(nodeQty);
	nodemap.clear();
}

bool compareIndices( PositionedGraphNode* n1, PositionedGraphNode* n2 )
{
	return [n1 index] < [n2 index];
}

void SugiyamaLayoutLayerStack::initIndexes() {
	for ( vector<vector<PositionedGraphNode*> >::iterator it = layers.begin(); it != layers.end(); ++it )
	{
		vector<PositionedGraphNode*>& l = *it;
		
		sort( l.begin(), l.end(), compareIndices );
		/*
		@todo figure out how to do this
		Collections.sort(l, new Comparator<PositionedGraphNode*>() {
			public int compare(PositionedGraphNode* n1, PositionedGraphNode* n2) {
				return n1.getIndex() - n2.getIndex();
			}
		});*/
		
		setOrderedIndexes(l);
	}
}

void SugiyamaLayoutLayerStack::layerHeights() {
	double offset = 0;
	for (int l = 0; l < layers.size(); l++) {
		vector<PositionedGraphNode*>& ln = layers[l];
		double maxh = maxHeight(ln);
		for ( vector<PositionedGraphNode*>::iterator it = ln.begin(); it != ln.end(); ++it ) {
			PositionedGraphNode* n = (*it);
			if (/*n->isVirtual()*/false) {
				[n setPos:CGPointMake( [n pos].x, offset+maxHeight(ln)/2.0)];
			} else {
				[n setPos:CGPointMake( [n pos].x, offset )];
			}
		}
		offset += maxh + Y_SEP;
	}
}

double SugiyamaLayoutLayerStack::maxHeight(const vector<PositionedGraphNode*>& ln) {
	double mh = 0;
	for ( vector<PositionedGraphNode*>::const_iterator it = ln.begin(); it != ln.end(); ++it ) {
		PositionedGraphNode* n = (*it);
		mh = MAX(mh, [n size].height);
	}
	return mh;
}

void SugiyamaLayoutLayerStack::reduceCrossings() {
	for (int round = 0; round < MAX_SWEEPS; round++) {
		if (round % 2 == 0) {
			for (int l = 0; l < layers.size() - 1; l++) {
				reduceCrossings2L(l, l + 1);
			}
		} else {
			for (int l = layers.size() - 1; l > 0; l--) {
				reduceCrossings2L(l, l - 1);
			}
		}
	}
}

void SugiyamaLayoutLayerStack::reduceCrossings2L(int staticIndex, int flexIndex) {
	assert( flexIndex < layers.size() );
	vector<PositionedGraphNode*>& flex = layers[flexIndex];
	for ( vector<PositionedGraphNode*>::const_iterator it = flex.begin(); it != flex.end(); ++it )
	{
		PositionedGraphNode* n = (*it);
		vector<PositionedGraphNode*> neighbors = getConnectedTo(n, staticIndex);
		[n setIndex:barycenter(neighbors)];
	}
	
	sort( flex.begin(), flex.end(), compareIndices );
	
	setOrderedIndexes(flex);
}

void SugiyamaLayoutLayerStack::setOrderedIndexes(vector<PositionedGraphNode*>& ln) {
	for (int i = 0; i < ln.size(); i++) {
		[ln[i] setIndex:i];
	}
}

/*
@Override
public String toString() {
	StringBuilder sb = new StringBuilder(getClass().getSimpleName());
	sb.append("(").append(layers.size()).append(")");
	int lc = 0;
	for (vector<PositionedGraphNode*> l : layers) {
		sb.append("\n\t").append(lc++).append(" # ").append(l);
	}
	return sb.toString();
}*/

void SugiyamaLayoutLayerStack::xPos() {
	for (int l = 0; l < layers.size(); l++) {
		xPosPack(l);
	}
	for (int l = 0; l < layers.size() - 1; l++) {
		xPosDown(l, l + 1);
	}
	for (int l = layers.size() - 1; l > 0; l--) {
		xPosUp(l, l - 1);
	}
}

void SugiyamaLayoutLayerStack::xPosDown(int staticIndex, int flexIndex) {
	assert( flexIndex < layers.size() );
	vector<PositionedGraphNode*> flex = layers[flexIndex];
	for (int i = 0; i < flex.size(); i++) {
		PositionedGraphNode* n = flex[i];
		vector<PositionedGraphNode*> neighbors = getConnectedTo(n, staticIndex);
		double avg = avgX(neighbors);
		// if i is 0 use avg as min (ie don't use a min)
		double min = (i > 0) ? (flex[i-1].pos.x + flex[i-1].size.width + X_SEP) : (-numeric_limits<double>::max());
		if (!isnan(avg)) {
			[n setPos:CGPointMake( MAX(min, avg - n.size.width/2.0), n.pos.y )];
			//n->setPos(max(min, avg - n->getSize().x / 2d), n->getPos().y);
		}
	}
}

void SugiyamaLayoutLayerStack::xPosPack(int flexIndex) {
	assert( flexIndex < layers.size() );
	vector<PositionedGraphNode*>& flex = layers[flexIndex];
	double offset = 0;
	for ( vector<PositionedGraphNode*>::const_iterator it = flex.begin(); it != flex.end(); ++it ) {
		PositionedGraphNode* n = (*it);
		[n setPos:CGPointMake(offset, n.pos.y)];
		offset = n.pos.x + n.size.width + X_SEP;
	}
}

void SugiyamaLayoutLayerStack::xPosUp(int staticIndex, int flexIndex) {
	assert( flexIndex < layers.size() );
	vector<PositionedGraphNode*> flex = layers[flexIndex];
	for (int i = flex.size() - 1; i > -1; i--) {
		PositionedGraphNode* n = flex[i];
		vector<PositionedGraphNode*> neighbors = getConnectedTo(n, staticIndex);
		//NSLog(@" %@ has %i neighbors: ", [n key], neighbors.size() );
		//for ( int i=0; i<neighbors.size() ;i++ )
		//	NSLog(@"   %@", [neighbors[i] key] );
		double avg = avgX(neighbors);
		// calculate min, max
		double min = (i>0)?(flex[i-1].pos.x + flex[i-1].size.width + X_SEP) : -numeric_limits<double>::max();
		double max = (i<flex.size()-1)?(flex[i+1].pos.x - n.size.width - X_SEP) : numeric_limits<double>::max();
		
		if (!isnan(avg)) {
			[n setPos:CGPointMake(MAX(min, MIN(max, avg - n.size.width / 2.0)), n.pos.y)];
		}
	}
}
/*
void SugiyamaLayoutLayerStack::xPosUp(int staticIndex, int flexIndex) {
	assert( flexIndex < layers.size() );
	vector<PositionedGraphNode*> flex = layers[flexIndex];
	for (int i = flex.size() - 1; i > -1; i--) {
		PositionedGraphNode* n = flex[i];
		double min = i > 0 ? flex.get(i - 1).getPos().x + flex.get(i - 1).getSize().x + X_SEP : -Double.MAX_VALUE;
		double max = i < flex.size() - 1 ? flex.get(i + 1).getPos().x - n.getSize().x - X_SEP : Double.MAX_VALUE;
		List<AbstractBox<?>> neighbors = getConnectedTo(n, staticIndex);
		double avg = avgX(neighbors);
		if (!Double.isNaN(avg)) {
			n.setPos(max(min, min(max, avg - n.getSize().x / 2d)), n.getPos().y);
		}
	}
}*/



/*
 * 
 * 
 * double barycenterX(double def, vector<PositionedGraphNode*> ln) { if (ln.size() == 0)
 * { return def; } else { double bc = 0; for (PositionedGraphNode* n : ln) { bc +=
 * n.getCtrPos().x; } return bc / ln.size(); } }
 * 
 * void xPositions() { double maxx = 0; double x[] = new double[layers.size()];
 * for (int l = 0; l < layers.size(); l++) { double currOffset = 0d; for
 * (PositionedGraphNode* n : layers.get(l)) { currOffset += n.getSize().x +
 * xSeparation; } x[l] = currOffset - xSeparation; maxx = max(maxx, x[l]); } for
 * (int l = 0; l < layers.size(); l++) { double currOffset = (maxx - x[l]) / 2d;
 * for (PositionedGraphNode* n : layers.get(l)) { n.getPos().x = currOffset;
 * currOffset += n.getSize().x + xSeparation; } } }
 * 
 * 
 * void adjustPosX(int staticLayer1, int flexLayer, int staticLayer2) {
 * vector<PositionedGraphNode*> flex = layers.get(flexLayer); double currOffset = 0d;
 * for (PositionedGraphNode* n : flex) { vector<PositionedGraphNode*> neighbors1 =
 * getConnectedTo(n, staticLayer1); vector<PositionedGraphNode*> neighbors2 =
 * getConnectedTo(n, staticLayer2); neighbors1.addAll(neighbors2); double bc1 =
 * barycenterX(n.getCtrPos().x, neighbors1) - n.getSize().x / 2d; // double bc2
 * = barycenterX(bc1, neighbors2) - n.getSize().x / 2d; n.getPos().x =
 * max(currOffset, bc1); currOffset = n.getPos().x + n.getSize().x +
 * xSeparation; //if ("c3:o3".equals(n.getName())) { // log.debug(n); //}
 * //log.debug(staticLayer1 + "/" + staticLayer2 + "->" + flexLayer + " " +
 * flex); } }
 * 
 * 
 * -------------------
 * 
 * 
 * void xPos() { for (int l = 0; l < layers.size() - 1; l++) { xPosDown(l, l +
 * 1); } for (int l = layers.size() - 1; l > 0; l--) { xPosUp(l, l - 1); } for
 * (int l = 0; l < layers.size() - 1; l++) { xPosDown(l, l + 1); } }
 * 
 * void xPosDown(int staticIndex, int flexIndex) { vector<PositionedGraphNode*> flex =
 * layers.get(flexIndex); double offset = 0d; for (PositionedGraphNode* n : flex) {
 * vector<PositionedGraphNode*> neighbors = getConnectedTo(n, staticIndex); n.getPos().x
 * = max(offset, maxX(neighbors) - n.getSize().x / 2d); offset = n.getPos().x +
 * n.getSize().x + xSeparation; } }
 * 
 * void xPosUp(int staticIndex, int flexIndex) { vector<PositionedGraphNode*> flex =
 * layers.get(flexIndex); double offset = Double.MAX_VALUE; for (int i =
 * flex.size() - 1; i >= 0; i--) { PositionedGraphNode* n = flex.get(i);
 * vector<PositionedGraphNode*> neighbors = getConnectedTo(n, staticIndex); if
 * (neighbors.isEmpty()) { n.getPos().x = min(offset - n.getSize().x,
 * n.getPos().x); offset = Double.MAX_VALUE == offset ? n.getPos().x +
 * n.getSize().x : offset; } else { n.getPos().x = min(offset, minX(neighbors) +
 * n.getSize().x / 2d) - n.getSize().x; } offset = n.getPos().x - xSeparation; }
 * }
 * 
 * for (int l = layers.size() - 1; l > 0; l--) { xPosUp(l, l - 1); } for (int l
 * = 0; l < layers.size() - 1; l++) { xPosDown(l, l + 1); } for (int l =
 * layers.size() - 1; l > 0; l--) { xPosUp(l, l - 1); } for (int l = 0; l <
 * layers.size() - 1; l++) { xPosDown(l, l + 1); }
 * 
 * 
 * double maxX(vector<PositionedGraphNode*> ln) { double m = -Double.MAX_VALUE; for
 * (PositionedGraphNode* n : ln) { m = max(n.getCtrPos().x, m); } return m; }
 * 
 * double minX(vector<PositionedGraphNode*> ln) { double m = Double.MAX_VALUE; for
 * (PositionedGraphNode* n : ln) { m = min(n.getCtrPos().x, m); } return m; }
 */
