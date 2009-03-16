
function init(div_id) {
	var lis = document.getElementsByTagName('li');
	for (var e in lis){
		if (e != e * 1){
			continue;
                }
		e = lis.item(e);
		if (e.getAttribute('class') == "nav"){
			e.addEventListener('click', function (e) {
				for (var a in this.getElementsByTagName('a')){
					if (a != a * 1){
						continue;
					}
					a = this.getElementsByTagName('a').item(a);
					var dest = a.getAttribute('href');
					dest = dest.replace('#', '');
					select_div(dest);
					break;
				}
				return false;
			},false);
		}
	}
	if (div_id != ''){
		select_div(div_id);
	}
}

function select_div(div_id){
	var divs = document.getElementsByTagName('div');
	var i = 0;
	for (i=0;i<=divs.length;i++){
		var e = divs.item(i);
		if (!e || !e.getAttribute || !e.getAttribute('class')){
			continue;
		}
		if (e.getAttribute('class').match(/^container/)){
			if (e.getAttribute('id') == div_id){
				e.className = 'container';
			}
			else {
				e.className = 'container_hidden';
			}
		}
	}
}

