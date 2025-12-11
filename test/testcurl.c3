import std::io;
import requests;
import curl;


const GET_URL = "https://jsonplaceholder.typicode.com/todos/1";
const POST_URL = "https://jsonplaceholder.typicode.com/posts";

fn int main() {
	io::printn("Testing get request:");
	requests::Requester requester;
	Response* g = requester.get(
		GET_URL,
		1000,
		{"content-type: application/json"}
	)!!;
	defer {
		g.clear();
		free(g);
	}
	io::printn((ZString)g.contents()!!);
	io::printn(g.status);

	io::printn("");

	io::printn("Testing post request:");
	Response* p = requester.post(
		POST_URL,
		1000,
		"{\"title\": \"My test\"}",
		{"content-type: application/json"}
	)!!;
	
	io::printn((ZString)p.contents()!!);
	io::printn(p.status);
	defer {
		p.clear();
		free(p);
	}

	return 0;
}
