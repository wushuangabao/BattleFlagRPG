#include "ResourceLoaderBytes.h"

//#include "resource_json.h"

Ref<Resource> ResourceFormatLoaderBytes::load(const String& p_path, const String& p_original_path, Error* r_error) {
    // 临时返回空引用
    if (r_error) {
        *r_error = OK;
    }
    return Ref<Resource>();
}

void ResourceFormatLoaderBytes::get_recognized_extensions(List<String>* r_extensions) const {
	if (!r_extensions->find("bytes")) {
		r_extensions->push_back("bytes");
	}
}

String ResourceFormatLoaderBytes::get_resource_type(const String& p_path) const {
	return "Resource";
}

bool ResourceFormatLoaderBytes::handles_type(const String& p_type) const {
	return ClassDB::is_parent_class(p_type, "Resource");
}