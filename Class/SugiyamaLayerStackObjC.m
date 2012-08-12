
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

/// converted to Objective C by Damian Stewart 2012

#import "SugiyamaLayerStack.h"

@interface SugiyamaLayerStack()
{
	NSMutableArray* layers; // List<List<AbstractBox<?>>> layers;
	NSMutableDictionary* nodeMap; // Map<AbstractBox<?>, Integer> nodeMap;
	
}

@end

@implementation SugiyamaLayerStack

static final int MAX_SWEEPS = 100;
static final double X_SEP = 40;
static final double Y_SEP = 75;

-(void) add(AbstractBox<?> n1, int layerIndex) {
	layers.get(layerIndex).add(n1);
	nodeMap.put(n1, layerIndex);
}

-(double) avgX(List<AbstractBox<?>> ln) {
	double m = 0d;
	for (AbstractBox<?> n : ln) {
		m += n.getCtrPos().x;
	}
	return m / ln.size();
}

-(int) barycenter(List<AbstractBox<?>> ln) {
	if (ln.size() == 0) {
		return 0;
	} else {
		double bc = 0;
		for (AbstractBox<?> n : ln) {
			bc += n.getIndex();
		}
		return (int) round(bc / ln.size());
	}
}

List<AbstractBox<?>> getConnectedTo(AbstractBox<?> n1, int layerIndex) {
	List<AbstractBox<?>> ln = new LinkedList<AbstractBox<?>>();
	if (layerIndex < layers.size() && layerIndex >= 0) {
		for (AbstractBox<?> n2 : layers.get(layerIndex)) {
			if (n1.isConnectedTo(n2)) {
				ln.add(n2);
			}
		}
	}
	return ln;
}

int getLayer(AbstractBox<?> n) {
	Integer l = nodeMap.get(n);
	if (l == null) {
		return 0;
	} else {
		return l;
	}
}

void init(int height, int nodeQty) {
	layers = new ArrayList<List<AbstractBox<?>>>(height);
	for (int i = 0; i < height; i++) {
		layers.add(new ArrayList<AbstractBox<?>>(nodeQty / height + 1));
	}
	nodeMap = new HashMap<AbstractBox<?>, Integer>(nodeQty);
}

void initIndexes() {
	for (List<AbstractBox<?>> l : layers) {
		Collections.sort(l, new Comparator<AbstractBox<?>>() {
			public int compare(AbstractBox<?> n1, AbstractBox<?> n2) {
				return n1.getIndex() - n2.getIndex();
			}
		});
		setOrderedIndexes(l);
	}
}

void layerHeights() {
	double offset = 0d;
	for (int l = 0; l < layers.size(); l++) {
		List<AbstractBox<?>> ln = layers.get(l);
		double maxh = maxHeight(ln);
		for (AbstractBox<?> n : ln) {
			if (n.isVirtual()) {
				n.setPos(n.getPos().x, offset + maxHeight(ln) / 2d);
			} else {
				n.setPos(n.getPos().x, offset);
			}
		}
		offset += maxh + Y_SEP;
	}
}

double maxHeight(List<AbstractBox<?>> ln) {
	double mh = 0d;
	for (AbstractBox<?> n : ln) {
		mh = max(mh, n.getSize().y);
	}
	return mh;
}

