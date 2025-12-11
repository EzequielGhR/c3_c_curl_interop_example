module json_tokenizer;

import std::io;
import std::core::mem;
import std::collections;
import json_types;
import libc;


faultdef INVALID_TOKEN;

const MAX_STR_LEN = 10000;

enum TokenType {
	LBRACE,
	RBRACE,
	LBRACKET,
	RBRACKET,
	COLON,
	COMMA,
	STRING,
	NUMBER,
	TRUE,
	FALSE,
	NULL,
	EOF
}


struct Token {
	TokenType type;
	String lexeme;
}

fn void Token.set(&self, TokenType type, String lexeme) {
	self.type = type;
	self.lexeme = lexeme.copy(mem);
}

fn void Token.clear(&self) => free(self.lexeme);


fn List{Token*}* tokenize(ZString input) {
	List{Token*}* list = mem::new(List{Token*});
	list.init(mem);
	
	int i = 0;
	while (i < input.len()) {
		char c = input[i];
		if (c == ' ' || c == '\n' || c == '\r') {
			i++;
			continue;
		}
		Token* token = mem::new(Token);
		switch(c) {
			case '{':
				token.set(LBRACE, "{");
				list.push(token);
				i++;
				break;
			case '}':
				token.set(RBRACE, "}");
				list.push(token);
				i++;
				break;
			case '[':
				token.set(LBRACKET, "[");
				list.push(token);
				i++;
				break;
			case ']':
				token.set(RBRACKET, "]");
				list.push(token);
				i++;
				break;
			case ':':
				token.set(COLON, ":");
				list.push(token);
				i++;
				break;
			case ',':
				token.set(COMMA, ",");
				list.push(token);
				i++;
				break;
			case '"':
				char[MAX_STR_LEN] buffer;
				int j = 0;
				while (true) {
					c = input[i+j+1];
					if (c == '"') {
						break;
					}

					buffer[j] = c;
					j++;
				}
				buffer[j] = 0;

				token.set(STRING, ((ZString)buffer[:j]).str_view());
				list.push(token);
				i = i + j + 2;
			default:
				if (c == 'n') {
					token.set(NULL, "null");
					list.push(token);
					i += 4;
				} else if (c == 't') {
					token.set(TRUE, "true");
					list.push(token);
					i += 4;
				} else if (c == 'f') {
					token.set(FALSE, "false");
					list.push(token);
					i += 5;
				} else {
					char[MAX_STR_LEN] buffer;
					int j = 0;
					while (true) {
						c = input[i+j];
						if (c == ']' || c == '}' || c == ':' || c == ',') {
							break;
						}
						buffer[j] = c;
						j++;
					}
					buffer[j] = 0;

					token.set(NUMBER, ((ZString)buffer[:j]).str_view());
					list.push(token);
					i+=j;
				}
		}
	}

	return list;
}

