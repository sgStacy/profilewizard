// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require_tree .

$(document).ready(function(){

$(".checkall").click(function(){

    var status = $(this).prop("checked");

    var className = this.id.replace('checkall_', '');
    className = '.' + className;

    $(className).each(function(){this.checked = status;});
});

$('#index_form')
    .bind("ajax:beforeSend", function(evt, xhr, settings){

        //alert("before");
        var $submitButton = $(this).find('input[name="update"]');

        // Update the text of the submit button to let the user know stuff is happening.
        // But first, store the original text of the submit button, so it can be restored when the request is finished.
        //alert($(this).valueOf());
        //alert($(this).text());
        var $messageDiv = $(this).find('div#message_div');
        var $loadingImage = $(this).find('div#loader_image');
        //alert($messageDiv.text());
        //var $messageDiv = $(this).getElementById("message_div");

        $submitButton.data( 'origText', $(this).text() );
        $submitButton.text( "Submitting..." );
        $messageDiv.html( "<br/><br/>Working ..." );
        $loadingImage.show();
    })
    .bind("ajax:success", function(evt, data, status, xhr){
        //alert('success');

        var $form = $(this);

        // Reset fields and any validation errors, so form can be used again, but leave hidden_field values intact.
       // $form.find('textarea,input[type="text"],input[type="file"]').val("");
        $form.find('div.validation-error').empty();

        // Insert response partial into page below the form.
        //$('#comments').append(xhr.responseText);
        //$('xxxx').html("<%= raw escape_javascript( render :file => "xxxx/xxxx", :locals => { xxx: xxx ) %>");

       // $('#profile_list').html('<%= escape_javascript render \'profile/permission_settings\' %>');

    })
    .bind('ajax:loading', function(evt, xhr, status){
        //alert(status);
        //alert("<%= raw escape_javascript(@job_status) %>");
    })
    .bind('ajax:complete', function(evt, xhr, status){
        //alert('complete');
        var $submitButton = $(this).find('input[name="update"]');

        // Restore the original submit button text
        $submitButton.text( $(this).data('origText') );

        var $loadingImage = $(this).find('div#loader_image');
        $loadingImage.hide();

        //alert(@profiles);
       // alert("<%=escape_javascript(@profiles)%>");

       // $('#profile_list').html("<%= escape_javascript(render :partial => 'permission_settings', :collection => @profiles) %>");
    })
    .bind("ajax:error", function(evt, xhr, status, error){

        alert('error');
        alert(status);
        alert(error);
        var $form = $(this),
            errors,
            errorText;

        try {
            // Populate errorText with the comment errors
            errors = $.parseJSON(xhr.responseText);
        } catch(err) {
            // If the responseText is not valid JSON (like if a 500 exception was thrown), populate errors with a generic error message.
            errors = {message: "Please reload the page and try again"};
        }

        // Build an unordered list from the list of errors
        errorText = "There were errors with the submission: \n<ul>";

        for ( error in errors ) {
            errorText += "<li>" + error + ': ' + errors[error] + "</li> ";
        }

        errorText += "</ul>";

        //alert(errorText);

        // Insert error list into form
        $form.find('div.validation-error').html(errorText);
    });
});

