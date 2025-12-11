module json_parser;


import std::collections;
import std::core::mem;
import std::io;

import json_tokenizer;
import json_types;


struct JsonParser {
	usz last_index;
	JsonValue value;
}

fn void JsonParser.init(&self) {
	self.last_index = 0;
}

fn JsonValue? JsonParser.get_value(&self, List{Token*}* token_list) {
	self.init();
	JsonValue parsed = self.parse_value(token_list, 0)!;
	self.value = parsed;
	return self.value;
}

fn JsonValue? JsonParser.parse_value(&self, List{Token*}* token_list, usz index) {
	JsonValue value;
	Token* current_token = token_list.get(index);
	switch(current_token.type) {
		case LBRACE:
			value.type = OBJECT;
			self.last_index++;
			value.as_object = self.parse_object(token_list, self.last_index)!;
			break;
		case LBRACKET:
			value.type = ARRAY;
			self.last_index++;
			value.as_array = self.parse_array(token_list, self.last_index)!;
			break;
		case STRING:
			value.type = STRING;
			self.last_index++;
			value.as_string = current_token.lexeme;
			break;
		case NUMBER:
			value.type = NUMBER;
			self.last_index++;
			value.as_number = current_token.lexeme.to_double()!;
			break;
		case TRUE:
			value.type = BOOL;
			self.last_index++;
			value.as_bool = true;
			break;
		case FALSE:
			value.type = BOOL;
			self.last_index++;
			value.as_bool = false;
			break;
		case NULL:
 			value.type = NULL;
			self.last_index++;
			value.as_null = null;
			break;
		case EOF:
			break;
		default:
			return json_tokenizer::INVALID_TOKEN?;
	}
	return value;
}

fn HashMap{String, JsonValue}*? JsonParser.parse_object(&self, List{Token*}* token_list, usz index) {
	HashMap{String, JsonValue}* map = mem::new(HashMap{String, JsonValue});
	map.init(mem);
	
	while (true) {
		Token* current_token = token_list.get(index);

		// Skip the colon
		self.last_index += 2;
		
		String key = current_token.lexeme;
		JsonValue value = self.parse_value(token_list, self.last_index)!;
		map.set(key, value);

		TokenType current_type = token_list.get(self.last_index).type;
		
		if (current_type == RBRACE) {
			self.last_index++;
			return map;
		}

		if (current_type != COMMA) {
			return json_tokenizer::INVALID_TOKEN?;
		}

		// Skip the comma
		self.last_index ++;
		index = self.last_index;
	}
}


fn List{JsonValue}*? JsonParser.parse_array(&self, List{Token*}* token_list, usz index) {
	List{JsonValue}* value_list = mem::new(List{JsonValue});
	value_list.init(mem);
	
	while(true) {
		JsonValue element = self.parse_value(token_list, index)!;
		value_list.push(element);

		TokenType current_type = token_list.get(self.last_index).type;
		if (current_type == RBRACKET) {
			self.last_index++;
			return value_list;
		}

		if (current_type != COMMA) {
			return json_tokenizer::INVALID_TOKEN?;
		}

		// Skip the comma
		self.last_index ++;
		index = self.last_index;
	}
}
