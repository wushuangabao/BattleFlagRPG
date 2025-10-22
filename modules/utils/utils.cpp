#include "a_star_module.h"
#include "utils.h"

void Utils::_bind_methods() {
    ClassDB::bind_static_method("Utils", D_METHOD("a_star", "start", "goal", "dir_start", "is_walkable"), &AStarWithBias::a_star);
}