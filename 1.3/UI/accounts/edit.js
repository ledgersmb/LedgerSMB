
function init(){
    var typeselect = document.getElementById('charttype');
    typeselect.addEventListener(
              'blur', 
              changetype,
              true
   );
   changetype()
}

function changetype() {
   var typeselect = document.getElementById('charttype');
   var headingrow = document.getElementById('heading-line');
   var accdetails = document.getElementById('accdetails');
   var dropdowns = document.getElementById('dropdowns');
   if (typeselect.value == 'A'){
         headingrow.style.display = 'none';
         accdetails.style.display = 'block';
         dropdowns.style.display = 'block';
   } else {
         headingrow.style.display = 'block';
         accdetails.style.display = 'none';
         dropdowns.style.display = 'none';
   }
}
