$(function(){
	$('a.form_overlay').click(function() {
		$('#login_overlay').overlay({load: true, 
			closeOnClick: true,
			    mask: {
		        color: '#ebecff',
		        loadSpeed: 200,
		        opacity: 0.9
      },
      left: '400px'
		});
		$('#login_overlay').overlay().load();
		});
	


	$("#topBar").topBar();
	$("#rotator").rotator();
	$("#proposal-bottom .cycle").cycle();
	$(".cookieText").cookieText();
	
	$("#propositions .getMore").getMore();
	
	$("#dropdown").dropdown();
	
	$("form").find("[data-label]").each(function(){
		var obj = $(this);
		var label = obj.attr("data-label");
		var val = obj.val();
		
	
		if( val == "" ){
			obj.val( label );
		};
		
		obj.bind("focus", function(){
			
			if( obj.val() == label ){ obj.val(""); }
		});
		
		obj.bind("blur", function(){
			if( obj.val() == "" ){ obj.val( label ); }
		});

	});
	
});

$.fn.dropdown = function(){
	var main = $(this);
	if( main.size() == 0 ){ return false; }
	
	var input = $("input[name='"+main.attr("rel")+"']");
	
	var label = main.find(".active:first");
	var more = main.find(".more:first");
	var visible = 0;
	var items = more.find(".item");
	
	label.bind("click", function(e){
		e.preventDefault();
		if( visible == 0 ){
			visible = 1;
			more.show();
			main.addClass("opened");
		}else{
			visible = 0;
			more.hide();
			main.removeClass("opened");
		};
	});
	
	items.bind("click", function(){
		var obj = $(this);
		items.removeClass("selected");
		obj.addClass("selected");
		label.text( obj.text());
		input.val( obj.attr("data-value") );
		visible = 0;
		more.hide();
		main.removeClass("opened");
	});
	
	items.filter(".selected").trigger("click");
	
};

$.fn.getMore = function(){
	var main = $(this);
	
	main.bind("click", function(e){
		e.preventDefault();
		var href = main.attr("href");
		$.ajax({
			url: href,
			dataType: "html",
			cache: false,
			success: function( response ){
				main.before( response );
				main.remove();
				$("#propositions .getMore").getMore();
			}
		});
	});
};

$.fn.cookieText = function(){
	$(this).each(function(){
		var obj = $(this);
		var closeButton = obj.find(".closeButton");
		var id = obj.attr("id");
		
		if( $.cookie(id) ){
			obj.hide();	
		};
		
		closeButton.bind("click", function(e){
			e.preventDefault();
			obj.fadeOut(500);
			$.cookie(id, "set");		
		});
		
	});
};

$.fn.cycle = function(){
	var main = $(this);
	if( main.size() == 0 ){ return false; }
	
	var items = main.find(".item");
	var state = 0;
	var total = items.size()-1;
	var interval = '';
	var delay = 9000;
	
	function next(){
		items.hide();
		items.eq(state).fadeIn(250);
		state++;
		if( state > total ){
			state = 0;
		};
	};
	
	interval = setInterval(function(){
		next();
	}, delay);
	
	main.bind("mouseenter", function(){
		clearInterval(interval);
	});
	
	main.bind("mouseleave", function(){
		interval = setInterval(function(){
			next();
		}, delay);
	});
	
	next();

};

$.fn.rotator = function(){
	var main = $(this);
	if( main.size() == 0 ){ return false; }
	
	var personsCont = main.find(".persons:first, .quote:first");
	
	var persons = main.find(".persons .item");
	var personsMaxWidth = 460;
	var totalPersons = persons.size();
	var personsImgWidth = 40;
	var personsCurrentWidth = (totalPersons-1) * personsImgWidth;
	var personsSpareWidth = personsMaxWidth - personsCurrentWidth;
	
	var status = false;
	var timeout = '';
	var delay = 18000;
	
	function startTimeout(){
		timeout = setTimeout(function(){
			var nextPerson = persons.filter(".active").next(".item");
			if( nextPerson.size() == 0 ){
				nextPerson = persons.eq(0);
			};
			nextPerson.trigger("click");
		}, delay);
	};
	
	function endTimeout(){
		clearTimeout( timeout );
	};
	
	personsCont.bind("mouseenter", function(){
		endTimeout();
		
	}).bind("mouseleave", function(){
		startTimeout();
	});
	
	var quote = main.find(".quote span");
	
	persons.find(".wrapper").css("width", personsSpareWidth);
	
	persons.bind("click", function(e){
		e.preventDefault();
		
		endTimeout();
		
		var obj = $(this);
		
		if( status || obj.is(".active") ){ return false; }
		status = true;
		
		persons.animate({opacity: 0.33, width: personsImgWidth}, {duration:500, queue:false}).removeClass("active");
		
		obj.animate({opacity: 1, width: personsSpareWidth}, {duration:500, queue:false, complete:function(){
			status = false;	
		}}).addClass("active");
		
		quote.empty().hide().html( obj.find(".text").html() ).fadeIn(500);
		
		startTimeout();
		
	}).eq(0).trigger("click");
	
};

$.fn.topBar = function(){
	var main = $(this);
	if( main.size() == 0 ){ return false; }
	
	var maxWidth = 960;
	var totalWidth = 0;
	
	setTimeout(function(){
		main.find(".inline").children("*").each(function(){
			totalWidth+= $(this).outerWidth();
		});
		
		var leftOver = (maxWidth - totalWidth) /2;
	
		main.find("a:first").css("marginLeft", leftOver);
		
		main.find(".inline").css("visibility", "visible");
		
	}, 200);
};


document.createElement('header');
document.createElement('nav');
document.createElement('section');
document.createElement('article');
document.createElement('aside');
document.createElement('footer');
document.createElement('figure');


