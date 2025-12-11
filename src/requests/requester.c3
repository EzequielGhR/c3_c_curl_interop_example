module requests;

import std::io;
import std::core::mem;

import curl;
import memory;


faultdef REQUESTER_NOT_INITIALIZED, FAILED_REQUEST;

// --- Response structure ---
struct Response {
	Memory* mem;
	int 			status;
}

fn char*? Response.contents(&self) {
	if (!self.mem || !self.mem.data) return memory::NOT_ENOUGH_MEMORY?;
	return self.mem.data;

}

fn usz? Response.size(&self) {
	if (!self.mem) return memory::NOT_ENOUGH_MEMORY?;
	return self.mem.size;
}

fn usz? Response.write_contents(&self, void* data, usz data_size) {
	char* contents 	= self.contents()!;
	usz size 		= self.size()!;

	if (size <= data_size) {
		io::eprintfn("Contents (%d) can't hold chunk size (%d)", size, data_size);
		data_size = size - 1;
	}

	mem::copy(contents, data, data_size);
	contents[data_size] = 0;
	return data_size;
}

fn void Response.allocate_mem(&self, usz char_amount) {
	io::printfn("Allocating response memory: %d", char_amount * char.sizeof);
	self.mem = mem::new(Memory);
	self.mem.data = mem::new_array(char, char_amount);
	self.mem.size = char_amount;
}

fn void Response.clear(&self) {
	self.mem.clear();
	free(self.mem);
}


// --- Utils ---
enum Method {
	GET,
	POST
}


// --- Requester obj ---
struct Requester {
	char* 			url;
	Curl* 			curl;
	CURLcode 		curl_response;
	Curl_slist* 	headers;
	memory::Memory* chunk;
	char* 			data;
	long 			response_code;
	Response* 		response;
}

fn bool Requester._is_set(&self) {
	return (
		self.curl 		!= null &&
		self.url 		!= null &&
		self.chunk 		!= null &&
		self.chunk.data != null
	);
}

fn bool Requester.setup(&self, char* url) {
	if (self._is_set()) {
		io::eprintn("Requester already set.");
		return false;
	}
	
	self.url 	= url;
	self.curl 	= curl::curl_easy_init();
	if (self.curl == null) {
		io::eprintn("Failed to initialize curl object");
		return false;
	}

	self.chunk 			= mem::new(Memory);
	self.chunk.data 	= mem::new(char);
	self.chunk.size 	= 0;

	curl::curl_easy_setopt(self.curl, curl::CURLOPT_URL, self.url);
	curl::curl_easy_setopt(
		self.curl,
		curl::CURLOPT_WRITEFUNCTION,
		&memory::w_callback
	);
	curl::curl_easy_setopt(
		self.curl,
		curl::CURLOPT_WRITEDATA,
		(void*)self.chunk
	);
	
	return true;
}

fn bool? Requester.set_headers(&self, String[] headers_array) {
	if (!self._is_set()) return REQUESTER_NOT_INITIALIZED?;
	
	foreach (String header : headers_array) {
		self.headers = curl::curl_slist_append(
			self.headers,
			(ZString)header
		);
	}
	curl::curl_easy_setopt(
		self.curl,
		curl::CURLOPT_HTTPHEADER,
		self.headers
	);

	return true;
}

fn bool? Requester.set_post_data(&self, char* data) {
	if(!self._is_set()) return REQUESTER_NOT_INITIALIZED?;
	if(!data) {
		io::eprintn("Data seems to be empty");
		return false;
	}
	curl::curl_easy_setopt(self.curl, curl::CURLOPT_POSTFIELDS, data);
	return true;
}

fn void Requester.cleanup(&self) {
	if (self.curl) curl::curl_easy_cleanup(self.curl);
	if (self.chunk) {
		if (self.chunk.data) free(self.chunk.data);
		free(self.chunk);
	}

	if (self.headers) curl::curl_slist_free_all(self.headers);

	self.curl 		= null;
	self.chunk 		= null;
	self.headers 	= null;
	self.url 		= null;
}

fn CURLcode? Requester.perform(&self) {
	if (!self._is_set()) return REQUESTER_NOT_INITIALIZED?;

	self.curl_response = curl::curl_easy_perform(self.curl);
	if (self.curl_response != curl::CURLE_OK) {
		return FAILED_REQUEST?;
	}

	if (self.response) {
		curl::curl_easy_getinfo(
			self.curl,
			curl::CURLINFO_RESPONSE_CODE,
			&(self.response.status)
		);
		self.response.write_contents(self.chunk.data, self.chunk.size)!;
	}

	return self.curl_response;
}

fn Response*? Requester.request(
	&self,
	char* url,
	Method method,
	usz resp_cap = 1000,
	char* data = null,
	String[] headers = {}
) {
	bool set_on_call = false;
	if(!self._is_set()) {
		self.setup(url);
		set_on_call=true;
	}
	defer {
		if (set_on_call) {
			io::printn("Cleaning up call resources");
			self.cleanup();
		}
	}

	if (!self.headers && headers) self.set_headers(headers)!;
	
	if (method == POST) {
		self.set_post_data(data)!;
	}

	self.response = mem::new(Response);
	self.response.allocate_mem(resp_cap);

	self.perform()!;
	return self.response;
}

fn Response*? Requester.get(
	&self,
	char* url,
	usz resp_cap = 1000,
	String[] headers = {}
) => self.request(url, GET, resp_cap, null, headers)!;

fn Response*? Requester.post(
	&self,
	char* url,
	usz resp_cap = 1000,
	char* data,
	String[] headers = {}
) => self.request(url, POST, resp_cap, data, headers)!;
