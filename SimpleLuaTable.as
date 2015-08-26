package
{
	import flash.utils.describeType;
	import flash.utils.getQualifiedClassName;

	/*
	* 
	Limit: Not support array mixed table, like {a = 1, "a", 123, true}.
	This class maybe overengineer. To encode Lua, just create a JSON, replace "[]:" to "{}=" and insert a "return" before the string. Limit is same.
	
	TODO:
	Use ["field"]="xx" replace field="xx".

	*/
	public class SimpleLuaTable
	{
		private static var _operatorStack : Vector.<String>;
		private static var _itemStack : Vector.<Object>;
		private static var _luaText : String = "";
		private static var _textPos : int = 0;
		
		private static var _result : String;
		private static var _isPretty : Boolean = false;
		
		public function SimpleLuaTable()
		{
			trace(1);
		}
		
		static public function decode(luaString : String) : Object
		{
			_operatorStack = new Vector.<String>;
			_itemStack = new Vector.<Object>;
			_luaText = luaString;
			// Get first '{'
			_textPos = 0;
			var count : int = _luaText.length;
			while(_textPos < count)
			{
				var ch : String = _luaText.substr(_textPos, 1)
				if (ch == '{') {
					_operatorStack.push(ch);
					return decodeTable();
				}
				_textPos ++;
			}
			return null;
		}
		
		public static function encode(as3Obj : Object, isPretty : Boolean = false) : String
		{
			_result = "return";
			_isPretty = isPretty;
			if (_isPretty)
				_result += ' ';
			
			var depth : int = 0;
			encodeTable(as3Obj, depth);
			
			return  _result;
		}
		
		private static function encodeTable(as3Obj : Object, depth : int) : void
		{
			depth ++;
			var qname : String = getQualifiedClassName(as3Obj);
			if ("__AS3__.vec::Vector" == qname.substr(0, 19))
			{
				_result += '{';
				// If the Object has item's item, it's will be "{{"
				var itemCount : int = 0;
				for(var i : String in as3Obj)
				{
					for (var j : String in as3Obj)
					{
						itemCount ++;
						break;
					}
					if (itemCount > 0)
						break;
				}
				var vecCount : int = 0;
				for (var v : String in as3Obj)
				{
					vecCount ++;
				}
				if (itemCount > 0)
				{
					var index : int;
					for each(var obj : Object in as3Obj)
					{
						if (!isObjectRaw(as3Obj))
						{
							_result += '\n';
							_result += getRightShif(depth);
						}
						if (obj == null) 
						{
							_result += 'null';
						}
						else
						{
							encodeTable(obj, depth);
						}
						index ++;
						if (index != vecCount)
						{
							_result += ',';
						}
					}
				}
				else
				{
					for each(obj in as3Obj)
					{
						_result += encodeItem(obj);
						index ++;
						if (index != vecCount)
						{
							_result += ',';
						}
					}
				}
				if (!isObjectRaw(as3Obj))
				{
					_result += '\n';
					_result += getRightShif(depth);
				}
				_result += '}';
			}
			else if ("number" == typeof(as3Obj) || "string" == typeof(as3Obj) || "boolean" == typeof(as3Obj))
			{
				_result += encodeItem(as3Obj);
			}
			else	// Object
			{
				//Object
				var objIndex : int = 0;
				if ("Object" == qname)
				{
					var objCount : int = 0;
					for (var key : String in as3Obj)
					{
						objCount ++;
					}
					_result += '{';
					if (_isPretty && objCount > 1 && !isObjectRaw(as3Obj))
					{
						_result += '\n';
						_result += getRightShif(depth);
					}
					
					for(key in as3Obj)
					{
						if (as3Obj[key] == null)
						{
							objIndex ++;
							continue;
						}
						_result += (key + '=');
						itemCount = 0;
						
						encodeTable(as3Obj[key], depth);
	
						objIndex ++;
						if (objIndex != objCount)
						{
							_result += ',';
							if (_isPretty && !isObjectRaw(as3Obj))
							{
								_result += '\n';
								_result += getRightShif(depth);
							}
						}
					}
				}
				else	// User define Object
				{
					var varList : XMLList = flash.utils.describeType(as3Obj)..variable;
					
					objCount = 0;
					for (var xmlIndex : int = 0; xmlIndex < varList.length(); xmlIndex++)
					{
						objCount ++;
					}
					_result += '{';
					if (_isPretty && objCount > 1 && !isObjectRaw(as3Obj))
					{
						_result += '\n';
						_result += getRightShif(depth);
					}
					
					for (xmlIndex = 0; xmlIndex < varList.length(); xmlIndex++) {
						var objKey : String = varList[xmlIndex].@name;
						if (as3Obj[objKey] == null) {
							objIndex ++;
							continue;
						}
							
						_result += (objKey + '=');
						itemCount = 0;
						
						encodeTable(as3Obj[objKey], depth);

						objIndex ++;
						if (objIndex != objCount)
						{
							_result += ',';
							if (_isPretty && !isObjectRaw(as3Obj))
							{
								_result += '\n';
								_result += getRightShif(depth);
							}
						}
					}
				}
				//
				if (_isPretty && objCount > 1 && !isObjectRaw(as3Obj)) {
					_result += '\n';
					_result += getRightShif(depth - 1);
				}
				
				_result += '}';
			}
		}
		
		private static function encodeItem(as3Obj : Object) : String
		{
			if ("string" == typeof(as3Obj))
				return "\"" + as3Obj.toString() + "\"";
			else
				return as3Obj.toString();
		}
		
		// Is the object's item is raw type. (number, string, boolean)
		private static function isObjectRaw(obj : Object) : Boolean
		{
			var qname : String = getQualifiedClassName(obj);
			if ("Object" == qname || "__AS3__.vec::Vector" == qname.substr(0, 19))
			{
				for (var key : String in obj)
				{
					var type : String = typeof(obj[key]);
					if ("object" == type && obj[key] != null)
						return false;
				}
				return true;
			}
			else
			{
				var varList : XMLList = flash.utils.describeType(obj)..variable;
				for (var xmlIndex : int = 0; xmlIndex < varList.length(); xmlIndex++)
				{
					key = varList[xmlIndex].@name;
					type = typeof(obj[key]);
					if ("object" == type && obj[key] != null)
						return false;
				}
				return true;
			}
		}
		
		private static function getRightShif(depth : int) : String
		{
			var r : String = "";
			for (var depthIndex : int = 0; depthIndex < depth; depthIndex ++)
			{
				r += '\t';
			}
			return r;
		}
		
		private static function decodeTable() : Object
		{
			var table : Object = new Object();
			var count : int = _luaText.length;
			var tempValue : Object;
			var arrayIndex : int = 0;
			var tempStr : String = ""
			while(_textPos < count)
			{
				_textPos++;
				var ch : String = _luaText.substr(_textPos, 1);
				switch(ch)
				{
					case ' ':
					case '\n':
					case '\t':
						break;
					case ',':
						if (_operatorStack.length > 0 && '=' == _operatorStack[_operatorStack.length - 1])
						{
							_operatorStack.pop();
							table[_itemStack.pop()] = typeCheck(tempStr);
						}
						else if ('{' == _operatorStack[_operatorStack.length - 1])
						{
							if ("" != tempStr)
							{
								if (tempValue == null)
									tempValue = new Vector.<Object>;
								tempValue.push(typeCheck(tempStr));
							}
						}
						tempStr = "";
						break;
					case '=':
						_operatorStack.push(ch);
						_itemStack.push(tempStr);
						tempStr = "";
						break;
					case '}':
						if (tempStr == "2")
							trace(1)
						if (_operatorStack.length > 0 && '{' == _operatorStack[_operatorStack.length - 1])
						{
							_operatorStack.pop(); // "{"
							
							if (tempValue == null)
							{
								var tableCount : int = 0
								//-- This is for 1 item array: {23, 1, 4, {1}}
								for (var obj : Object in table)
								{
									tableCount++;
								}
								if (tableCount <= 0 && tempStr.length >= 0)
								{
									tempValue = new Vector.<Object>;
									tempValue.push(typeCheck(tempStr));
									return tempValue;
								}
								//--
								return table;
							}
							if("" != tempStr) {
								tempValue.push(typeCheck(tempStr)); // 
							}
							if (tempValue.length == 1)
								trace(1)
							return tempValue;
						}
						else if (_operatorStack.length > 0 && '=' == _operatorStack[_operatorStack.length - 1])
						{
							_operatorStack.pop(); // Pop '='
							_operatorStack.pop(); // Pop '{'
							table[_itemStack.pop()] = typeCheck(tempStr);
							return table;
						}
						else
						{
							trace("Input lua file is bad.");
							return null;
						}
						break;
					case '{':
						//Check arry
						_operatorStack.push(ch);
						var tobj : Object = decodeTable();
						if (_operatorStack.length > 0 && '=' == _operatorStack[_operatorStack.length - 1])
						{
							_operatorStack.pop(); // Pop '='
							table[_itemStack.pop()] = tobj;
							tempValue = null;
						}
						else if (_operatorStack.length > 0 && '{' == _operatorStack[_operatorStack.length - 1])
						{
							if (tempValue == null)
								tempValue = new Vector.<Object>();
							tempValue.push(tobj);
						}
						break;
					default:
						tempStr += ch;
						break;
				}
			}
			return table;
		}
		
		private static function typeCheck(tempStr : String) : Object
		{
			//		private static const ZERO : int = '0'.charCodeAt();
			//private static const NINE : int = '9'.charCodeAt();
			var codeAt0 : int = tempStr.charCodeAt(0);
			if ("true" == tempStr) 
			{
				return true;
			}
			else if ("false" == tempStr) 
			{
				return false;
			}
			else if ("nil" == tempStr || "null" == tempStr)
			{
				return null;
			}
			else if ((codeAt0 >= '0'.charCodeAt() && codeAt0 <= '9'.charCodeAt()) || '-'.charCodeAt() == codeAt0 || '.'.charCodeAt() == codeAt0) 
			{
				// Number
				var t : Number = Number(tempStr);
				if (isNaN(t)) 
				{
					trace("Assign a NaN.");
					return null;
				}
				return t;
			}
			else 
			{
				return tempStr.substring(1, tempStr.length - 1);
			}
		}
	}
}