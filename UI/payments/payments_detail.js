
function init() {
	var cc = document.getElementById('contact-count').value;
	for (var i=1; i <= cc; i++){
		var paid = '';
		var cid = document.getElementById('contact-' + i).value;
		var radio = document.getElementById('paid-all-' + cid);
		if (radio.checked == true){
			paid = 'all';
		} else {
			paid = 'some';
		}
		radio.addEventListener('click', 
			function(e){
				var my_id = 
					this.getAttribute('id');
					var contact_id = 
						my_id.slice(9, 
							my_id.length);
					hide_details(contact_id);
					return true;
				}, false);
		radio = document.getElementById('paid-some-' + cid);
		radio.addEventListener('click', 
			function(e){
				var my_id = 
					this.getAttribute('id');
					var contact_id = 
						my_id.slice(10, 
							my_id.length);
					show_details(contact_id);
					return true;
				}, false);
		var table = document.getElementById('invoice-data-table-' + cid);
		if (paid == 'all'){
			table.className = 'detail_table_hidden';
		}
	}
        var cb = document.getElementById('checkbox-selectall');
        cb.addEventListener('click',
                function(e){
                    var cb = document.getElementById('checkbox-selectall');
                    var cc = document.getElementById('contact-count').value;
                    for (var i=1; i <= cc; i++){
                        var cid = document.getElementById('contact-' + i).value;                        var rowcb = document.getElementById('id-' + cid);
                        rowcb.checked = cb.checked;
                    }
                 }, false);
}

function show_details(contact_id){
	var e_id = "invoice-data-table-" + contact_id;
	var e = document.getElementById(e_id);
	e.className = "detail_table_visible";
	return true;
}

function hide_details(contact_id){
	var e_id = "invoice-data-table-" + contact_id;
	var e = document.getElementById(e_id);
	e.className = "detail_table_hidden";
	return true;
}
