#pragma once

#include "core/io/resource_loader.h"
#include "Code/schema.h"

class ResourceFormatLoaderBytes : public ResourceFormatLoader {
	GDCLASS(ResourceFormatLoaderBytes, ResourceFormatLoader);
public:
	virtual Ref<Resource> load(const String& p_path, const String& p_original_path, Error* r_error = NULL);
	virtual void get_recognized_extensions(List<String>* r_extensions) const;
	virtual bool handles_type(const String& p_type) const;
	virtual String get_resource_type(const String& p_path) const;
};