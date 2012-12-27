$(function(){
	$("#topBar").topBar();
	$("#rotator").rotator();
});

$.fn.rotator = function(){
	var main = $(this);
	if( main.size() == 0 ){ return false; }
	
	var persons = main.find(".persons .item");
	var personsMaxWidth = 460;
	var totalPersons = persons.size();
	var personsImgWidth = 40;
	var personsCurrentWidth = (totalPersons-1) * personsImgWidth;
	var personsSpareWidth = personsMaxWidth - personsCurrentWidth;
	
	var status = false;
	
	var quote = main.find(".quote span");
	
	persons.find(".wrapper").css("width", personsSpareWidth);
	
	persons.bind("click", function(e){
		e.preventDefault();
		
		var obj = $(this);
		
		if( status || obj.is(".active") ){ return false; }
		status = true;
		
		persons.animate({opacity: 0.33, width: personsImgWidth}, {duration:500, queue:false}).removeClass("active");
		
		obj.animate({opacity: 1, width: personsSpareWidth}, {duration:500, queue:false, complete:function(){
			status = false;	
		}}).addClass("active");
		
		quote.empty().hide().html( obj.find(".text").html() ).fadeIn(500);
		
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