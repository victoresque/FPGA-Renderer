//
//  objLoader.h
//  render
//
//  Created by Victor Huang on 5/13/17.
//  Copyright © 2017 Victor Huang. All rights reserved.
//

#ifndef objLoader_h
#define objLoader_h

#include <stdio.h>
#include "tinyobj_loader_c.h"
#include "../REN/renObject.h"

renObject* objLoad(const char* filepath);
renObject* objLoadSD(const char* filepath);

#endif /* objLoader_h */
