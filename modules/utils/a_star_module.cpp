#include <queue>

#include "a_star_module.h"

const float align_weight = 0.02f;
const float turn_weight = 0.001f;
const Vector2i Vector2i_ZERO = Vector2i(0, 0);

PackedVector2Array AStarWithBias::a_star(const Vector2i& start,
                                         const Vector2i& goal,
                                         const Vector2i& dir_start,
                                         const Callable& is_walkable) {
    Vector2i dir_to_goal = goal - start;
    if (dir_to_goal == Vector2i_ZERO) {
        return PackedVector2Array();
    }

    HashMap<Vector2i, Vector2i> came;
    HashMap<Vector2i, int> g;
    HashMap<Vector2i, int> f;
    HashMap<Vector2i, float> angle_bias;
    HashMap<Vector2i, Vector2i> last_dir;

    std::priority_queue<OpenNode, std::vector<OpenNode>, OpenNode::Cmp> open;

    g[start] = 0;
    f[start] = heuristic(start, goal);
    angle_bias[start] = 0.0f;
    last_dir[start] = dir_start;

    OpenNode start_node;
    start_node.node = start;
    start_node.f = f[start];
    start_node.angle_bias = angle_bias[start];
    start_node.parent = start; // 起始节点的父节点设为自己
    start_node.parent_dir = dir_start;
    open.push(start_node);

    while (!open.empty()) {
        OpenNode current_node = open.top();
        open.pop();
        Vector2i current = current_node.node;

        // 跳过过期条目（队列中可能存在旧优先级的重复项）
        if (f.has(current) && current_node.f != f[current]) continue;
        if (angle_bias.has(current) && current_node.angle_bias != angle_bias[current]) continue;

        if (current == goal) {
            return reconstruct(came, current, start);
        }

        Vector2i neighbors[4];
        neighbors4(current, neighbors);

        for (int i = 0; i < 4; i++) {
            Vector2i n = neighbors[i];

            Variant args[1] = { Variant(n) };
            const Variant* argptrs[1] = { &args[0] };
            Callable::CallError call_error;
            Variant result;
            is_walkable.callp(argptrs, 1, result, call_error);
            if (call_error.error != Callable::CallError::CALL_OK || !result.operator bool()) {
                continue;
            }

            int tentative_g = g[current] + 1;
            
            dir_to_goal = goal - n;
            float align_cos = 0.0f;
            if (dir_to_goal != Vector2i_ZERO) {
                Vector2 dir_to_goal_norm = Vector2(dir_to_goal).normalized();
                Vector2 dir_from_start_norm = Vector2(n - start).normalized();
                align_cos = dir_from_start_norm.dot(dir_to_goal_norm);
            }

            Vector2i dir = clamp_to_4dir(current, n); // 单位方向向量（4邻域）
            Vector2i prev_dir = last_dir.has(current) ? last_dir[current] : Vector2i(0, 0);
            bool is_turn = (prev_dir != Vector2i_ZERO && dir != Vector2i_ZERO && prev_dir != dir);
            float turn_penalty = (current == start) ? (is_turn ? turn_weight : 0.0f) : (is_turn ? 0.0f : turn_weight);

            float current_angle_acc = angle_bias.has(current) ? angle_bias[current] : 0.0f;
            float tentative_angle = current_angle_acc - align_cos * align_weight + turn_penalty;

            bool better = false;
            int old_g = g.has(n) ? g[n] : (1 << 30);
            if (tentative_g < old_g) {
                better = true;
            } else if (tentative_g == old_g) {
                float old_angle = angle_bias.has(n) ? angle_bias[n] : 1e9f;
                if (tentative_angle < old_angle) {
                    better = true;
                }
            }

            if (better) {
                came[n] = current;
                g[n] = tentative_g;
                f[n] = tentative_g + heuristic(n, goal);
                angle_bias[n] = tentative_angle;
                last_dir[n] = dir;

                OpenNode new_node;
                new_node.node = n;
                new_node.f = f[n];
                new_node.angle_bias = angle_bias[n];
                new_node.parent = current;
                new_node.parent_dir = prev_dir;
                open.push(new_node);
            }
        }
    }

    return PackedVector2Array();
}

PackedVector2Array AStarWithBias::reconstruct(const HashMap<Vector2i, Vector2i>& came, Vector2i current, const Vector2i& start)
{
    // 回溯
    PackedVector2Array path;
    // 先用临时容器逆序收集
    std::vector<Vector2i> rev;
    rev.push_back(current);

    // Using HashMap API: find returns Iterator
    auto it = came.find(current);
    while (it) {
        current = it->value;
        rev.push_back(current);
        if (current == start) break;
        it = came.find(current);
    }

    // 反转
    for (int i = static_cast<int>(rev.size()) - 1; i >= 0; --i) {
        path.push_back(rev[i]);
    }
    return path;
}