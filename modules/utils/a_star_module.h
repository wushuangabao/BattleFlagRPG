#pragma once

#include "core/templates/hash_map.h"
#include "core/templates/hash_set.h"

#include "core/math/vector2i.h"
#include "core/variant/variant.h"

class AStarWithBias
{
public:
    // 对外统一接口
    static PackedVector2Array a_star(const Vector2i& start,
        const Vector2i& goal,
        const Vector2i& dir_start,
        const Callable& is_walkable);

private:
    // 参考实现：曼哈顿启发
    static inline int heuristic(const Vector2i& a, const Vector2i& b) {
        return Math::abs(a.x - b.x) + Math::abs(a.y - b.y);
    }

    // 4 邻居
    static inline void neighbors4(const Vector2i& p, Vector2i out[4]) {
        out[0] = Vector2i(p.x + 1, p.y);
        out[1] = Vector2i(p.x - 1, p.y);
        out[2] = Vector2i(p.x, p.y + 1);
        out[3] = Vector2i(p.x, p.y - 1);
    }

    // 步进方向的单位向量（4 邻域，优先较大的轴）
    static inline Vector2i clamp_to_4dir(const Vector2i& from, const Vector2i& to) {
        Vector2i d = to - from;
        int dx = (d.x == 0) ? 0 : (d.x > 0 ? 1 : -1);
        int dy = (d.y == 0) ? 0 : (d.y > 0 ? 1 : -1);
        if (Math::abs(d.x) >= Math::abs(d.y)) {
            return Vector2i(dx, 0);
        } else {
            return Vector2i(0, dy);
        }
    }

    // 回溯路径
    static PackedVector2Array reconstruct(const HashMap<Vector2i, Vector2i>& came,
        Vector2i current,
        const Vector2i& start);

    // 用于优先队列的条目
    struct OpenNode {
        Vector2i node;
        int f = 0;
        int angle_bias = 0;
        Vector2i parent; // 父节点位置
        Vector2i parent_dir; // last_dir[parent]，用于 tie-break（更直优先）

        // 比较器：注意 priority_queue 默认取“最大”，我们反转逻辑以便最小优先
        struct Cmp {
            bool operator()(const OpenNode& a, const OpenNode& b) const {
                // 第一优先级：f值小的优先
                if (a.f != b.f) return a.f > b.f;
                
                // 第二优先级：angle_bias小的优先
                if (a.angle_bias != b.angle_bias) return a.angle_bias > b.angle_bias;
                
                // 第三优先级：偏好直线移动（严格参照 GDScript 的比较式）
                // 注意：脚本中是 last_dir[came[a]] == a - came[a]
                // 其中 last_dir 存的是格子坐标，而 a - came[a] 是方向向量。
                // 我们照搬这个“非对称”判定以匹配脚本行为。
                Vector2i step_a = a.node - a.parent;
                Vector2i step_b = b.node - b.parent;
                bool straight_a = (a.parent_dir == step_a);
                bool straight_b = (b.parent_dir == step_b);
                if (straight_a != straight_b) {
                    return !straight_a; // a 不直线则认为 a 优先级更低
                }
                return false;
            }
        };
    };
};