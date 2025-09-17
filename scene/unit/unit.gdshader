shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_test_disabled;
// 渲染模式说明：
// unshaded 无阴影渲染，确保精灵不受光照影响
// blend_mix 混合模式，确保精灵的透明部分与背景正确混合
// cull_disabled 禁用面剔除，确保所有面都被渲染
// depth_test_disabled 禁用深度测试，确保精灵始终显示在最前面，不被任何物体遮挡

uniform sampler2D u_frame_tex;
// 轮廓发光参数
uniform vec4 outline_color : source_color = vec4(1.0, 0.9, 0.8, 0.75); // 轮廓颜色
uniform bool enable_outline = false; // 启用轮廓效果
uniform float outline_width : hint_range(0.0, 10.0) = 2.0; // 轮廓宽度
uniform float outline_intensity : hint_range(0.0, 3.0) = 1.0; // 轮廓强度
uniform float glow_strength : hint_range(0.0, 5.0) = 2.0; // 发光强度倍数
uniform float outer_glow_range : hint_range(1.0, 5.0) = 3.0; // 外层发光范围
uniform float inner_glow_falloff : hint_range(0.1, 2.0) = 0.3; // 内层发光衰减率
uniform float outer_glow_falloff : hint_range(0.1, 1.0) = 0.15; // 外层发光衰减率

// 纹理颜色混合参数
uniform bool enable_color_tint = false; // 启用颜色混合
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // 混合颜色
uniform float tint_strength : hint_range(0.0, 1.0) = 0.5; // 混合强度

// 模拟 billboard 效果
void vertex() {
    // 获取模型的世界位置
    vec3 world_position = MODEL_MATRIX[3].xyz;
    
    // 获取摄像机的右向量和上向量（从逆视图矩阵中提取）
    vec3 camera_right = normalize(INV_VIEW_MATRIX[0].xyz);
    vec3 camera_up = normalize(INV_VIEW_MATRIX[1].xyz);
    
    // 获取原始缩放
    vec3 scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
    
    // 计算billboard顶点位置
    // 考虑项目统一的offset(0, 32)设置，VERTEX已经包含了正确的偏移
    vec3 billboard_position = world_position + 
                             camera_right * VERTEX.x * scale.x + 
                             camera_up * VERTEX.y * scale.y;
    
    // 转换到视图空间
    POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(billboard_position, 1.0);
}

void fragment() {
	vec4 tex = texture(u_frame_tex, UV);
	
	// 基本颜色处理
	vec4 final_color = tex;
	vec3 emission = vec3(0.0);
	
	// 纹理颜色混合处理
	if (enable_color_tint && tex.a > 0.1) {
		// 将原始颜色与混合颜色按强度混合
		final_color.rgb = mix(final_color.rgb, tint_color.rgb, tint_strength);
		// 可选：添加轻微的发光效果
		emission = tint_color.rgb * tint_strength * 0.3;
	}
	
	// 强化的发光轮廓效果
	if (enable_outline) {
		vec2 tex_size = vec2(textureSize(u_frame_tex, 0));
		vec2 pixel_size = 1.0 / tex_size;

		float inner_glow = 0.0;
		float outline_alpha = 0.0;
		
		// 内层发光 - 检测边缘像素
		int inner_range = int(ceil(outline_width));
		for (int x = -inner_range; x <= inner_range; x++) {
			for (int y = -inner_range; y <= inner_range; y++) {
				if (x == 0 && y == 0) continue;
				
				float distance = length(vec2(float(x), float(y)));
				if (distance > outline_width) continue;
				
				vec2 offset = vec2(float(x), float(y)) * pixel_size;
				float sample_alpha = texture(u_frame_tex, UV + offset).a;
				
				// 根据距离计算发光强度，使用可调节的衰减
				float weight = 1.0 / (1.0 + distance * inner_glow_falloff);
				inner_glow += sample_alpha * weight;
				outline_alpha = max(outline_alpha, sample_alpha);
			}
		}
		
		// 外层发光 - 更大范围的柔和发光
		float outer_glow = 0.0;
		int outer_range = int(ceil(outer_glow_range));
		for (int x = -outer_range; x <= outer_range; x++) {
			for (int y = -outer_range; y <= outer_range; y++) {
				float distance = length(vec2(float(x), float(y)));
				if (distance <= outline_width || distance > outer_glow_range) continue;
				
				vec2 offset = vec2(float(x), float(y)) * pixel_size;
				float sample_alpha = texture(u_frame_tex, UV + offset).a;
				
				// 外层发光衰减，使用可调节的衰减率
				float weight = 1.0 / (1.0 + distance * distance * outer_glow_falloff);
				outer_glow += sample_alpha * weight;
			}
		}
		
		// 如果当前像素透明但周围有内容，创建轮廓
		if (tex.a <= 0.2 && outline_alpha > 0.1) {
			// 强烈的轮廓发光
			final_color = outline_color;
			final_color.a = min(1.0, outline_alpha * outline_intensity);
			
			// 添加强烈的发射光
			emission = outline_color.rgb * outline_intensity * glow_strength;
		} 
		// 如果是不透明像素
		else if (tex.a > 0.2) {
			// 检查是否靠近边缘
			bool is_edge = false;
			for (int x = -1; x <= 1; x++) {
				for (int y = -1; y <= 1; y++) {
					if (x == 0 && y == 0) continue;
					vec2 offset = vec2(float(x), float(y)) * pixel_size;
					if (texture(u_frame_tex, UV + offset).a < 0.1) {
						is_edge = true;
						break;
					}
				}
				if (is_edge) break;
			}
			
			// 边缘像素增强发光
			if (is_edge) {
				// 混合轮廓颜色到原色
				float mix_factor = 0.3 * outline_intensity;
				final_color.rgb = mix(final_color.rgb, outline_color.rgb, mix_factor);
				// 强烈的边缘发光
				emission = outline_color.rgb * outline_intensity * glow_strength * 0.8;
			}
			// 内部像素也有轻微发光
			else if (inner_glow > 0.1) {
				emission = outline_color.rgb * outline_intensity * glow_strength * 0.2;
			}
		}
		// 透明区域的外层发光
		else if (outer_glow > 0.02) {
			final_color = outline_color;
			final_color.a = min(0.8, outer_glow * outline_intensity * 0.5);
			emission = outline_color.rgb * outline_intensity * glow_strength * 0.6;
		}
	}
	
	// 丢弃完全透明的像素
	if (final_color.a < 0.01) {
		discard;
	}
	
	ALBEDO = final_color.rgb;
	ALPHA = final_color.a;
	EMISSION = emission;
}