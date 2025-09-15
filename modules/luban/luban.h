#pragma once

#include "core/object/ref_counted.h"
#include "Code/schema.h"

class Luban : public RefCounted
{
	GDCLASS(Luban, RefCounted);

private:
	cfg::Tables tables;

protected:
	static void _bind_methods();

public:
	int get_actor_attr(String actor_name, int attr_index);
	Array get_base_attrs();

	Luban();
};
