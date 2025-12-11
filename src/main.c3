import std::io;
import std::collections;
import json_tokenizer;
import json_parser;
import json_types;
import requests;
import curl;


const GET_URL = "https://jsonplaceholder.typicode.com/todos/1";
const POST_URL = "https://jsonplaceholder.typicode.com/posts";


faultdef INVALID_ARG;

enum Argument {
	TEST_POST,
	TEST_GET,
	TEST_PARSE,
	TEST_PIPELINE
}

fn Argument? parse_arg(String arg) {
	switch(arg) {
		case "POST":
		case "post":
		case "Post":
			return TEST_POST;
		case "GET":
		case "get":
		case "Get":
			return TEST_GET;
		case "PARSE":
		case "parse":
		case "Parse":
			return TEST_PARSE;
		case "PIPE":
		case "Pipe":
		case "pipe":
			return TEST_PIPELINE;
		default:
			return INVALID_ARG?;
	}
}


fn void? test_get() {
	requests::Requester requester;
	Response* g = requester.get(
		GET_URL,
		1000,
		{"content-type: application/json"}
	)!;
	defer {
		g.clear();
		free(g);
	}
	io::printn((ZString)g.contents()!);
	io::printn(g.status);
}


fn void? test_post() {
	requests::Requester requester;
	Response* p = requester.post(
		POST_URL,
		1000,
		"{\"title\": \"My test\"}",
		{"content-type: application/json"}
	)!;
	
	io::printn((ZString)p.contents()!!);
	io::printn(p.status);
	defer {
		p.clear();
		free(p);
	}
}


fn void? test_parse() {
	char* test_data = "{\"My test\": 1, \"Another\": [null, false, true], \"oops\": [{\"key\": 87}, {\"key\": false}]}";

	List{Token*}* tokens = json_tokenizer::tokenize((ZString)test_data);
	defer {
		foreach (Token* tk : tokens) {
			tk.clear();
			free(tk);
		}
		tokens.free();
		free(tokens);
	}

	io::printn("------ TEST DATA ------");
	io::printn((ZString)test_data);
	
	io::printn("------ PARSED ------");
	JsonParser parser;
	JsonValue? value = parser.get_value(tokens);
	value.print()!;
}


fn void? test_pipeline() {
	requests::Requester requester;
	Response* g = requester.get(
		GET_URL,
		1000,
		{"content-type: application/json"}
	)!;
	defer {
		g.clear();
		free(g);
	}
	ZString response_text = (ZString)g.contents()!;
	io::printn(g.status);
	
	List{Token*}* list = json_tokenizer::tokenize(response_text);	 
	defer {
		foreach (Token* tk : list) {
			tk.clear();
			free(tk);
		}
		list.free();
		free(list);
	}

	JsonParser parser;
	JsonValue value = parser.get_value(list)!;

	HashMap{String, JsonValue}* response_json = value.as_object;
	double userId = response_json.get("userId").as_number!;
	io::printfn("Returned userId: %.2f", userId);
}


fn int main(String[] args) {
	if (args.len != 2) {
		io::eprintn("Expected exactly one argument");
		return 1;
	}

	Argument? arg = parse_arg(args[1]);
	if (catch excuse = arg) {
		io::eprintn(excuse);
		return 1;
	}

	switch(arg) {
		case TEST_GET:
			if (catch excuse = test_get()) {
				io::eprintn(excuse);
				return 1;
			}
			break;
		case TEST_POST:
			if (catch excuse = test_post()) {
				io::eprintn(excuse);
				return 1;
			}
			break;
		case TEST_PARSE:
			if (catch excuse = test_parse()) {
				io::eprintn(excuse);
				return 1;
			}
			break;
		case TEST_PIPELINE:
			if (catch excuse = test_pipeline()) {
				io::eprintn(excuse);
				return 1;
			}
			break;
	}

	return 0;
}

// fn void main() {
// 	char* test_data = "{\"My test\": 1, \"Another\": [null, false, true], \"oops\": [{\"key\": 87}, {\"key\": false}]}";
// 	io::printn("---------- TOKENIZER START ------------");
// 	List{Token*}* list = json_tokenizer::tokenize((ZString)test_data);
// 	defer {
// 		foreach (Token* tk : list) {
// 			tk.clear();
// 			free(tk);
// 		}
// 		free(list);
// 	}
// 	io::printn("---------- TOKENIZER END------------");
// 	io::printn("---------- PARSER START ------------");
// 	JsonParser parser;
// 	JsonValue? value = parser.get_value(list);
// 	JsonValue? value2 = parser.get_value(list);
// 	if (catch excuse = value) {
// 		io::eprintn(excuse);
// 		return;
// 	} else if (catch excuse2 = value2) {
// 		io::eprintn(excuse2);
// 		return;
// 	}
// 	defer (void)value.free_inner();
// 	defer (void)value2.free_inner();

// 	io::printn("---------- PARSER END------------");
// 	io::printn("---------- TESTING START------------");
// 	io::printfn("Test data: %s", (ZString)test_data);

// 	(void)value.print();
// 	// HashMap{String, JsonValue}* base = value.as_object;

// 	// String key1 = "My test";
// 	// double value1 = base.get(key1).as_number!!;
// 	// io::printfn("%s: %.2f", key1, value1);

// 	// String key2 = "Another";
// 	// List{JsonValue}* value2 = base.get(key2).as_array!!;
// 	// void* n = value2.get(0).as_null;
// 	// bool f = value2.get(1).as_bool;
// 	// bool t = value2.get(2).as_bool;
// 	// io::printfn("%s: [%s, %s, %s]", key2, n, f, t);

// 	// String key3 = "oops";
// 	// List{JsonValue}* value3 = base.get(key3).as_array!!;
// 	// HashMap{String, JsonValue}* v3obj1 = value3.get(0).as_object;
// 	// HashMap{String, JsonValue}* v3obj2 = value3.get(1).as_object;

// 	// String rec_key = "key";
// 	// double rec1_value = v3obj1.get(rec_key).as_number!!;
// 	// bool rec2_value = v3obj2.get(rec_key).as_bool!!;

// 	// io::printfn("%s: [", key3);
// 	// io::printfn("\t%s: %.2f,", rec_key, rec1_value);
// 	// io::printfn("\t%s: %s", rec_key, rec2_value);
// 	// io::printn("]");
	
// 	io::printn("---------- TESTING END------------");
// }
