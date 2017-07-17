#! /bin/bash
NA=${NA:=2067195763@vtext.com}
if curl -s -S http://www.hgtv.com/shows/be-on-hgtv |
	fgrep -i desperate | fgrep -i kitchen; 
then mailx -s "Audition for America's Most Desperate Kitchens" $NA <&-
else mailx -s "not yet" $NA <&-
fi
