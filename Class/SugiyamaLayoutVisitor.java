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

package org.modsl.core.agt.layout.sugiyama;

import static java.lang.Math.max;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.modsl.core.agt.layout.AbstractLayoutVisitor;
import org.modsl.core.agt.model.Bend;
import org.modsl.core.agt.model.Edge;
import org.modsl.core.agt.model.Graph;
import org.modsl.core.agt.model.Node;
import org.modsl.core.util.ModSLException;


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
 */
public class SugiyamaLayoutVisitor extends AbstractLayoutVisitor {
	
    Graph graph;
    SugiyamaLayerStack stack = new SugiyamaLayerStack();
	
    @Override
    public void apply(Graph graph) {
        this.graph = graph;
        removeCycles();
        splitIntoLayers();
        insertDummies();
        stack.initIndexes();
        stack.reduceCrossings();
        undoRemoveCycles();
        stack.layerHeights();
        stack.xPos();
        // log.debug(new ToStringVisitor().toString(graph));
    }
	
    void insertDummies() {
        for (Edge currEdge : new ArrayList<Edge>(graph.getEdges())) {
            int fromLayer = stack.getLayer(currEdge.getNode1());
            int toLayer = stack.getLayer(currEdge.getNode2());
            if (toLayer - fromLayer > 1) {
                for (int layer = fromLayer + 1; layer < toLayer; layer++) {
                    Bend b = new Bend();
                    currEdge.add(b);
                    stack.add(b, layer);
                }
            }
        }
    }
	
    void splitIntoLayers() {
        List<Node> sorted = topologicalSort();
        Map<Node, Integer> lmap = new HashMap<Node, Integer>();
        for (Node n : sorted) {
            lmap.put(n, 0);
        }
        int h = 1;
        for (Node n1 : sorted) {
            for (Edge out : n1.getOutEdges()) {
                Node n2 = out.getNode2();
                int inc = dup(out) ? 2 : 1; // need to put nodes connected with
                // > 1 edge further away
                lmap.put(n2, max(lmap.get(n1) + inc, lmap.get(n2)));
                h = max(h, lmap.get(n2) + 1);
            }
        }
        stack.init(h, sorted.size());
        for (Node n : sorted) {
            stack.add(n, lmap.get(n));
        }
    }
	
    boolean dup(Edge e1) {
        for (Edge e2 : e1.getParent().getEdges()) {
            if (!e2.equals(e1)
				&& ((e1.getNode1().equals(e2.getNode1()) && e1.getNode2().equals(e2.getNode2())) || (e1.getNode2().equals(
																														  e2.getNode1()) && e1.getNode1().equals(e2.getNode2())))) {
                return true;
            }
        }
        return false;
    }
	
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
	
    List<Node> sortByOutDegree() {
        List<Node> nodes = new ArrayList<Node>(graph.getNodes());
        Collections.sort(nodes, new Comparator<Node>() {
            public int compare(Node n1, Node n2) {
                return n2.getOutDegree() - n1.getOutDegree();
            }
        });
        return nodes;
    }
	
    List<Node> sortByInMinusOutDegree() {
        List<Node> nodes = new ArrayList<Node>(graph.getNodes());
        Collections.sort(nodes, new Comparator<Node>() {
            public int compare(Node n1, Node n2) {
                return (n1.getInDegree() * 2 - n1.getOutDegree()) - (n2.getInDegree() * 2 - n2.getOutDegree());
            }
        });
        return nodes;
    }
	
    List<Node> sources() {
        List<Node> sources = new LinkedList<Node>();
        for (Node n : graph.getNodes()) {
            if (n.getInDegree() == 0) {
                sources.add(n);
            }
        }
        return sources;
    }
	
    List<Node> topologicalSort() {
        List<Node> q = sources();
        List<Node> l = new ArrayList<Node>(this.graph.getNodes().size());
        List<Edge> r = new ArrayList<Edge>(this.graph.getEdges().size()); // removed
        // edges
        while (q.size() > 0) {
            Node n = q.remove(0);
            l.add(n);
            for (Edge e : n.getOutEdges()) {
                Node m = e.getNode2();
                r.add(e); // removing edge from the graph
                boolean allEdgesRemoved = true;
                // then checking if the target has any more "in" edges left
                for (Edge e2 : m.getInEdges()) {
                    if (!r.contains(e2)) {
                        allEdgesRemoved = false;
                    }
                }
                if (allEdgesRemoved) {
                    q.add(m);
                }
            }
        }
        if (graph.getNodes().size() != l.size()) {
            throw new ModSLException("Topological sort failed for " + graph + " in Sugiyama layout, " + graph.getNodes().size()
									 + " total nodes, " + l.size() + ", sorted nodes, remaining nodes: " + q);
        }
        return l;
    }
	
    void undoRemoveCycles() {
        for (Edge e : graph.getEdges()) {
            e.setReverted(false);
        }
    }
	
}