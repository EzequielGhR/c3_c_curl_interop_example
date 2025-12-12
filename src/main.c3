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
	char* test_data = "{\"My test\": 1, \"Another\": [null, false, true, \"sample\"], \"oops\": [{\"key\": 87}, {\"key\": false}]}";

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
	defer (void)value.free_inner();
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
