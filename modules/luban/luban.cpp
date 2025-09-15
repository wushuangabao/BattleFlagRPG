#include "luban.h"

int Luban::get_actor_attr(String actor_name, int attr_index)
{
	auto attrs = tables.TbActorBaseAttr.get("test_actor");
	if (attrs)
	{
		switch (attr_index)
		{
			case 0:
				return attrs->STR;
			case 1:
				return attrs->CON;
			case 2:
				return attrs->AGI;
			case 3:
				return attrs->WIL;
			case 4:
				return attrs->INT;
			default:
				return 0;
		}
	}
	return 0;
}

Array Luban::get_base_attrs()
{
	auto& list = tables.TbBaseAttr.getDataList();
	Array ret;
	ret.resize(list.size());
	for (int i = 0; i < list.size(); i++)
	{
		Dictionary d;
		auto attr = list[i];
		d["key"] = attr->key.c_str();
		d["name"] = attr->name.c_str();
		d["desc"] = attr->desc.c_str();
		d["HP"] = attr->HP;
		d["MP"] = attr->MP;
		d["ATKp"] = attr->ATKp;
		d["ATKm"] = attr->ATKm;
		d["DEFp"] = attr->DEFp;
		d["DEFm"] = attr->DEFm;
		d["CR"] = attr->CR;
		d["CD"] = attr->CD;
		d["PAR"] = attr->PAR;
		d["PDR"] = attr->PDR;
		d["HIT"] = attr->HIT;
		d["EVA"] = attr->EVA;
		d["SPD"] = attr->SPD;
		d["PenP"] = attr->PenP;
		d["PenM"] = attr->PenM;
		d["CTR"] = attr->CTR;
		d["RES"] = attr->RES;
		ret[i] = d;
	}
	return ret;
}

void Luban::_bind_methods()
{
	ClassDB::bind_method(D_METHOD("get_actor_attr", "actor_name", "attr_index"), &Luban::get_actor_attr);
	ClassDB::bind_method(D_METHOD("get_base_attrs"), &Luban::get_base_attrs);
}

Luban::Luban()
{
	if (tables.load(
		[](::luban::ByteBuf& buf, const std::string& s) {
			return buf.loadFromFile("modules/luban/Table/" + s + ".bytes");
		})
	)
		print_line("== luban data load succ ==");
	else
		ERR_PRINT("== luban data load fail ==");
}
