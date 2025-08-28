using Godot;
using Luban;                   // Luban 运行时库
using cfg;                     // Luban 生成代码的命名空间

public partial class DataService : Node
{
	private Tables _tables;

	public override void _Ready()
	{
		// 一次性加载全部配置（也可改成延迟加载：把 _tables = new Tables(LoadByteBuf) 放到需要的时机
		_tables = new Tables(LoadByteBuf);
		GD.Print($"Luban tables loaded. Item 1: {_tables.Tbitem.Get(1001).Name}"); // 举例
	}

	// Luban 约定的加载函数：给定表名，返回该表的二进制 ByteBuf
	private ByteBuf LoadByteBuf(string file)
	{
		var path = $"res://luban/Table/{file}.bytes"; // 你的输出扩展名可能是 .bin，自行对应
		using var f = FileAccess.Open(path, FileAccess.ModeFlags.Read);
		f.Seek(0);
		var bytes = f.GetBuffer((long)f.GetLength());
		return new ByteBuf(bytes);
	}

	// === 以下是给 GDScript 用的查询接口 ===
	// 方式A：返回具体字段（性能最佳，跨语言开销最小）
	public string GetItemName(int id)
	{
		var row = _tables.Tbitem.Get(id);
		if (row == null)
		{
			GD.PushWarning($"[Luban] TbItem 没有 id={id}。");
			return "";
		}
		return row.Name;
	}

	// 方式B：需要更通用时，转成 GDScript 友好的 Dictionary/Array
	public Godot.Collections.Dictionary GetItemAsDict(int id)
	{
		var row = _tables.Tbitem.GetOrDefault(id);
		var d = new Godot.Collections.Dictionary();
		if (row == null) return d;
		d["Id"] = row.Id;
		d["Name"] = row.Name;
		d["Desc"] = row.Desc;
		// …按你的表结构补充字段
		return d;
	}
}
