
function init() {
	var radios = ['comparison_by_dates', 'comparison_by_periods'];
	while (radios.length) {
		var radio = document.getElementById(radios.shift());
		radio.addEventListener('click', 
			function(e){
				var my_id = this.getAttribute('id');
				show_hide_details(my_id);
				return true;
			}, false);
	}
	var periods = document.getElementById('comparison-periods');
	periods.addEventListener('input', 
		function(e){
			var my_id = this.getAttribute('id');
			show_hide_details(my_id);
			return true;
		}, false);
}

function show_hide_details(type_id){
	var e_id = "comparison_dates";
	var e = document.getElementById(e_id);
	var p_id = 'comparison-periods';
	var p = document.getElementById(p_id);
	if (type_id != "comparison-periods") {
		e.style = type_id == "comparison_by_dates" ? "" : "display:none";
	} else {
		var c = p.value;
		for ( i = 1 ; i <= 9 ; i++ ) {
			var ei_id = e_id + "_" + i;
			var p_ei_id = document.getElementById(ei_id);
			if ( p_ei_id ) {
				p_ei_id.style = i <= c ? "" : "display:none";
			}
		}
	}
	return true;
}
