# SimpleLuaTable
An AS3 class. Encode AS3 object to Lua table. Decode Lua table string to AS3 object.

###Input and output example
AS3 object:
```as3
var as3Obj = new Object();
as3Obj["name"] = "foo";
```

<--->

Lua string:
```lua
return {
    name = "foo",
}
```

Limit: Not support array mixed table, like {a = 1, "a", 123, true}.
This class maybe overengineer. To encode Lua, just create a JSON, replace "[]:" to "{}=" and insert a "return" before the string. Limit is same.

## Useage
```as3
// Encode
var luaTableString : String = SimpleLuaTable.encode(fooAS3Obj, true);

// Decode
var fooAs3Obj : Object = SimpleLuaTable.decode(luaTableString);  

```
