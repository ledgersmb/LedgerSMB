
// Note: we do not heed to try other interfaces since we don't support IE 6 or
// lower.  If we need to support other interfaces later, we can add them.
// --CT
function get_http_request_object(){
	if (typeof XMLHttpRequest == undefined){
		return false;
	} else {
		return new XMLHttpRequest();
	}
}

