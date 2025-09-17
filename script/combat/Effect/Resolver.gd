class_name Resolver

# 负责检定命中 → 暴击 → 伤害 → 应用Effect列表
# 标签系统贯穿：单位、技能、效果、Buff、武器都带 tags，resolver 可基于 tags 注入特判（例如“对中毒目标+20%伤害”）
