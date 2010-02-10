try{
var agt=navigator.userAgent.toLowerCase();
if (agt.indexOf("msie") != -1) {
// IE clear HTTP Authentication
    document.execCommand("ClearAuthenticationCache");
}
}
catch (e) {
}
