$('.dropdown-toggle').dropdown();
$(".alert").alert();
$('.typeahead').typeahead();


$("#countries").typeahead({
    source: function(typeahead, query) {
        if(this.ajax_call)
            this.ajax_call.abort();
        this.ajax_call = $.ajax({
            dataType : 'json',
            data: {
                q: query
            },
            url: $("#countries").data('source'),
            success: function(data) {
                typeahead.process(data);
            }
        });
    },
    property: 'name',
    onselect: function (obj) {
        $("#country_id").val(obj.id)
        console.log(obj);
    }
});