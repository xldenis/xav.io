//Prints out text one letter at a time with delay.
function type(elem, text, delay, callback) {
  for(var eId = 0; eId < elem.children.length; eId++){
    elem.children[eId].style.opacity = 0;
  }

  function next(remText, elemId) {

    if(remText == ""){
      var child = elem.children[elemId];

      if(elemId > 0) {
        elem.children[elemId-1].innerHTML = elem.children[elemId-1].innerHTML.slice(0,-1);
      }

      if(!(elemId < elem.children.length)) {
        return callback();
      }

      remText = child.innerHTML.trim();
      child.innerHTML = "▊";
      child.style.opacity = 1;

      elemId += 1;

    }

    var child = elem.children[elemId-1];

    child.innerHTML = child.innerHTML.slice(0,-1) + remText[0]+"▊";
    remText = remText.slice(1);

    var randDelay = Math.floor(Math.random() * 100) - 40;

    setTimeout(function() {next(remText, elemId)}, delay + randDelay);
  }
  next("",0);

}

function load(elem,delay) {
  setTimeout(function() {
    function show(i){
      if(i < elem.childElementCount){
        elem.children[i].style.opacity = 1;
        setTimeout(function() {show(i+1)} , 25);
      }
    }
    show(0);
    elem.style.opacity = 1;
  },delay);
}

function request(com,resp,typeSpeed,lag) {
  for(i=0;i<resp.childElementCount;i++){
    resp.children[i].style.opacity = 0;
  }
  resp.style.opacity = 0;
  type(com,com.innerText,typeSpeed,function() {
    load(resp,lag);
  });
}

window.onload = function () {
  el = document.getElementsByClassName("zsh")[0];
  el2 = document.getElementsByClassName("hash")[0];
  typeDelay = 50;
  request(el, el2, typeDelay, 600);
}
