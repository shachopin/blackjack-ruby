$(document).ready(function(){
 // $('#hit_form button').click(function(){
	//the second call is not ajax call, so we are looking at rendering the game template without a layout, hence without a css
    //document.ready. do this  is a one-time thing. when the form changes, it doens't bind again
  player_hits();
  player_stays();
  dealer_hits();
});


function player_hits(){
	$(document).on("click", "#hit_form button", function(){

	//alert("haha");

	$.ajax({
		type: "POST",
		url: "/game/player/hit"
	}).done(function(msg){
		//alert(msg);
		$("#game").replaceWith(msg);  //use replaceWith, not html
	});

	return false;
   
  });

}


function player_stays(){
	$(document).on("click", "#stay_form button", function(){

	//alert("haha");

	$.ajax({
		type: "POST",
		url: "/game/player/stay"
	}).done(function(msg){
		//alert(msg);
		$("#game").replaceWith(msg);  //use replaceWith, not html
	});

	return false;
   
  });

}


function player_stays(){
	$(document).on("click", "#stay_form button", function(){

	//alert("haha");

	$.ajax({
		type: "POST",
		url: "/game/player/stay"
	}).done(function(msg){
		//alert(msg);
		$("#game").replaceWith(msg);  //use replaceWith, not html
	});

	return false;
   
  });

}


function dealer_hits(){
	$(document).on("click", "#dealer_hit input", function(){

	//alert("haha");

	$.ajax({
		type: "POST",
		url: "/game/dealer/hit"
	}).done(function(msg){
		//alert(msg);
		$("#game").replaceWith(msg);  //use replaceWith, not html
	});

	return false;
   
  });

}



/* this is the same, not .click(doSomething()); like the video said

$(document).ready(function(){
  $('#hit_form button').click(doSomething);

});

function doSomething(){
	alert("haha");
	return false;
}
*/