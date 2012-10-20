//
//  SugiyamaLayout.h
//  drawify
//
//  Created by Damian Stewart on 12.08.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#pragma once

#import "Graph.h"

#ifdef __cplusplus
extern "C"
#endif
/// Graph should be make up of PositionedGraphNode rather than GraphNode
/// Returns 1 on success, 0 on fail
int sugiyamaLayout( Graph* graphToLayout );
