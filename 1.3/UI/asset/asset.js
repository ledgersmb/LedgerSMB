function setDefaultAccount(){
    var asset_dropdown = document.getElementById('asset-account-id');
    var dep_dropdown = document.getElementById('dep-account-id');
    var old_class = document.getElementById('last-class-id').value;
    var class_dropdown = document.getElementById('asset-class');
    var new_class = class_dropdown.options[class_dropdown.selectedIndex].value;
    var unit_caption_e = document.getElementById('caption-usablelifegroup');
    var unit_caption = document.getElementById('unit-label-' + new_class).value;

    if (new_class == ""){
        new_class = class_dropdown.options[0].value;
    }
    if (old_class != ""){
        unit_caption_e.innerHTML = '(' + unit_caption + ')';
        document.getElementById('asset-account-default-' + old_class).value 
        = asset_dropdown.options[asset_dropdown.selectedIndex].value;
        document.getElementById('dep-account-default-' + old_class).value 
        = dep_dropdown.options[dep_dropdown.selectedIndex].value;
    }
    document.getElementById('last-class-id').value = new_class;

    set_dropdown(asset_dropdown, 
                 document.getElementById('asset-account-default-' + new_class).value);
    set_dropdown(dep_dropdown,
                 document.getElementById('dep-account-default-' + new_class).value);

}

function set_dropdown (selectElement, newValue){
    for (var i = 0; i < selectElement.options.length; i++) {
        if (selectElement.options[i].value == newValue) {
           selectElement.options[i].selected = true;
        } else {
           selectElement.options[i].selected = false;
        }
    }
   
}

function init(){
    if (document.GetElementById('id').value > 0){
        return;
    }
    document.getElementById('asset-class').addEventListener('blur', Function('setDefaultAccount()'), false);
    setDefaultAccount();
    document.getElementById('update-accounts').setAttribute('class', 'generic');
    document.getElementById('update-accounts').addEventListener('click', 'return false', false);
}
