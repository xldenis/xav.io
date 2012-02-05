# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
_gaq = _gaq || [];
_gaq.push(['_setAccount', 'UA-28905854-1']);
_gaq.push(['_trackPageview']);
$ ->
  hljs.initHighlightingOnLoad();
  ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
  ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
  s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);