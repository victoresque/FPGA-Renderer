#include "renScene.h"

renScene* renInitScene() {
    renScene* scene;
    scene = (renScene*) malloc(sizeof(renScene));

    return scene;
}

