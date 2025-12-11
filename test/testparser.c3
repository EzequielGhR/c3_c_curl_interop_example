import std::io;
import std::collections;
import json_tokenizer;
import json_parser;
import json_types;


fn void main() {
	char* test_data = "{\"My test\": 1, \"Another\": [null, false, true], \"oops\": [{\"key\": 87}, {\"key\": false}]}";
	io::printn("---------- TOKENIZER START ------------");
	List{Token*}* list = json_tokenizer::tokenize((ZString)test_data);
	defer {
		foreach (Token* tk : list) {
			tk.clear();
			free(tk);
		}
		free(list);
	}
	io::printn("---------- TOKENIZER END------------");
	io::printn("---------- PARSER START ------------");
	JsonParser parser;
	JsonValue? value = parser.get_value(list);
	JsonValue? value2 = parser.get_value(list);
	if (catch excuse = value) {
		io::eprintn(excuse);
		return;
	} else if (catch excuse2 = value2) {
		io::eprintn(excuse2);
		return;
	}
	defer (void)value.free_inner();
	defer (void)value2.free_inner();

	io::printn("---------- PARSER END------------");
	io::printn("---------- TESTING START------------");
	io::printfn("Test data: %s", (ZString)test_data);

	(void)value.print();
	// HashMap{String, JsonValue}* base = value.as_object;

	// String key1 = "My test";
	// double value1 = base.get(key1).as_number!!;
	// io::printfn("%s: %.2f", key1, value1);

	// String key2 = "Another";
	// List{JsonValue}* value2 = base.get(key2).as_array!!;
	// void* n = value2.get(0).as_null;
	// bool f = value2.get(1).as_bool;
	// bool t = value2.get(2).as_bool;
	// io::printfn("%s: [%s, %s, %s]", key2, n, f, t);

	// String key3 = "oops";
	// List{JsonValue}* value3 = base.get(key3).as_array!!;
	// HashMap{String, JsonValue}* v3obj1 = value3.get(0).as_object;
	// HashMap{String, JsonValue}* v3obj2 = value3.get(1).as_object;

	// String rec_key = "key";
	// double rec1_value = v3obj1.get(rec_key).as_number!!;
	// bool rec2_value = v3obj2.get(rec_key).as_bool!!;

	// io::printfn("%s: [", key3);
	// io::printfn("\t%s: %.2f,", rec_key, rec1_value);
	// io::printfn("\t%s: %s", rec_key, rec2_value);
	// io::printn("]");
	
	io::printn("---------- TESTING END------------");
}
