#include "register_types.h"

#include "core/object/class_db.h"
#include "luban.h"
#include "ResourceLoaderBytes.h"

static Ref<ResourceFormatLoaderBytes> bytes_loader;

void initialize_luban_module(ModuleInitializationLevel p_level) {
	if (p_level == MODULE_INITIALIZATION_LEVEL_EDITOR) {
		bytes_loader.instantiate();
		ResourceLoader::add_resource_format_loader(bytes_loader);
	}
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
	ClassDB::register_class<Luban>();
}

void uninitialize_luban_module(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_EDITOR) {
		ResourceLoader::remove_resource_format_loader(bytes_loader);
		bytes_loader.unref();
	}

	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
	// Nothing to do here in this example.
}