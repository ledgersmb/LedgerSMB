function post_ajax_setter(text,li)
{
	hidden_field_to_update = text.id;
	$(hidden_field_to_update).value = li.id;
	text.blur();
    $(hidden_field_to_update).focus();
}
