class_name EffectBase extends Resource

enum EffectType {
	Damage, Heal, AddBuff, Cure, Move, Spwan, Custom
}

var my_type : EffectType

var target : ActorController