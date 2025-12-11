module json_types;

import std::io;
import std::collections;


faultdef INVALID_TYPE;

alias InnerFunc = fn void(JsonValue);

enum JsonType {
	NULL,
	BOOL,
	NUMBER,
	STRING,
	ARRAY,
	OBJECT
}


struct JsonValue {
	JsonType type;
	union {
		bool as_bool;
		double as_number;
		String as_string;
		List{JsonValue}* as_array;
		HashMap{String, JsonValue}* as_object;
		void* as_null;
	}
}

fn void? JsonValue.print(&self, int indents = 0) {
	JsonValue* current = self;
	print_indents(indents);
	switch(current.type) {
		case NULL:
			io::printn("null");
			return;
		case BOOL:
			bool current_value = current.as_bool;
			io::printfn("%s", current_value);
			return;
		case NUMBER:
			double current_value = current.as_number;
			io::printfn("%.2f", current_value);
			return;
		case STRING:
			String current_value = current.as_string;
			io::printfn("%s", current_value);
			return;
		case ARRAY:
			io::printn("[");
			List{JsonValue}* current_value = current.as_array;
			foreach (JsonValue val : current_value) {
				val.print(indents + 1)!;
			}
			print_indents(indents);
			io::printn("]");
			break;
		case OBJECT:
			io::printn("{");
			HashMap{String, JsonValue}* current_value = current.as_object;
			foreach(String key : current_value.tkeys()) {
				print_indents(indents + 1);
				io::printfn("\"%s\":", key);
				JsonValue value = current_value.get(key)!;
				value.print(indents + 1)!;
			}
			print_indents(indents);
			io::printn("}");
			break;
	}
}

fn void? JsonValue.free_inner(&self) {
	JsonValue* current = self;
	switch (current.type) {
		case ARRAY:
			List{JsonValue}* current_value = current.as_array;
			foreach(JsonValue value : current_value) {
				value.free_inner()!;
			}
			current_value.free();
			free(current_value);
		case OBJECT:
			HashMap{String, JsonValue}* current_value = current.as_object;
			foreach(String key : current_value.tkeys()) {
				JsonValue val = current_value.get(key)!;
				val.free_inner()!;
			}
			current_value.free();
			free(current_value);
		default:
			return;
	}
	
}


fn void print_indents(int indents) @private {
	for (int i = 0; i < indents; i++) {
		io::print("  ");
	}
}
