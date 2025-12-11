module curl;


// These are extracted directly from curl.h
const CURLINFO_LONG 			= 0x200000;
const CURLINFO_RESPONSE_CODE 	= CURLINFO_LONG + 2;
const CURLE_OK 					= 0;

const CURLOPT_URL 				= 10002;
const CURLOPT_WRITEDATA 		= 10001;
const CURLOPT_HTTPHEADER 		= 10023;
const CURLOPT_WRITEFUNCTION 	= 20011;
const CURLOPT_POSTFIELDS     	= 10015;

// These are useful for readability
typedef Curl 		= void;
typedef Curl_slist 	= void;
typedef CURLcode 	= int;

extern fn Curl* 		curl_easy_init();
extern fn int 			curl_easy_setopt(Curl*, int, void*);
extern fn CURLcode 		curl_easy_perform(Curl*);
extern fn void 			curl_easy_cleanup(Curl*);
extern fn void 			curl_easy_getinfo(Curl*, int, int*);
extern fn Curl_slist* 	curl_slist_append(Curl_slist*, char*);
extern fn void 			curl_slist_free_all(Curl_slist*);
