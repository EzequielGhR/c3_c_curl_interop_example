module memory;

import std::core::mem;
import std::io;


faultdef NOT_ENOUGH_MEMORY;


struct Memory {
	char* 	data;
	usz 	size;
}

fn usz? Memory.write_data(&self, usz realsize, void* contents) {
	char* new_memory = realloc(self.data, self.size + realsize + 1);
	if (new_memory == null) {
		return NOT_ENOUGH_MEMORY?;
	}

	self.data = new_memory;
	mem::copy(&(self.data[self.size]), contents, realsize);
	self.size += realsize;
	self.data[self.size] = 0;

	return realsize;
}

fn void Memory.clear(&self) {
	free(self.data);
	self.data = (void*)null;
	self.size = 0;
}


// --- Write Callback for curl ---
fn usz w_callback(void* contents, usz size, usz nmemb, void* userp) {
	usz realsize 	= size * nmemb;
	Memory* memory 	= (Memory*)userp;
	usz? written 	= memory.write_data(realsize, contents);
	if (catch excuse = written) {
		io::eprintn("Not enough memory");
		return 0;
	}

	return written;
}
