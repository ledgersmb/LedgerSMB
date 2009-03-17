
function init() {
	var spans = document.getElementsByTagName('span');
	var tables = document.getElementsByTagName('table');
	for (var i=0, il=tables.length; i<il; i++){
		var table = tables.item(i);
		if (table.getAttribute('class') == 'detail_table_visible'){
			var tid = table.getAttribute('id');
			var cid = tid.slice(19, tid.length);
			var rg = document.getElementsByName('paid_' + cid);
			for (var i=0, il=rg.length; i<il; i++){
				var button = rg.item(i);
				if ((button.value == 'all') && 
						(button.checked == true)){
					table.className = 'detail_table_hidden';
				}
			}
		}
	}
	for (var i=0, il=spans.length; i<il; i++){
		var span = spans.item(i);
		if (span.getAttribute('class') != 'details_select'){
			continue;
		}
		var inputs = span.getElementsByTagName('input');
		for (var i=0, il=inputs.length; i<il; i++){
			var input = inputs.item(i);
			if (input.getAttribute('class') == 'paid_some'){
				input.addEventListener('click', 
					function(e){
						var my_id = 
							this.getAttribute('id');
						var contact_id = 
							my_id.slice(10, 
								my_id.length);
						show_details(contact_id);
						return true;
					}, false);
			}
			else if (input.getAttribute('class') == 'paid_all'){
				input.addEventListener('click', 
					function(e){
						var my_id = 
							this.getAttribute('id');
						var contact_id = 
							my_id.slice(9, 
								my_id.length);
						hide_details(contact_id);
						return true;
					}, false);
			}
		}
	}
}

function show_details(contact_id){
	var e_id = "invoice_data_table_" + contact_id;
	var e = document.getElementById(e_id);
	e.className = "detail_table_visible";
	return true;
}

function hide_details(contact_id){
	var e_id = "invoice_data_table_" + contact_id;
	var e = document.getElementById(e_id);
	e.className = "detail_table_hidden";
	return true;
}
