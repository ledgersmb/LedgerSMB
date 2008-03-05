/******************************************************
    CopyLeft DAVID MORA RODRIGUEZ
	     CRISTIAN CEBALLOS

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
********************************************************/

// This function should not be called directly
 function maximize(element) {
      try { 
           var obj = document.getElementById(element);
           obj.style.visibility =  'visible';
           obj.style.height = "60px";
	             
      }
      catch(err) { alert("ERROR ON maximize: "+err);  }
       
    
    }
// This funciton should not be called directly
 function minimize(element) {
      try {
           var obj2 = document.getElementById(element);
           obj2.style.visibility = 'hidden';
           obj2.style.height = '0px';
      }
      catch(err) { alert("ERROR ON minimize: " + err);  }
   }
/* This is the handler for maximize_minimize, it is intended to be called
 directly this will call maximize and minimize */
 function maximize_minimize(element, state, img, plusimage, minusimage) {
     try {   
        var obj = document.getElementById(element);
        var obj3 = document.getElementById(state);
      if ( obj.style.visibility  == 'hidden'   ) {
        img.src = minusimage;
        maximize(element);
        obj3.value = 'visible'; 
      } else {
         img.src = plusimage;
         minimize(element);
         obj3.value ='hidden';
      }
     } catch (err) { alert("ERROR ON maximize_minimize: " + err);}
 }

/* This function gets the form state and set it invisible */
/* Container is the element that contains the tagname elements, all of them must match the same criteria */
 function maximize_minimize_on_load (container, plusimage, minusimage) {
 
 var table = document.getElementById(container); 
 var cells = table.getElementsByTagName("input");
 var regex = new RegExp("topaystate_");
 try{ 
	for (var i = 0; i < cells.length; i++) {
       
	 var extra_info =  cells[i].id.replace(regex,"div_topay_");   
	 var img        =  document.getElementById(cells[i].id.replace(regex,"button_topay_"));
         if (cells[i].value == '' || cells[i].value == "hidden") {
		 maximize_minimize(extra_info , cells[i].id, img, plusimage, minusimage);
         }
 }        
 } catch (err) { alert("ERROR ON maximize_minimize_on_load: " + err)  }
}

