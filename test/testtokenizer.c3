import std::io;
import std::collections;
import json_tokenizer;


fn void main() {
	char* test_data = "{\"My test\": 1, \"Another\": [null, false, true], \"oops\": [{\"key\": 87}, {\"key\": false}]}";
	List{Token*}* list = json_tokenizer::tokenize((ZString)test_data);
	defer {
		foreach (Token* tk : list) {
			tk.clear();
			free(tk);
		}
		free(list);
	}

	io::printn((ZString)test_data);
	foreach (Token* tk : list) {
		char* lexeme = tk.lexeme;
		io::printfn("%s -> %s", tk.type, tk.lexeme);
	}
}