void reduceCrossings() {
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

void reduceCrossings2L(int staticIndex, int flexIndex) {
	final List<AbstractBox<?>> flex = layers.get(flexIndex);
	for (AbstractBox<?> n : flex) {
		List<AbstractBox<?>> neighbors = getConnectedTo(n, staticIndex);
		n.setIndex(barycenter(neighbors));
	}
	Collections.sort(flex, new Comparator<AbstractBox<?>>() {
		public int compare(AbstractBox<?> n1, AbstractBox<?> n2) {
			return n1.getIndex() - n2.getIndex();
		}
	});
	setOrderedIndexes(flex);
}

void setOrderedIndexes(List<AbstractBox<?>> ln) {
	for (int i = 0; i < ln.size(); i++) {
		ln.get(i).setIndex(i);
	}
}

@Override
public String toString() {
	StringBuilder sb = new StringBuilder(getClass().getSimpleName());
	sb.append("(").append(layers.size()).append(")");
	int lc = 0;
	for (List<AbstractBox<?>> l : layers) {
		sb.append("\n\t").append(lc++).append(" # ").append(l);
	}
	return sb.toString();
}

void xPos() {
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

void xPosDown(int staticIndex, int flexIndex) {
	List<AbstractBox<?>> flex = layers.get(flexIndex);
	for (int i = 0; i < flex.size(); i++) {
		AbstractBox<?> n = flex.get(i);
		double min = i > 0 ? flex.get(i - 1).getPos().x + flex.get(i - 1).getSize().x + X_SEP : -Double.MAX_VALUE;
		List<AbstractBox<?>> neighbors = getConnectedTo(n, staticIndex);
		double avg = avgX(neighbors);
		if (!Double.isNaN(avg)) {
			n.setPos(max(min, avg - n.getSize().x / 2d), n.getPos().y);
		}
	}
}

void xPosPack(int flexIndex) {
	List<AbstractBox<?>> flex = layers.get(flexIndex);
	double offset = 0d;
	for (AbstractBox<?> n : flex) {
		n.setPos(offset, n.getPos().y);
		offset = n.getPos().x + n.getSize().x + X_SEP;
	}
}

void xPosUp(int staticIndex, int flexIndex) {
	List<AbstractBox<?>> flex = layers.get(flexIndex);
	for (int i = flex.size() - 1; i > -1; i--) {
		AbstractBox<?> n = flex.get(i);
		double min = i > 0 ? flex.get(i - 1).getPos().x + flex.get(i - 1).getSize().x + X_SEP : -Double.MAX_VALUE;
		double max = i < flex.size() - 1 ? flex.get(i + 1).getPos().x - n.getSize().x - X_SEP : Double.MAX_VALUE;
		List<AbstractBox<?>> neighbors = getConnectedTo(n, staticIndex);
		double avg = avgX(neighbors);
		if (!Double.isNaN(avg)) {
			n.setPos(max(min, min(max, avg - n.getSize().x / 2d)), n.getPos().y);
		}
	}
}

}

/*
 * 
 * 
 * double barycenterX(double def, List<AbstractBox<?>> ln) { if (ln.size() == 0)
 * { return def; } else { double bc = 0; for (AbstractBox<?> n : ln) { bc +=
 * n.getCtrPos().x; } return bc / ln.size(); } }
 * 
 * void xPositions() { double maxx = 0; double x[] = new double[layers.size()];
 * for (int l = 0; l < layers.size(); l++) { double currOffset = 0d; for
 * (AbstractBox<?> n : layers.get(l)) { currOffset += n.getSize().x +
 * xSeparation; } x[l] = currOffset - xSeparation; maxx = max(maxx, x[l]); } for
 * (int l = 0; l < layers.size(); l++) { double currOffset = (maxx - x[l]) / 2d;
 * for (AbstractBox<?> n : layers.get(l)) { n.getPos().x = currOffset;
 * currOffset += n.getSize().x + xSeparation; } } }
 * 
 * 
 * void adjustPosX(int staticLayer1, int flexLayer, int staticLayer2) {
 * List<AbstractBox<?>> flex = layers.get(flexLayer); double currOffset = 0d;
 * for (AbstractBox<?> n : flex) { List<AbstractBox<?>> neighbors1 =
 * getConnectedTo(n, staticLayer1); List<AbstractBox<?>> neighbors2 =
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
 * void xPosDown(int staticIndex, int flexIndex) { List<AbstractBox<?>> flex =
 * layers.get(flexIndex); double offset = 0d; for (AbstractBox<?> n : flex) {
 * List<AbstractBox<?>> neighbors = getConnectedTo(n, staticIndex); n.getPos().x
 * = max(offset, maxX(neighbors) - n.getSize().x / 2d); offset = n.getPos().x +
 * n.getSize().x + xSeparation; } }
 * 
 * void xPosUp(int staticIndex, int flexIndex) { List<AbstractBox<?>> flex =
 * layers.get(flexIndex); double offset = Double.MAX_VALUE; for (int i =
 * flex.size() - 1; i >= 0; i--) { AbstractBox<?> n = flex.get(i);
 * List<AbstractBox<?>> neighbors = getConnectedTo(n, staticIndex); if
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
 * double maxX(List<AbstractBox<?>> ln) { double m = -Double.MAX_VALUE; for
 * (AbstractBox<?> n : ln) { m = max(n.getCtrPos().x, m); } return m; }
 * 
 * double minX(List<AbstractBox<?>> ln) { double m = Double.MAX_VALUE; for
 * (AbstractBox<?> n : ln) { m = min(n.getCtrPos().x, m); } return m; }
 */


@end
