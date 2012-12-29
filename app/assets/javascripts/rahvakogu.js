if (typeof Rahvakogu == "undefined" || !Rahvakogu) {
    var Rahvakogu = {};
}

/* Mobile ID check */
(function($) {
    var checkInterval;
    
    var MobileIdCheck = function() {
        return {
            init: function($form) {
                checkInterval = setInterval(function() {
                    $.ajax({
                        url: $form.attr('action'),
                        type: $form.attr('method'),
                        data: $form.serialize(),
                        dataType: 'json',
                        success: function(data, status, request) {
                            if (data.message) {
                                $form.find('.status').html(data.message);
                            }
                            if (data.notice) {
                                $form.find('.status').html(data.notice);
                            }
                            if (data.redirect) {
                                window.location.href = data.redirect;
                            }
                        }
                    });
                }, 8000);
            }
        };
    }();
    
    Rahvakogu.MobileIdCheck = MobileIdCheck;
})(jQuery);