#pragma once

#include "core/object/ref_counted.h"

class Utils : public RefCounted
{
	GDCLASS(Utils, RefCounted)

protected:
	static void _bind_methods();
};