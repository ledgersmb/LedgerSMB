/* 
  Date input field transformation.
  Original script from sql-ledger fork from: http://www.tavugyvitel.hu

  Example:
  enter the following string to a date input field: 0815
  press TAB: now the entered string will be converted to 2014-08-15
  if the format is: yyyy-mm-dd and the current year is 2014

  Tested and integrated by István Pongrácz
  2014.08.15.

  Based on LedgerSMB 1.3.41 but should work on the whole 1.3.x series.

*/

function dattrans(n,c){
  var d = $(n);
  if ( d.value.length == 4 && !/[^\d]/.test(d.value)) {
    var most = new Date();
    ev = most.getYear()
    if ( ev < 1000 ) { ev += 1900; };
    var tit = d.title;
    tit = tit.replace( "(" , "" );
    tit = tit.replace( ")" , "" );
    tit = tit.replace( " " , "" );
    tit = tit.replace( "mm" , d.value.substr(0,2));
    tit = tit.replace( "dd" , d.value.substr(2,2));
    tit = tit.replace( "yyyy" , ev);
    tit = tit.replace( "yy" , ev.toString().substr(2,2));
    d.value = tit;
  }    
  if( c == 1 ) {
    document.forms[0].transdate.value = d.value;
    document.forms[0].duedate.value = d.value;
  }    
}
